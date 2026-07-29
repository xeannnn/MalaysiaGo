
import 'package:flutter/material.dart';

/// Shared header used at the top of every screen: title, subtitle,
/// XP pill, and notification bell. Change styling here and it
/// updates on every screen that uses it.
class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String xp;

  const AppHeader({super.key, required this.title, required this.subtitle, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F8A5F))),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECC8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('⭐ $xp XP',
                    style: const TextStyle(
                        color: Color(0xFFB8720A), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Text('🔔'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
