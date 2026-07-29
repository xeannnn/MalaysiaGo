
import 'package:flutter/material.dart';
import 'models.dart';
import 'modules/homepage.dart';
import 'modules/passport.dart';
import 'modules/placeholder.dart';
import 'widgets/app_bottom_bar.dart';

void main() {
  runApp(const MalaysiaGoApp());
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

/// Holds which bottom-nav tab is selected and routes to the matching
/// screen. To add a new screen: add a case to the switch below and
/// build it the same way HomeScreen / PassportScreen are structured.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  BottomTab _selectedTab = BottomTab.home;

  Widget _buildBody() {
    switch (_selectedTab) {
      case BottomTab.home:
        return const HomeScreen();
      case BottomTab.passport:
        return const PassportScreen();
      default:
        return PlaceholderScreen(tab: _selectedTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: AppBottomBar(
        selected: _selectedTab,
        onSelect: (tab) => setState(() => _selectedTab = tab),
      ),
    );
  }
}
