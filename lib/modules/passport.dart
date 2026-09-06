import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/badge_data.dart';
import '../services/achievement_provider.dart';

class PassportScreen extends StatelessWidget {
  /// When true, Passport was opened from a Heritage Detail page.
  /// A back button is shown so the user can return to the same heritage site.
  ///
  /// When Passport is opened normally from the bottom navigation,
  /// leave this false so no back button is shown.
  final bool showBackButton;

  const PassportScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final AchievementProvider provider =
    context.watch<AchievementProvider>();

    // 64 unique heritage-site IDs from all active state/FT badges.
    final List<String> siteIds = activeStateBadges
        .expand((badge) => badge.requiredSiteIds)
        .toSet()
        .toList();

    final Set<String> visitedIds = provider.visitedHeritageSiteIds;

    final int totalPieces = siteIds.length;
    final int collected =
        siteIds.where((id) => visitedIds.contains(id)).length;

    final double progress =
    totalPieces == 0 ? 0 : collected / totalPieces;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _PassportHeader(
              showBackButton: showBackButton,
              collected: collected,
              totalPieces: totalPieces,
              xp: provider.totalXp,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PassportHeroCard(
                      collected: collected,
                      total: totalPieces,
                      progress: progress,
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Text(
                        'Tap any piece to view site details',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PassportMosaicGrid(
                      siteIds: siteIds,
                      visitedIds: visitedIds,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _PassportHeader extends StatelessWidget {
  final bool showBackButton;
  final int collected;
  final int totalPieces;
  final int xp;

  const _PassportHeader({
    required this.showBackButton,
    required this.collected,
    required this.totalPieces,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7FA),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: [
          if (showBackButton) ...[
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 19,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Digital Passport',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$collected / $totalPieces Pieces',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1C7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 17,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 5),
                Text(
                  '$xp XP',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB7791F),
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

// ============================================================
// HERO CARD
// ============================================================

class PassportHeroCard extends StatelessWidget {
  final int collected;
  final int total;
  final double progress;

  const PassportHeroCard({
    super.key,
    required this.collected,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final int percent =
    total == 0 ? 0 : ((collected * 100) / total).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7768D7),
            Color(0xFF8B7DE3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7768D7).withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Malaysia Heritage Mosaic',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white70,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Collect all $total pieces to reveal the masterpiece',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$collected',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 35,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  ' / $total',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor:
              const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MOSAIC GRID
// ============================================================

class PassportMosaicGrid extends StatelessWidget {
  final List<String> siteIds;
  final Set<String> visitedIds;

  const PassportMosaicGrid({
    super.key,
    required this.siteIds,
    required this.visitedIds,
  });

  static const List<IconData> _icons = [
    Icons.account_balance_rounded,
    Icons.temple_buddhist_rounded,
    Icons.mosque_rounded,
    Icons.castle_rounded,
    Icons.park_rounded,
    Icons.museum_rounded,
    Icons.landscape_rounded,
    Icons.fort_rounded,
    Icons.location_city_rounded,
    Icons.auto_awesome_rounded,
  ];

  static const List<Color> _backgrounds = [
    Color(0xFFFFE8D8),
    Color(0xFFE1F3FF),
    Color(0xFFE5F7E8),
    Color(0xFFFFF0C9),
    Color(0xFFF0E5FF),
    Color(0xFFFFE3EC),
    Color(0xFFDFF7F1),
    Color(0xFFE8ECFF),
  ];

  static const List<Color> _foregrounds = [
    Color(0xFFE77732),
    Color(0xFF2D8DD6),
    Color(0xFF33A65C),
    Color(0xFFD99A1D),
    Color(0xFF8C5AC6),
    Color(0xFFD45D82),
    Color(0xFF2D9C84),
    Color(0xFF5869C7),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: siteIds.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final String siteId = siteIds[index];
        final bool unlocked = visitedIds.contains(siteId);

        return _PassportPiece(
          siteId: siteId,
          unlocked: unlocked,
          icon: _icons[index % _icons.length],
          backgroundColor:
          _backgrounds[index % _backgrounds.length],
          foregroundColor:
          _foregrounds[index % _foregrounds.length],
        );
      },
    );
  }
}

class _PassportPiece extends StatelessWidget {
  final String siteId;
  final bool unlocked;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const _PassportPiece({
    required this.siteId,
    required this.unlocked,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  String get _friendlyName {
    return siteId
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
      '${part[0].toUpperCase()}${part.substring(1)}',
    )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: Text(
                  unlocked ? _friendlyName : 'Locked Piece',
                ),
                content: Text(
                  unlocked
                      ? 'You unlocked this heritage passport piece through a verified GPS check-in.'
                      : 'Visit this heritage site and complete a verified GPS check-in to unlock this piece.',
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color:
            unlocked ? backgroundColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: unlocked
                  ? foregroundColor.withValues(alpha: 0.15)
                  : Colors.grey.shade200,
            ),
          ),
          child: Center(
            child: unlocked
                ? Icon(
              icon,
              size: 27,
              color: foregroundColor,
            )
                : Text(
              '?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
