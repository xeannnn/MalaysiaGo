import 'package:flutter/material.dart';
import 'quiz.dart';

/// Temporary placeholder for the Map tab. This is NOT the real map —
/// a teammate is building the actual Map UI (site markers, GPS,
/// etc.) separately. Once that's ready, replace the body of this
/// screen with theirs, or delete this file and route BottomTab.map
/// straight to their MapScreen in main.dart.
///
/// For now this only exists so the quiz feature (this task) has
/// somewhere to be reached from — tapping a site card below simulates
/// "arriving near a heritage site" until real GPS proximity detection
/// is wired up.
class MapScreen extends StatelessWidget {
  final ValueChanged<int> onXpEarned;
  const MapScreen({super.key, required this.onXpEarned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Map',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F8A5F))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECC8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Map UI pending', style: TextStyle(fontSize: 11, color: Color(0xFFB8720A))),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🗺️', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text('Map view coming soon',
                          style: TextStyle(fontSize: 15, color: Colors.grey[600]), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      // Demo entry point into the quiz feature — stands
                      // in for tapping a site marker on the real map.
                      _NearbySiteCard(
                        icon: '⛩️',
                        name: 'Batu Caves',
                        subtitle: 'Selangor · Tap to simulate arriving here',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => QuizIntroScreen(siteId: 'batu_caves', onXpEarned: onXpEarned),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbySiteCard extends StatelessWidget {
  final String icon;
  final String name;
  final String subtitle;
  final VoidCallback onTap;

  const _NearbySiteCard({
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
