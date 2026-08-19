import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models.dart';
import 'modules/homepage.dart';
import 'modules/mappage.dart';
import 'modules/passport.dart';
import 'modules/placeholder.dart';
import 'modules/badges.dart';
import 'services/achievement_provider.dart';
import 'widgets/app_bottom_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase init failed: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) {
        try {
          final provider = AchievementProvider();
          provider.loadUserData();
          return provider;
        } catch (e) {
          debugPrint('⚠️ Provider init error: $e');
          return AchievementProvider();
        }
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
      home: const MainScreen(),  // Skip login for debugging
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
            onXpEarned: (xp) => provider.addXp(xp),
          );
        case BottomTab.passport:
          return const PassportScreen();
        case BottomTab.badges:
          return BadgesScreen(
            onXpEarned: (xp) => provider.addXp(xp),
          );
        default:
          return PlaceholderScreen(tab: _selectedTab);
      }
    }

    return Scaffold(
      body: SafeArea(child: buildBody()),
      bottomNavigationBar: AppBottomBar(
        selected: _selectedTab,
        onSelect: (tab) => setState(() => _selectedTab = tab),
      ),
    );
  }
}