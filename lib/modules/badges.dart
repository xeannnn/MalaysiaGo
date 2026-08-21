// ============================================================
// ACHIEVEMENT & REWARDS MODULE - BADGES SCREEN
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_header.dart';
import '../models.dart';
import '../data/badge_data.dart';
import '../services/achievement_provider.dart';

class BadgesScreen extends StatefulWidget {
  final ValueChanged<int> onXpEarned;

  const BadgesScreen({
    super.key,
    required this.onXpEarned,
  });

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AchievementProvider>(context);
    final achievement = provider.achievement;
    final completedBadges = provider.completedBadges;
    final totalBadges = provider.totalBadges;
    final badgeProgress = provider.badgeProgress;

    // Map badge progress for easy lookup
    final Map<String, UserBadgeProgress> progressMap = {};
    for (var p in badgeProgress) {
      progressMap[p.badgeId] = p;
    }

    return Column(
      children: [
        AppHeader(
          title: 'Achievements',
          subtitle: 'Complete state badges to unlock rewards',
          xp: '${provider.totalXp}',
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              // XP Progress Card
              SliverToBoxAdapter(
                child: _XpProgressCard(
                  xp: provider.totalXp,
                  level: achievement.level,
                  xpToNext: achievement.xpToNextLevel,
                  completedBadges: completedBadges,
                  totalBadges: totalBadges,
                ),
              ),
              // Badge Collection Header
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'State Badges',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F8A5F),
                        ),
                      ),
                      Text(
                        '$completedBadges / $totalBadges completed',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Badge Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final badge = allStateBadges[index];
                      final progress = progressMap[badge.id];
                      final unlocked = progress?.unlockedPieces ?? 0;
                      final complete = progress?.isComplete ?? false;

                      return _BadgeCard(
                        badge: badge,
                        unlockedPieces: unlocked,
                        isComplete: complete,
                        onTap: () {
                          final visited = provider.visitedSites[badge.id] ?? [];
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BadgeDetailScreen(
                                badge: badge,
                                visitedSites: visited,
                                totalXp: provider.totalXp,
                                onXpEarned: widget.onXpEarned,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: allStateBadges.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// XP PROGRESS CARD
// ============================================================

class _XpProgressCard extends StatelessWidget {
  final int xp;
  final int level;
  final int xpToNext;
  final int completedBadges;
  final int totalBadges;

  const _XpProgressCard({
    required this.xp,
    required this.level,
    required this.xpToNext,
    required this.completedBadges,
    required this.totalBadges,
  });

  @override
  Widget build(BuildContext context) {
    final currentLevelConfig = LevelConfig.getLevelByXp(xp);
    final nextLevel = LevelConfig.getNextLevel(currentLevelConfig.level);
    final double progress = nextLevel != null && nextLevel != currentLevelConfig
        ? (xp - currentLevelConfig.xpRequired) /
        (nextLevel.xpRequired - currentLevelConfig.xpRequired)
        : 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D5BD0), Color(0xFF8B7FE8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Level',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⭐ $xp XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                nextLevel != null && nextLevel != currentLevelConfig
                    ? '${xp - currentLevelConfig.xpRequired} / ${nextLevel.xpRequired - currentLevelConfig.xpRequired} XP'
                    : 'Max Level Reached!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              if (xpToNext > 0)
                Text(
                  '$xpToNext XP to next level',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: Colors.white.withOpacity(0.25),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatChip(icon: '🏅', label: '$completedBadges/$totalBadges Badges'),
              const SizedBox(width: 10),
              _StatChip(
                icon: '🌟',
                label: '${(completedBadges / totalBadges * 100).toInt()}% Complete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BADGE CARD
// ============================================================

class _BadgeCard extends StatelessWidget {
  final StateBadge badge;
  final int unlockedPieces;
  final bool isComplete;
  final VoidCallback onTap;

  const _BadgeCard({
    required this.badge,
    required this.unlockedPieces,
    required this.isComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = badge.totalPieces > 0
        ? unlockedPieces / badge.totalPieces
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isComplete ? const Color(0xFFE9F9EF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isComplete
                ? const Color(0xFF16A34A)
                : Colors.grey.withOpacity(0.15),
            width: isComplete ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 4,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? const Color(0xFF16A34A) : const Color(0xFF6D5BD0),
                    ),
                  ),
                ),
                if (isComplete)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badge.badgeIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  )
                else if (progress > 0)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D5BD0).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D5BD0),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '🔒',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              badge.stateName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isComplete ? const Color(0xFF16A34A) : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              isComplete ? '✅ Completed!' : '${unlockedPieces}/${badge.totalPieces}',
              style: TextStyle(
                fontSize: 11,
                color: isComplete ? const Color(0xFF16A34A) : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isComplete
                    ? const Color(0xFF16A34A).withOpacity(0.1)
                    : const Color(0xFF6D5BD0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge.badgeTheme,
                style: TextStyle(
                  fontSize: 9,
                  color: isComplete ? const Color(0xFF16A34A) : const Color(0xFF6D5BD0),
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
// BADGE DETAIL SCREEN
// ============================================================

class BadgeDetailScreen extends StatefulWidget {
  final StateBadge badge;
  final List<String> visitedSites;
  final int totalXp;
  final ValueChanged<int> onXpEarned;

  const BadgeDetailScreen({
    super.key,
    required this.badge,
    required this.visitedSites,
    required this.totalXp,
    required this.onXpEarned,
  });

  @override
  State<BadgeDetailScreen> createState() => _BadgeDetailScreenState();
}

class _BadgeDetailScreenState extends State<BadgeDetailScreen> {
  bool _bonusClaimed = false;
  late AchievementProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<AchievementProvider>(context, listen: false);
    if (_provider.isBonusClaimed(widget.badge.id)) {
      _bonusClaimed = true;
    }
  }

  void _claimBonus() {
    if (widget.badge.isComplete(widget.visitedSites) && !_bonusClaimed) {
      int bonusXp = _provider.claimBadgeBonus(widget.badge.id);
      if (bonusXp > 0) {
        setState(() {
          _bonusClaimed = true;
        });
        widget.onXpEarned(bonusXp);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Bonus +$bonusXp XP for completing this badge!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.badge.getUnlockedPieces(widget.visitedSites);
    final complete = widget.badge.isComplete(widget.visitedSites);
    final progress = widget.badge.getProgress(widget.visitedSites);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('${widget.badge.stateName} Badge'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: complete
                    ? const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF0D9488)],
                )
                    : const LinearGradient(
                  colors: [Color(0xFF6D5BD0), Color(0xFF8B7FE8)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.badge.badgeIcon,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.badge.stateName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.badge.badgeTheme,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$unlocked / ${widget.badge.totalPieces} pieces collected',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    color: Colors.white.withOpacity(0.25),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: progress.clamp(0.0, 1.0),
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
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (complete) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✨ COMPLETE ✨',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bonus Claim Section
            if (complete && !_bonusClaimed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F9EF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF16A34A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎉 Badge Completed!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Claim +150 XP bonus',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _claimBonus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Claim Bonus'),
                    ),
                  ],
                ),
              ),

            if (complete && _bonusClaimed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F9EF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF16A34A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                    SizedBox(width: 10),
                    Text(
                      'Bonus claimed! +150 XP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Required Sites List
            const Text(
              'Required Heritage Sites',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ...widget.badge.requiredSiteIds.map((siteId) {
              final visited = widget.visitedSites.contains(siteId);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: visited
                            ? const Color(0xFF16A34A).withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: visited
                          ? const Icon(
                        Icons.check,
                        color: Color(0xFF16A34A),
                        size: 16,
                      )
                          : const Icon(
                        Icons.lock_outline,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Heritage Site ${siteId.replaceFirst('site_', '').toUpperCase()}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: visited ? Colors.black : Colors.grey[600],
                            ),
                          ),
                          Text(
                            visited ? '✅ Visited' : '🔒 Not yet visited',
                            style: TextStyle(
                              fontSize: 11,
                              color: visited ? const Color(0xFF16A34A) : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (visited)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF16A34A),
                        size: 18,
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About this badge',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.badge.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}