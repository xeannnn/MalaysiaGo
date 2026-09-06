import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'models.dart';

import 'modules/auth/login_screen.dart';
import 'modules/badges.dart';
import 'modules/community_screen.dart';
import 'modules/gps_checkin.dart';
import 'modules/homepage.dart';
import 'modules/mappage.dart';
import 'modules/passport.dart';
import 'modules/quiz.dart';

import 'services/achievement_provider.dart';

import 'widgets/app_bottom_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('userProgress');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('✅ Firebase initialized');
  } catch (error, stackTrace) {
    debugPrint('⚠️ Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // Supabase initialization
  await Supabase.initialize(
    url: 'https://jcyecsnsiznmeddygkle.supabase.co',
    publishableKey: 'sb_publishable_ArQqnsMHEqiQRHZAR5E9hA_9y5NpWp1',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final provider = AchievementProvider();
        provider.loadUserData();
        return provider;
      },
      child: const MalaysiaGoApp(),
    ),
  );
}

class MalaysiaGoApp extends StatelessWidget {
  const MalaysiaGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MalaysiaGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        useMaterial3: true,
      ),
      home: FirebaseAuth.instance.currentUser == null
          ? const LoginScreen()
          : const MainScreen(),
      routes: {'/home': (context) => const MainScreen()},
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const double _arrivalRadiusMeters = 250;
  static const double _maximumAcceptedAccuracyMeters = 150;

  BottomTab _selectedTab = BottomTab.home;
  String? _mapFocusSiteId;

  StreamSubscription<Position>? _locationSubscription;
  Position? _currentPosition;

  final Set<String> _promptedSiteIds = <String>{};

  bool _arrivalDialogOpen = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startHeritageLocationTracking();
    });
  }

  Future<void> _startHeritageLocationTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showLocationMessage(
          'Location services are turned off. Turn on GPS to detect nearby heritage sites.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showLocationMessage(
          'Location permission was denied. Nearby heritage-site detection is unavailable.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationMessage(
          'Location permission is permanently denied. Enable it from your phone settings.',
        );
        return;
      }

      try {
        final currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );

        _handlePositionUpdate(currentPosition);
      } catch (error) {
        debugPrint('Could not obtain the initial GPS position: $error');
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      );

      await _locationSubscription?.cancel();

      _locationSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            _handlePositionUpdate,
            onError: (Object error) {
              debugPrint('Location stream error: $error');
            },
          );
    } catch (error, stackTrace) {
      debugPrint('Unable to start heritage-site location tracking: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showLocationMessage('Unable to start location tracking.');
    }
  }

  void _handlePositionUpdate(Position position) {
    if (!mounted) {
      return;
    }

    /*
     * Ignore extremely inaccurate readings. This helps prevent a
     * heritage-site prompt from appearing when the GPS position has
     * a very large uncertainty radius.
     */
    if (position.accuracy > _maximumAcceptedAccuracyMeters) {
      debugPrint(
        'Ignoring inaccurate GPS reading: '
        '${position.accuracy.toStringAsFixed(1)} metres',
      );
      return;
    }

    setState(() {
      _currentPosition = position;
    });

    if (_arrivalDialogOpen) {
      return;
    }

    HeritageMapSite? nearestSite;
    double nearestDistance = double.infinity;

    for (final site in heritageMapSites) {
      if (_promptedSiteIds.contains(site.id)) {
        continue;
      }

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        site.latitude,
        site.longitude,
      );

      if (distance <= _arrivalRadiusMeters && distance < nearestDistance) {
        nearestSite = site;
        nearestDistance = distance;
      }
    }

    if (nearestSite == null) {
      return;
    }

    _promptedSiteIds.add(nearestSite.id);

    Provider.of<AchievementProvider>(
      context,
      listen: false,
    ).addHeritageVisit(nearestSite.id, nearestSite.location);

    _showHeritageSiteArrivalPrompt(
      site: nearestSite,
      distanceMeters: nearestDistance,
    );
  }

  Future<void> _showHeritageSiteArrivalPrompt({
    required HeritageMapSite site,
    required double distanceMeters,
  }) async {
    if (!mounted || _arrivalDialogOpen) {
      return;
    }

    _arrivalDialogOpen = true;

    final shouldOpenSite = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final distanceText = distanceMeters < 100
            ? '${distanceMeters.round()} metres away'
            : 'about ${(distanceMeters / 10).round() * 10} metres away';

        return AlertDialog(
          title: Row(
            children: [
              Text(site.icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(child: Text('You are near ${site.name}!')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${site.location} • $distanceText',
                  style: const TextStyle(
                    color: Color(0xFF0F8A5F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(site.briefInfo),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: site.hasQuiz
                        ? const Color(0xFFE9F9EF)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        site.hasQuiz ? Icons.quiz : Icons.info_outline,
                        color: site.hasQuiz
                            ? const Color(0xFF0F8A5F)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          site.hasQuiz
                              ? 'A heritage quiz is available for this site. Complete it to earn XP.'
                              : 'Site information is available. The quiz for this site is coming soon.',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Later'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: Icon(site.hasQuiz ? Icons.quiz : Icons.menu_book),
              label: Text(site.hasQuiz ? 'Info & Quiz' : 'View Info'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F8A5F),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    _arrivalDialogOpen = false;

    if (shouldOpenSite == true && mounted) {
      _openDetectedSiteOnMap(site.id);
    }
  }

  void _openDetectedSiteOnMap(String siteId) {
    setState(() {
      /*
       * Setting the site ID gives MapScreen a new key. The map then
       * focuses on the detected site and automatically opens its
       * existing site-options sheet.
       */
      _mapFocusSiteId = siteId;
      _selectedTab = BottomTab.map;
    });
  }

  void _showLocationMessage(String message) {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
      );
    });
  }

  void _handleQuizComplete(QuizAttempt attempt) {
    final provider = Provider.of<AchievementProvider>(context, listen: false);

    provider.addQuizAttempt(attempt);
  }

  void _openCommunitySiteOnMap(String siteId) {
    setState(() {
      _mapFocusSiteId = siteId;
      _selectedTab = BottomTab.map;
    });
  }

  void _selectTab(BottomTab tab) {
    setState(() {
      _selectedTab = tab;

      if (tab != BottomTab.map) {
        _mapFocusSiteId = null;
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AchievementProvider>(context);

    Widget buildBody() {
      switch (_selectedTab) {
        case BottomTab.home:
          return HomeScreen(
            totalXp: provider.totalXp,
            onTabSelected: _selectTab,
          );

        case BottomTab.map:
          return MapScreen(
            key: ValueKey<String?>('map-${_mapFocusSiteId ?? 'normal'}'),
            totalXp: provider.totalXp,
            completedQuizIds: provider.completedQuizIds,
            quizHistory: provider.quizHistory,
            onQuizComplete: _handleQuizComplete,
            initialSiteId: _mapFocusSiteId,
            visitedSiteIds: provider.visitedHeritageSiteIds,
            userLatitude: _currentPosition?.latitude,
            userLongitude: _currentPosition?.longitude,
          );

        case BottomTab.scan:
          return GpsCheckInScreen(onSiteSelected: _openDetectedSiteOnMap);

        case BottomTab.community:
          return CommunityScreen(onViewOnMap: _openCommunitySiteOnMap);

        case BottomTab.badges:
          return const BadgesScreen();

        case BottomTab.passport:
          return const PassportScreen();
      }
    }

    return Scaffold(
      body: SafeArea(child: buildBody()),
      bottomNavigationBar: AppBottomBar(
        selected: _selectedTab,
        onSelect: _selectTab,
      ),
    );
  }
}
