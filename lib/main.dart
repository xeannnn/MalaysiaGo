import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'models.dart';
import 'modules/quiz.dart';

import 'modules/homepage.dart';
import 'modules/mappage.dart';
import 'modules/passport.dart';
import 'modules/badges.dart';
import 'modules/gps_checkin.dart';
import 'modules/community_screen.dart';
import 'modules/auth/login_screen.dart';

import 'services/achievement_provider.dart';
import 'widgets/app_bottom_bar.dart';

Future<void> main() async {
  try {
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

    try {
      await Supabase.initialize(
        url: 'https://jcyecsnsiznmeddygkle.supabase.co',
        publishableKey: 'sb_publishable_ArQqnsMHEqiQRHZAR5E9hA_9y5NpWp1',
      );
      debugPrint('✅ Supabase initialized');
    } catch (e) {
      debugPrint('❌ Supabase error: $e');
    }

    runApp(
      ChangeNotifierProvider(
        create: (context) {
          try {
            final provider = AchievementProvider();
            provider.loadUserData();
            return provider;
          } catch (e) {
            debugPrint('❌ Provider error: $e');
            return AchievementProvider();
          }
        },
        child: const MalaysiaGoApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('❌ Startup error: $e');
    debugPrintStack(stackTrace: stack);
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('Startup Error: $e', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Check console for details.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      routes: {
        '/home': (context) => const MainScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  BottomTab _selectedTab = BottomTab.home;
  String? _mapFocusSiteId;

  void _handleQuizComplete(QuizAttempt attempt) {
    final provider = Provider.of<AchievementProvider>(
      context,
      listen: false,
    );
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
          );
        case BottomTab.scan:
          return const GpsCheckInScreen();
        case BottomTab.community:
          return CommunityScreen(
            onViewOnMap: _openCommunitySiteOnMap,
          );
        case BottomTab.badges:
          return BadgesScreen(
            onXpEarned: (xp) => provider.addXp(xp),
          );
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