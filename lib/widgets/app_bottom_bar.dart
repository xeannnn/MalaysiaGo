import 'package:flutter/material.dart';
import '../models.dart';

/// Bottom navigation bar. `selected` is the currently active tab,
/// `onSelect` is called with the tapped tab.
class AppBottomBar extends StatelessWidget {
  final BottomTab selected;
  final ValueChanged<BottomTab> onSelect;

  const AppBottomBar({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: BottomTab.values.indexOf(selected),
      onTap: (index) => onSelect(BottomTab.values[index]),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF0F8A5F),
      unselectedItemColor: Colors.grey,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: BottomTab.values
          .map((tab) => BottomNavigationBarItem(
        icon: Text(tab.emoji, style: const TextStyle(fontSize: 18)),
        label: tab.label,
      ))
          .toList(),
    );
  }
}