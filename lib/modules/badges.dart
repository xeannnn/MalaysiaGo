// ============================================================
// ACHIEVEMENT & REWARDS MODULE - BADGES SCREEN
// ============================================================
//
// This module displays:
// 1. User's XP and level progress (ACCURATE)
// 2. State-themed badges with progressive reveal (0% → 100%)
// 3. Badge detail view with site requirements
// 4. Bonus XP claiming for completed badges (ONCE per badge)
// 5. Badge unlock celebration dialog (VISUAL ONLY - NO XP AUTO-ADD)
// 6. Level-up celebration dialog
// 7. XP breakdown section
// 8. Badge filtering (All / Unlocked / In Progress / Locked)
// 9. Recent achievements history
// 10. Level info button (ℹ️) to see all levels
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_header.dart';
import '../models.dart';
import '../data/badge_data.dart';
import '../services/achievement_provider.dart';

// ✅ Custom callback type for claiming badge bonus (takes 2 parameters)
typedef ClaimBonusCallback = void Function(String badgeId, int xpReward);

// ============================================================
// DEMONSTRATION DATA
// ============================================================

class DemoData {
  static Map<String, int> visitedCounts = {
    'badge_kl': 4,      // 100% Complete ✅
    'badge_selangor': 1, // 50%
    'badge_penang': 2,   // 40%
    'badge_perak': 2,    // 67%
    'badge_kedah': 0,    // 0%
    'badge_perlis': 0,   // 0%
    'badge_melaka': 2,   // 50%
    'badge_johor': 1,    // 100% Complete ✅
    'badge_ns': 0,       // 0%
    'badge_pahang': 0,   // 0%
    'badge_tganu': 0,    // 0%
    'badge_kelantan': 0, // 0%
    'badge_sarawak': 1,  // 33%
    'badge_sabah': 2,    // 67%
  };

  static List<XpSource> xpSources = [
    XpSource(source: 'Heritage Visit', xp: 100, icon: '📍'),
    XpSource(source: 'Quiz Completed', xp: 50, icon: '🧠'),
    XpSource(source: 'Perfect Quiz Bonus', xp: 50, icon: '⭐'),
    XpSource(source: 'Badge Completed', xp: 200, icon: '🏅'),
    XpSource(source: 'Daily Bonus', xp: 20, icon: '🔥'),
  ];

  static List<RecentAchievement> recentAchievements = [
    RecentAchievement(
      title: 'First Explorer',
      description: 'Visited your first heritage site',
      date: DateTime(2026, 8, 20),
      icon: '🏅',
      type: RecentType.badge,
    ),
    RecentAchievement(
      title: 'Level 5 Reached',
      description: 'Reached Heritage Enthusiast level',
      date: DateTime(2026, 8, 25),
      icon: '⬆️',
      type: RecentType.level,
    ),
    RecentAchievement(
      title: 'Kuala Lumpur Explorer',
      description: 'Completed all KL heritage sites',
      date: DateTime(2026, 8, 26),
      icon: '🏅',
      type: RecentType.badge,
    ),
  ];
}

class XpSource {
  final String source;
  final int xp;
  final String icon;
  XpSource({required this.source, required this.xp, required this.icon});
}

enum RecentType { badge, level }

class RecentAchievement {
  final String title;
  final String description;
  final DateTime date;
  final String icon;
  final RecentType type;
  RecentAchievement({
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
    required this.type,
  });
  String get formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}

class BadgeUnlockData {
  final String badgeId;
  final String stateName;
  final String badgeIcon;
  final String badgeTheme;
  final int xpReward;
  BadgeUnlockData({
    required this.badgeId,
    required this.stateName,
    required this.badgeIcon,
    required this.badgeTheme,
    required this.xpReward,
  });
}

// ============================================================
// MAIN BADGES SCREEN
// ============================================================

class BadgesScreen extends StatefulWidget {
  final ValueChanged<int> onXpEarned;
  const BadgesScreen({super.key, required this.onXpEarned});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  String _selectedFilter = 'All';
  final Set<String> _celebratedBadges = {};
  final Set<String> _claimedBadgeBonuses = {};
  final List<BadgeUnlockData> _unlockQueue = [];
  Map<String, List<String>> _simulatedVisitedSites = {};
  List<XpSource> _xpSources = [];
  List<RecentAchievement> _recentAchievements = [];

  @override
  void initState() {
    super.initState();
    _initializeDemoData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialUnlocks();
    });
  }

  void _initializeDemoData() {
    _simulatedVisitedSites = {};
    for (var badge in allStateBadges) {
      int count = DemoData.visitedCounts[badge.id] ?? 0;
      List<String> visited = [];
      for (int i = 0; i < count && i < badge.requiredSiteIds.length; i++) {
        visited.add(badge.requiredSiteIds[i]);
      }
      _simulatedVisitedSites[badge.id] = visited;
    }
    _xpSources = List.from(DemoData.xpSources);
    _recentAchievements = List.from(DemoData.recentAchievements);
  }

  void _checkInitialUnlocks() {
    for (var badge in allStateBadges) {
      List<String> visited = _simulatedVisitedSites[badge.id] ?? [];
      if (badge.isComplete(visited) && !_celebratedBadges.contains(badge.id)) {
        _celebratedBadges.add(badge.id);
        _unlockQueue.add(BadgeUnlockData(
          badgeId: badge.id,
          stateName: badge.stateName,
          badgeIcon: badge.badgeIcon,
          badgeTheme: badge.badgeTheme,
          xpReward: badge.bonusXp,
        ));
      }
    }
    if (_unlockQueue.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNextUnlock();
      });
    }
  }

  void _showNextUnlock() {
    if (_unlockQueue.isEmpty) return;
    final unlock = _unlockQueue.removeAt(0);
    _showUnlockCelebration(unlock);
  }

  Map<String, UserBadgeProgress> _getBadgeProgressMap() {
    final progressMap = <String, UserBadgeProgress>{};
    for (var badge in allStateBadges) {
      List<String> visited = _simulatedVisitedSites[badge.id] ?? [];
      int unlocked = badge.getUnlockedPieces(visited);
      bool complete = badge.isComplete(visited);
      progressMap[badge.id] = UserBadgeProgress(
        badgeId: badge.id,
        stateName: badge.stateName,
        badgeIcon: badge.badgeIcon,
        badgeTheme: badge.badgeTheme,
        totalPieces: badge.totalPieces,
        unlockedPieces: unlocked,
        isComplete: complete,
        bonusXpEarned: complete ? badge.bonusXp : 0,
        bonusClaimed: _claimedBadgeBonuses.contains(badge.id),
      );
    }
    return progressMap;
  }

  List<StateBadge> _getFilteredBadges() {
    final progressMap = _getBadgeProgressMap();
    return allStateBadges.where((badge) {
      final progress = progressMap[badge.id];
      final isComplete = progress?.isComplete ?? false;
      final unlockedPieces = progress?.unlockedPieces ?? 0;
      switch (_selectedFilter) {
        case 'All': return true;
        case 'Unlocked': return isComplete;
        case 'In Progress': return !isComplete && unlockedPieces > 0;
        case 'Locked': return unlockedPieces == 0;
        default: return true;
      }
    }).toList();
  }

  void _handleBadgeComplete(String badgeId) {
    final badge = allStateBadges.firstWhere((b) => b.id == badgeId);
    if (!_celebratedBadges.contains(badgeId)) {
      _celebratedBadges.add(badgeId);
      _recentAchievements.insert(0, RecentAchievement(
        title: '${badge.stateName} Explorer',
        description: 'Completed all heritage sites in ${badge.stateName}',
        date: DateTime.now(),
        icon: badge.badgeIcon,
        type: RecentType.badge,
      ));
      setState(() {});
      _showUnlockCelebration(BadgeUnlockData(
        badgeId: badge.id,
        stateName: badge.stateName,
        badgeIcon: badge.badgeIcon,
        badgeTheme: badge.badgeTheme,
        xpReward: badge.bonusXp,
      ));
    }
  }

  void _claimBadgeBonus(String badgeId, int xpReward) {
    if (_claimedBadgeBonuses.contains(badgeId)) return;
    _claimedBadgeBonuses.add(badgeId);
    widget.onXpEarned(xpReward);
    final badge = allStateBadges.firstWhere((b) => b.id == badgeId);
    _xpSources.add(XpSource(
      source: '${badge.stateName} Badge Completed',
      xp: xpReward,
      icon: '🏅',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Bonus +$xpReward XP for completing this badge!'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  void _showUnlockCelebration(BadgeUnlockData unlock) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UnlockCelebrationDialog(
        unlock: unlock,
        onDismiss: () {
          if (_unlockQueue.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showNextUnlock();
            });
          }
        },
        onViewBadge: () {
          final badge = allStateBadges.firstWhere((b) => b.id == unlock.badgeId);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BadgeDetailScreen(
                badge: badge,
                visitedSites: _simulatedVisitedSites[badge.id] ?? [],
                totalXp: Provider.of<AchievementProvider>(context, listen: false).totalXp,
                onXpEarned: widget.onXpEarned,
                onBadgeComplete: (badgeId) {
                  _handleBadgeComplete(badgeId);
                },
                claimedBonuses: _claimedBadgeBonuses,
                onClaimBonus: _claimBadgeBonus,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AchievementProvider>(context);
    final totalXp = provider.totalXp;
    final level = provider.level.level;
    final completedBadges = provider.completedBadges;
    final totalBadges = provider.totalBadges;
    final filteredBadges = _getFilteredBadges();

    // ✅ ACCURATE XP CALCULATION
    final currentLevelConfig = LevelConfig.getLevelByXp(totalXp);
    final nextLevelConfig = LevelConfig.getNextLevel(currentLevelConfig.level);
    final xpInCurrentLevel = totalXp - currentLevelConfig.xpRequired;
    final xpRange = nextLevelConfig != null
        ? nextLevelConfig.xpRequired - currentLevelConfig.xpRequired
        : 0;
    final xpToNext = nextLevelConfig != null
        ? nextLevelConfig.xpRequired - totalXp
        : 0;

    return Column(
      children: [
        AppHeader(
          title: 'Achievements',
          subtitle: 'Complete state badges to unlock rewards',
          xp: '$totalXp',
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _XpProgressCard(
                  xp: totalXp,
                  level: level,
                  xpInCurrentLevel: xpInCurrentLevel,
                  xpToNext: xpToNext,
                  xpRange: xpRange,
                  completedBadges: completedBadges,
                  totalBadges: totalBadges,
                ),
              ),
              SliverToBoxAdapter(
                child: _XpBreakdownSection(xpSources: _xpSources),
              ),
              SliverToBoxAdapter(
                child: _RecentAchievementsSection(
                  achievements: _recentAchievements,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                      const SizedBox(height: 10),
                      _buildFilterChips(),
                    ],
                  ),
                ),
              ),
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
                      final badge = filteredBadges[index];
                      final visited = _simulatedVisitedSites[badge.id] ?? [];
                      final unlocked = badge.getUnlockedPieces(visited);
                      final complete = badge.isComplete(visited);
                      final progress = badge.getProgress(visited);
                      return _ProgressiveBadgeCard(
                        badge: badge,
                        unlockedPieces: unlocked,
                        isComplete: complete,
                        progress: progress,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BadgeDetailScreen(
                                badge: badge,
                                visitedSites: visited,
                                totalXp: totalXp,
                                onXpEarned: widget.onXpEarned,
                                onBadgeComplete: (badgeId) {
                                  _handleBadgeComplete(badgeId);
                                },
                                claimedBonuses: _claimedBadgeBonuses,
                                onClaimBonus: _claimBadgeBonus,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: filteredBadges.length,
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

  Widget _buildFilterChips() {
    final filters = ['All', 'Unlocked', 'In Progress', 'Locked'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF16A34A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade300,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// XP PROGRESS CARD (ACCURATE)
// ============================================================

class _XpProgressCard extends StatelessWidget {
  final int xp;
  final int level;
  final int xpInCurrentLevel;
  final int xpToNext;
  final int xpRange;
  final int completedBadges;
  final int totalBadges;

  const _XpProgressCard({
    required this.xp,
    required this.level,
    required this.xpInCurrentLevel,
    required this.xpToNext,
    required this.xpRange,
    required this.completedBadges,
    required this.totalBadges,
  });

  void _showLevelInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _LevelInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = xpRange > 0 ? (xpInCurrentLevel / xpRange).clamp(0.0, 1.0) : 0.0;

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
                  const Text('Level', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('$level', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showLevelInfo(context),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.info_outline, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text('⭐ $xp XP', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('$xpInCurrentLevel / $xpRange XP', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              const SizedBox(width: 8),
              Text('$xpToNext XP to next level', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 8, color: Colors.white.withOpacity(0.25)),
                FractionallySizedBox(widthFactor: progress.clamp(0.0, 1.0), child: Container(height: 8, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)])))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatChip(icon: '🏅', label: '$completedBadges/$totalBadges Badges'),
              const SizedBox(width: 10),
              _StatChip(icon: '🌟', label: '${(completedBadges / totalBadges * 100).toInt()}% Complete'),
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============================================================
// LEVEL INFO DIALOG
// ============================================================

class _LevelInfoDialog extends StatelessWidget {
  const _LevelInfoDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFFFBBF24)),
          const SizedBox(width: 8),
          const Text('Level Requirements'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...LevelConfig.levels.map((level) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: level.level == 10 ? const Color(0xFFFBBF24).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: level.level == 10 ? const Color(0xFFFBBF24) : Colors.grey.withOpacity(0.2)),
                    ),
                    alignment: Alignment.center,
                    child: Text('${level.level}', style: TextStyle(fontWeight: FontWeight.bold, color: level.level == 10 ? const Color(0xFFFBBF24) : Colors.black87)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(level.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${level.xpRequired} XP required', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}

// ============================================================
// XP BREAKDOWN SECTION
// ============================================================

class _XpBreakdownSection extends StatelessWidget {
  final List<XpSource> xpSources;
  const _XpBreakdownSection({required this.xpSources});

  @override
  Widget build(BuildContext context) {
    if (xpSources.isEmpty) return const SizedBox.shrink();
    int totalXp = xpSources.fold(0, (sum, s) => sum + s.xp);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('XP Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFDECC8), borderRadius: BorderRadius.circular(12)),
                  child: Text('Total: +$totalXp XP', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB8720A))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...xpSources.map((source) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(source.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(source.source, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  const Spacer(),
                  Text('+${source.xp} XP', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RECENT ACHIEVEMENTS SECTION
// ============================================================

class _RecentAchievementsSection extends StatelessWidget {
  final List<RecentAchievement> achievements;
  const _RecentAchievementsSection({required this.achievements});

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Achievements', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...achievements.take(3).map((achievement) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: achievement.type == RecentType.badge ? const Color(0xFFDCFCE7) : const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(achievement.icon, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(achievement.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text(achievement.description, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Text(achievement.formattedDate, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PROGRESSIVE BADGE CARD
// ============================================================

class _ProgressiveBadgeCard extends StatelessWidget {
  final StateBadge badge;
  final int unlockedPieces;
  final bool isComplete;
  final double progress;
  final VoidCallback onTap;

  const _ProgressiveBadgeCard({
    required this.badge,
    required this.unlockedPieces,
    required this.isComplete,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isComplete ? const Color(0xFFE9F9EF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isComplete ? const Color(0xFF16A34A) : Colors.grey.withOpacity(0.15), width: isComplete ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: isComplete ? const Color(0xFF16A34A) : Colors.grey.withOpacity(0.1))),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 4,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(isComplete ? const Color(0xFF16A34A) : const Color(0xFF6D5BD0)),
                  ),
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: isComplete ? const Color(0xFF16A34A) : Colors.transparent, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: isComplete ? Text(badge.badgeIcon, style: const TextStyle(fontSize: 28)) : Text(badge.badgeIcon, style: TextStyle(fontSize: 28, color: Colors.black.withOpacity(0.5 + progress * 0.5))),
                    ),
                  ),
                ),
                if (!isComplete && progress > 0)
                  Positioned(
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF6D5BD0), borderRadius: BorderRadius.circular(8)),
                      child: Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                if (isComplete)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(badge.stateName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isComplete ? const Color(0xFF16A34A) : Colors.black), textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(isComplete ? '✅ Completed!' : '${(progress * 100).toInt()}% Complete', style: TextStyle(fontSize: 11, color: isComplete ? const Color(0xFF16A34A) : Colors.grey[600])),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isComplete ? const Color(0xFF16A34A).withOpacity(0.1) : const Color(0xFF6D5BD0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge.badgeTheme, style: TextStyle(fontSize: 9, color: isComplete ? const Color(0xFF16A34A) : const Color(0xFF6D5BD0))),
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
  final ValueChanged<String> onBadgeComplete;
  final Set<String> claimedBonuses;
  final ClaimBonusCallback onClaimBonus;

  const BadgeDetailScreen({
    super.key,
    required this.badge,
    required this.visitedSites,
    required this.totalXp,
    required this.onXpEarned,
    required this.onBadgeComplete,
    required this.claimedBonuses,
    required this.onClaimBonus,
  });

  @override
  State<BadgeDetailScreen> createState() => _BadgeDetailScreenState();
}

class _BadgeDetailScreenState extends State<BadgeDetailScreen> {
  bool _bonusClaimed = false;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    if (widget.claimedBonuses.contains(widget.badge.id)) {
      _bonusClaimed = true;
    }
    if (widget.badge.isComplete(widget.visitedSites) && !_celebrated) {
      _celebrated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onBadgeComplete(widget.badge.id);
      });
    }
  }

  void _claimBonus() {
    if (_bonusClaimed) return;
    if (widget.badge.isComplete(widget.visitedSites)) {
      setState(() => _bonusClaimed = true);
      widget.onClaimBonus(widget.badge.id, widget.badge.bonusXp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.badge.getUnlockedPieces(widget.visitedSites);
    final complete = widget.badge.isComplete(widget.visitedSites);
    final progress = widget.badge.getProgress(widget.visitedSites);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(title: Text('${widget.badge.stateName} Badge'), backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: complete ? const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF0D9488)]) : const LinearGradient(colors: [Color(0xFF6D5BD0), Color(0xFF8B7FE8)]),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle)),
                      ClipRect(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          heightFactor: progress.clamp(0.0, 1.0),
                          child: Container(width: 80, height: 80, alignment: Alignment.center, child: Text(widget.badge.badgeIcon, style: const TextStyle(fontSize: 36))),
                        ),
                      ),
                      if (complete)
                        Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), alignment: Alignment.center, child: Text(widget.badge.badgeIcon, style: const TextStyle(fontSize: 36))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(widget.badge.stateName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(widget.badge.badgeTheme, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${(progress * 100).toInt()}% Complete', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                children: [
                                  Container(height: 6, color: Colors.white.withOpacity(0.25)),
                                  FractionallySizedBox(widthFactor: progress.clamp(0.0, 1.0), child: Container(height: 6, color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  if (complete) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFFBBF24), borderRadius: BorderRadius.circular(20)),
                      child: const Text('✨ COMPLETE ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (complete && !_bonusClaimed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFE9F9EF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF16A34A))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🎉 Badge Completed!', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        const SizedBox(height: 2),
                        Text('Claim +${widget.badge.bonusXp} XP bonus', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _claimBonus,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Claim Bonus'),
                    ),
                  ],
                ),
              ),

            if (complete && _bonusClaimed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFE9F9EF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF16A34A))),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                    SizedBox(width: 10),
                    Text('Bonus claimed! +150 XP', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            const Text('Required Heritage Sites', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('$unlocked / ${widget.badge.totalPieces} locations visited', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 10),

            ...widget.badge.requiredSiteIds.map((siteId) {
              final visited = widget.visitedSites.contains(siteId);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: visited ? const Color(0xFFE9F9EF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: visited ? const Color(0xFF16A34A) : Colors.grey.withOpacity(0.15), width: visited ? 1.5 : 1),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: visited ? const Color(0xFF16A34A) : Colors.grey.withOpacity(0.15), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: visited ? const Icon(Icons.check, color: Colors.white, size: 16) : const Icon(Icons.lock_outline, color: Colors.grey, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(siteId.replaceFirst('site_', '').toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: visited ? Colors.black : Colors.grey[600])),
                          Text(visited ? '✅ Visited' : '🔒 Not yet visited', style: TextStyle(fontSize: 11, color: visited ? const Color(0xFF16A34A) : Colors.grey[500])),
                        ],
                      ),
                    ),
                    if (visited) const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About this badge', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(widget.badge.description, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
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

// ============================================================
// UNLOCK CELEBRATION DIALOG
// ============================================================

class _UnlockCelebrationDialog extends StatelessWidget {
  final BadgeUnlockData unlock;
  final VoidCallback onDismiss;
  final VoidCallback onViewBadge;

  const _UnlockCelebrationDialog({
    required this.unlock,
    required this.onDismiss,
    required this.onViewBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1130), Color(0xFF141B4D), Color(0xFF1B1440)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉 🎊 🎉', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            const Text(
              'ACHIEVEMENT UNLOCKED!',
              style: TextStyle(
                color: Color(0xFFFBBF24),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFBBF24).withOpacity(0.3),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(unlock.badgeIcon, style: const TextStyle(fontSize: 44)),
            ),
            const SizedBox(height: 16),
            Text(
              unlock.stateName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unlock.badgeTheme,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You completed all required heritage locations!',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,   // ✅ No extra parenthesis here
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFBBF24).withOpacity(0.3),
                ),
              ),
              child: Text(
                '+${unlock.xpReward} XP',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDismiss();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onViewBadge();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('View Badge'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}