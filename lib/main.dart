import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'models.dart';

import 'modules/homepage.dart';
import 'modules/mappage.dart';
import 'modules/passport.dart';
import 'modules/badges.dart';
import 'modules/quiz.dart';
import 'modules/gps_checkin.dart';
import 'modules/community_screen.dart';
import 'modules/auth/login_screen.dart';

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
          return GpsCheckInScreen(
            onXpEarned: (xp) => provider.addXp(xp),
          );

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
      body: SafeArea(
        child: buildBody(),
      ),
      bottomNavigationBar: AppBottomBar(
        selected: _selectedTab,
        onSelect: _selectTab,
      ),
    );
  }
}