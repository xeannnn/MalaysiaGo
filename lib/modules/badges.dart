import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../models.dart';

// ============================================================
// BADGE DATA - All 13 Malaysian States
// ============================================================

/// Predefined state badges with their required heritage sites
/// Note: site IDs should match actual site IDs from your database
const List<StateBadge> _allBadges = [
  StateBadge(
    id: 'badge_kl',
    stateName: 'Kuala Lumpur',
    badgeIcon: '🐅',
    badgeTheme: 'Malayan Tiger',
    requiredSiteIds: [
      'site_klcc',
      'site_pasar_seni',
      'site_perdana_garden',
      'site_merdeka_square',
    ],
    totalPieces: 4,
    description: 'Complete all heritage sites in Kuala Lumpur',
  ),
  StateBadge(
    id: 'badge_melaka',
    stateName: 'Melaka',
    badgeIcon: '🦌',
    badgeTheme: 'Mousedeer (Kancil)',
    requiredSiteIds: [
      'site_afamosa',
      'site_st_paul',
      'site_jonker_street',
      'site_melaka_sultanate',
    ],
    totalPieces: 4,
    description: 'Complete all heritage sites in Melaka',
  ),
  StateBadge(
    id: 'badge_sarawak',
    stateName: 'Sarawak',
    badgeIcon: '🦅',
    badgeTheme: 'Hornbill',
    requiredSiteIds: [
      'site_sarawak_museum',
      'site_kuching_waterfront',
      'site_semenggoh',
    ],
    totalPieces: 3,
    description: 'Complete all heritage sites in Sarawak',
  ),
  StateBadge(
    id: 'badge_sabah',
    stateName: 'Sabah',
    badgeIcon: '🐒',
    badgeTheme: 'Proboscis Monkey',
    requiredSiteIds: [
      'site_mt_kinabalu',
      'site_miso_walai',
      'site_sepilok',
    ],
    totalPieces: 3,
    description: 'Complete all heritage sites in Sabah',
  ),
  StateBadge(
    id: 'badge_penang',
    stateName: 'Penang',
    badgeIcon: '🌴',
    badgeTheme: 'Betel Nut / Penang Bridge',
    requiredSiteIds: [
      'site_fort_cornwallis',
      'site_penang_street_art',
      'site_khoo_kongsi',
      'site_kek_lok_si',
      'site_pinang_peranakan',
    ],
    totalPieces: 5,
    description: 'Complete all heritage sites in Penang',
  ),
  StateBadge(
    id: 'badge_perak',
    stateName: 'Perak',
    badgeIcon: '🐃',
    badgeTheme: 'Seladang',
    requiredSiteIds: [
      'site_kellie_castle',
      'site_gua_tempurung',
      'site_perak_museum',
    ],
    totalPieces: 3,
    description: 'Complete all heritage sites in Perak',
  ),
  StateBadge(
    id: 'badge_pahang',
    stateName: 'Pahang',
    badgeIcon: '🐘',
    badgeTheme: 'Elephant',
    requiredSiteIds: [
      'site_taman_negara',
      'site_gua_tempurung',
    ],
    totalPieces: 2,
    description: 'Complete all heritage sites in Pahang',
  ),
  // Add more states as needed
];

// ============================================================
// MAIN BADGES SCREEN
// ============================================================

/// Achievement & Rewards Screen
/// Displays:
/// 1. User's overall progress (XP, Level, Completion)
/// 2. List of all state badges with progress
/// 3. Detailed view of each badge
class BadgesScreen extends StatefulWidget {
  final int totalXp;
  final ValueChanged<int> onXpEarned;

  const BadgesScreen({
    super.key,
    required this.totalXp,
    required this.onXpEarned,
  });

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  // Simulated user progress - replace with actual data from Firebase/Hive
  // In production, these would come from the user's profile in Firestore
  final Map<String, List<String>> _visitedSites = {
    // "badge_kl": ['site_klcc', 'site_pasar_seni'],
    // "badge_melaka": ['site_afamosa', 'site_st_paul', 'site_jonker_street'],
  };

  // XP thresholds for each level
  static const List<int> _levelThresholds = [
    0, 100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700, 3250
  ];

  int _getLevel(int xp) {
    int level = 1;
    for (int i = 1; i < _levelThresholds.length; i++) {
      if (xp >= _levelThresholds[i]) {
        level = i + 1;
      }
    }
    return level;
  }

  int _getXpToNextLevel(int xp) {
    int currentLevel = _getLevel(xp);
    if (currentLevel >= _levelThresholds.length) {
      return 0;
    }
    int nextThreshold = _levelThresholds[currentLevel];
    return nextThreshold - xp;
  }

  List<UserBadgeProgress> _getUserBadgeProgress() {
    List<UserBadgeProgress> progress = [];

    for (StateBadge badge in _allBadges) {
      List<String> visited = _visitedSites[badge.id] ?? [];
      int unlocked = badge.getUnlockedPieces(visited);
      bool complete = badge.isComplete(visited);

      progress.add(UserBadgeProgress(
        badgeId: badge.id,
        stateName: badge.stateName,
        badgeIcon: badge.badgeIcon,
        badgeTheme: badge.badgeTheme,
        totalPieces: badge.totalPieces,
        unlockedPieces: unlocked,
        isComplete: complete,
        xpEarned: complete ? 150 : 0, // Bonus XP when badge is completed
      ));
    }

    return progress;
  }

  int _getCompletedBadgeCount() {
    int count = 0;
    for (StateBadge badge in _allBadges) {
      List<String> visited = _visitedSites[badge.id] ?? [];
      if (badge.isComplete(visited)) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final userLevel = _getLevel(widget.totalXp);
    final xpToNext = _getXpToNextLevel(widget.totalXp);
    final completedBadges = _getCompletedBadgeCount();
    final totalBadges = _allBadges.length;
    final badgeProgressList = _getUserBadgeProgress();

    return Column(
      children: [
        AppHeader(
          title: 'Achievements',
          subtitle: 'Complete state badges to unlock rewards',
          xp: '${widget.totalXp}',
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              // XP Progress Card
              SliverToBoxAdapter(
                child: _XpProgressCard(
                  xp: widget.totalXp,
                  level: userLevel,
                  xpToNext: xpToNext,
                  completedBadges: completedBadges,
                  totalBadges: totalBadges,
                ),
              ),
              // Badge Collection Grid
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'State Badges',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F8A5F),
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
                      final badge = _allBadges[index];
                      final visited = _visitedSites[badge.id] ?? [];
                      final unlocked = badge.getUnlockedPieces(visited);
                      final complete = badge.isComplete(visited);

                      return _BadgeCard(
                        badge: badge,
                        unlockedPieces: unlocked,
                        isComplete: complete,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BadgeDetailScreen(
                                badge: badge,
                                visitedSites: visited,
                                totalXp: widget.totalXp,
                                onXpEarned: widget.onXpEarned,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: _allBadges.length,
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
    final progress = xpToNext > 0
        ? (xp % 1000) / 1000 // Simplified progress calculation
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
                '${xp % 1000} / 1000 XP',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
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
            // Badge Icon with progress ring
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

/// Detailed view of a single state badge showing:
/// 1. Badge name and theme
/// 2. Progress indicator
/// 3. List of required heritage sites with visit status
/// 4. Completion status and bonus XP
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

  @override
  void initState() {
    super.initState();
    // Check if badge is complete and bonus hasn't been claimed
    if (widget.badge.isComplete(widget.visitedSites)) {
      // In production, check if bonus was already claimed from Firestore
      // For now, we'll check local state
    }
  }

  void _claimBonus() {
    if (widget.badge.isComplete(widget.visitedSites) && !_bonusClaimed) {
      setState(() {
        _bonusClaimed = true;
      });
      widget.onXpEarned(150); // Bonus XP for completing a badge
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Bonus +150 XP for completing this badge!'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
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
                  // Badge Icon
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
                  // Progress Bar
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