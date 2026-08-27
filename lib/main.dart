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
import 'modules/placeholder.dart';
import 'modules/badges.dart';
import 'modules/quiz.dart';
import 'modules/auth/login_screen.dart';
import 'modules/gps_checkin.dart';
import 'modules/community_screen.dart';

import 'services/achievement_provider.dart';

import 'widgets/app_bottom_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive initialization
  await Hive.initFlutter();
  await Hive.openBox('userProgress');

  // Firebase initialization
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

  void _handleQuizComplete(QuizAttempt attempt) {
    final provider = Provider.of<AchievementProvider>(
      context,
      listen: false,
    );

    provider.addQuizAttempt(attempt);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AchievementProvider>(context);

    Widget buildBody() {
      switch (_selectedTab) {
        case BottomTab.home:
          return HomeScreen(
            totalXp: provider.totalXp,
            onTabSelected: (tab) {
              setState(() => _selectedTab = tab);
            },
          );

        case BottomTab.map:
          return MapScreen(
            totalXp: provider.totalXp,
            completedQuizIds: provider.completedQuizIds,
            quizHistory: provider.quizHistory,
            onQuizComplete: _handleQuizComplete,
          );

        case BottomTab.scan:
          return GPSCheckInScreen(
            onTabSelected: (tab) {
              setState(() => _selectedTab = tab);
            },
          );

        case BottomTab.community:
          return const CommunityScreen();

        case BottomTab.badges:
          return BadgesScreen(
            onXpEarned: (xp) => provider.addXp(xp),
          );

        case BottomTab.passport:
          return const PassportScreen();

        default:
          return PlaceholderScreen(tab: _selectedTab);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: buildBody(),
      ),
      bottomNavigationBar: AppBottomBar(
        selected: _selectedTab,
        onSelect: (tab) {
          setState(() => _selectedTab = tab);
        },
      ),
    );
  }
}