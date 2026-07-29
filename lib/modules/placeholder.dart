import 'package:flutter/material.dart';
import '../models.dart';

/// Stand-in for Map / Scan / Badges until those screens are built.
/// Build a real ___Screen widget the same way HomeScreen is
/// structured, then swap the `default:` branch in main.dart's
/// switch for a direct call to it.
class PlaceholderScreen extends StatelessWidget {
  final BottomTab tab;
  const PlaceholderScreen({super.key, required this.tab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(tab.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text('${tab.label} — coming soon',
                style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}