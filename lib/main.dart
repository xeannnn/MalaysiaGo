import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'modules/homepage.dart';
import 'modules/mappage.dart';
import 'modules/passport.dart';
import 'modules/placeholder.dart';
import 'modules/badges.dart';
import 'services/achievement_provider.dart';
import 'widgets/app_bottom_bar.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AchievementProvider()..loadUserData(),
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
      home: const MainScreen(),
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
          return HomeScreen(totalXp: provider.totalXp);
        case BottomTab.map:
          return MapScreen(
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