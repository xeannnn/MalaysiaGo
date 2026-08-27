import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../modules/auth/profile_screen.dart';

/// Shared header used at the top of every screen:
/// title, subtitle, XP pill, and profile button.
class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String xp;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? photoUrl = user?.photoURL;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F8A5F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECC8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⭐ $xp XP',
                  style: const TextStyle(
                    color: Color(0xFFB8720A),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: ClipOval(
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (
                          context,
                          error,
                          stackTrace,
                          ) {
                        return const Icon(
                          Icons.person,
                          color: Color(0xFF0F8A5F),
                        );
                      },
                    )
                        : const Icon(
                      Icons.person,
                      color: Color(0xFF0F8A5F),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}