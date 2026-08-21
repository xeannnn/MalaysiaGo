import 'package:flutter/material.dart';

import '../widgets/app_header.dart';

/// Each collectible piece: an icon cycled with a pastel background
/// color. Add/replace entries here to change what shows up in the
/// grid — these stand in for real site artwork until that's ready.
const List<String> _pieceIcons = [
  '🏛️',
  '🎭',
  '⛩️',
  '🌺',
  '🗼',
  '🏯',
  '🖼️',
  '⛺',
  '🦚',
  '🏺',
  '💎',
  '⛰️',
  '🌋',
  '⚓',
  '🛡️',
  '🏆',
  '🕌',
  '🏰',
  '🎨',
  '🏵️',
];

const List<Color> _pieceColors = [
  Color(0xFFDCFCE7),
  Color(0xFFE0E7FF),
  Color(0xFFFCE7F3),
  Color(0xFFFFF7CD),
  Color(0xFFDBEEFB),
  Color(0xFFFFE4E1),
];

/// Passport screen: hero progress card + grid of collectible pieces.
/// `collected` / `totalPieces` are hardcoded for now — wire these up
/// to real data later.
class PassportScreen extends StatelessWidget {
  const PassportScreen({super.key});

  static const int totalPieces = 40;
  static const int collected = 24;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(
          title: 'Digital Passport',
          subtitle: '$collected / $totalPieces Pieces',
          xp: '1,250',
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const PassportHeroCard(
                        collected: collected,
                        total: totalPieces,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: Text(
                            'Tap any piece to view site details',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                      final bool unlocked =
                          index < collected;

                      final Color color = unlocked
                          ? _pieceColors[
                      index % _pieceColors.length]
                          : const Color(0xFFF0F0F0);

                      return Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: unlocked
                            ? Text(
                          _pieceIcons[
                          index %
                              _pieceIcons.length],
                          style:
                          const TextStyle(
                            fontSize: 20,
                          ),
                        )
                            : const Text(
                          '?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                            color: Color(
                              0xFFB0B0B0,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: totalPieces,
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PassportHeroCard extends StatelessWidget {
  final int collected;
  final int total;

  const PassportHeroCard({
    super.key,
    required this.collected,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final int percent =
    (collected * 100 / total).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6D5BD0),
            Color(0xFF8B7FE8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DIGITAL PASSPORT',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Malaysia Heritage Mosaic',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Collect all $total pieces to reveal the masterpiece',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                '$collected / $total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  color:
                  Colors.white.withOpacity(0.25),
                ),
                FractionallySizedBox(
                  widthFactor: percent / 100,
                  child: Container(
                    height: 6,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}