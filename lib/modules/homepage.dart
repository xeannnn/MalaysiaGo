import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/achievement_provider.dart';
import '../widgets/app_header.dart';
import 'auth/profile_screen.dart';
import 'heritage_explorer.dart';

// ================================================================
// HOME SCREEN
// ================================================================

class HomeScreen extends StatefulWidget {
  final int totalXp;
  final ValueChanged<BottomTab> onTabSelected;

  const HomeScreen({
    super.key,
    required this.totalXp,
    required this.onTabSelected,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'MalaysiaGO User';
  String _userState = 'Malaysia';
  String? _photoUrl;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }

      return;
    }

    String name = user.displayName?.trim() ?? '';
    String state = '';
    String? photoUrl = user.photoURL;

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final Map<String, dynamic>? data = snapshot.data();

      if (data != null) {
        final String firestoreName =
            data['name']?.toString().trim() ?? '';

        final String firestoreState =
            data['state']?.toString().trim() ?? '';

        final String firestorePhoto =
            data['photoUrl']?.toString().trim() ?? '';

        if (firestoreName.isNotEmpty) {
          name = firestoreName;
        }

        if (firestoreState.isNotEmpty) {
          state = firestoreState;
        }

        if (firestorePhoto.isNotEmpty) {
          photoUrl = firestorePhoto;
        }
      }
    } catch (error) {
      debugPrint(
        'Failed to load home profile: $error',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _userName =
      name.isEmpty ? 'MalaysiaGO User' : name;

      _userState =
      state.isEmpty ? 'Malaysia' : state;

      _photoUrl = photoUrl;
      _isLoadingProfile = false;
    });
  }

  bool _hasVisitedSite(
      AchievementProvider provider,
      ) {
    return provider.visitedSites.values.any(
          (sites) => sites.isNotEmpty,
    );
  }

  int _visitedSiteCount(
      AchievementProvider provider,
      ) {
    return provider.visitedSites.values.fold<int>(
      0,
          (total, sites) => total + sites.length,
    );
  }

  int _visitedStateCount(
      AchievementProvider provider,
      ) {
    return provider.visitedSites.values
        .where((sites) => sites.isNotEmpty)
        .length;
  }

  String _formatXp(int xp) {
    final String digits = xp.toString();
    final StringBuffer result = StringBuffer();

    for (int index = 0;
    index < digits.length;
    index++) {
      final int remaining = digits.length - index;

      result.write(digits[index]);

      if (remaining > 1 && remaining % 3 == 1) {
        result.write(',');
      }
    }

    return result.toString();
  }

  List<HomeRanking> _buildRankings(int userXp) {
    final List<HomeRanking> rankings = [
      const HomeRanking(
        avatar: '🧕',
        name: 'Albert Chin',
        state: 'Selangor',
        xp: 4820,
        isYou: false,
      ),
      const HomeRanking(
        avatar: '🧑',
        name: 'Kaiser Tan',
        state: 'Penang',
        xp: 4310,
        isYou: false,
      ),
      const HomeRanking(
        avatar: '👩',
        name: 'Mei Lin Tan',
        state: 'Malacca',
        xp: 3720,
        isYou: false,
      ),
      HomeRanking(
        avatar: '🙂',
        name: '$_userName (You)',
        state: _userState,
        xp: userXp,
        isYou: true,
      ),
    ];

    rankings.sort(
          (first, second) =>
          second.xp.compareTo(first.xp),
    );

    return rankings;
  }

  void _openGpsCheckIn() {
    widget.onTabSelected(BottomTab.scan);
  }

  void _openHeritageMap() {
    widget.onTabSelected(BottomTab.map);
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileScreen(),
      ),
    );

    if (mounted) {
      await _loadUserProfile();
    }
  }

  void _openHeritageExplorer(int currentXp) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HeritageExplorerScreen(
          totalXp: currentXp,
          onTabSelected: widget.onTabSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AchievementProvider provider =
    Provider.of<AchievementProvider>(context);

    final int currentXp = provider.totalXp;
    final int level = provider.level.level;
    final String levelTitle = provider.level.title;
    final int xpToNextLevel =
        provider.xpToNextLevel;
    final int completedBadges =
        provider.completedBadges;
    final int visitedSites =
    _visitedSiteCount(provider);
    final int visitedStates =
    _visitedStateCount(provider);

    final bool gpsMissionCompleted =
    _hasVisitedSite(provider);

    final bool quizMissionCompleted =
        provider.completedQuizIds.isNotEmpty;

    final List<HomeMission> missions = [
      HomeMission(
        icon: '📍',
        title: 'GPS Check-In at a heritage site',
        xp: '+50 XP',
        completed: gpsMissionCompleted,
        onTap: _openGpsCheckIn,
      ),
      HomeMission(
        icon: '📝',
        title: 'Complete a heritage quiz',
        xp: '+40 XP',
        completed: quizMissionCompleted,
        onTap: _openHeritageMap,
      ),
      const HomeMission(
        icon: '🤝',
        title: 'Refer a friend to MalaysiaGO',
        xp: '+100 XP',
        completed: false,
      ),
    ];

    final int completedMissionCount = missions
        .where((mission) => mission.completed)
        .length;

    final List<HomeRanking> rankings =
    _buildRankings(currentXp);

    return Column(
      children: [
        AppHeader(
          title: 'MalaysiaGO',
          subtitle: 'Your Heritage Journey 🇲🇾',
          xp: '$currentXp',
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUserProfile,
            child: ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              children: [
                WelcomeCard(
                  name: _isLoadingProfile
                      ? 'Loading...'
                      : _userName,
                  photoUrl: _photoUrl,
                  onProfileTap: _openProfile,
                  level: level,
                  levelTitle: levelTitle,
                  currentXp: currentXp,
                  xpToNextLevel: xpToNextLevel,
                  badges: completedBadges,
                  sites: visitedSites,
                  states: visitedStates,
                ),
                const SizedBox(height: 16),
                QuickActionsRow(
                  onGpsCheckIn: _openGpsCheckIn,
                  onNearbySites: _openHeritageMap,
                ),
                const SizedBox(height: 16),
                ExploreGuideCard(
                  onTap: () =>
                      _openHeritageExplorer(currentXp),
                ),
                const SizedBox(height: 22),
                SectionHeading(
                  title: 'Daily Missions',
                  trailing:
                  '$completedMissionCount/${missions.length} Done',
                ),
                const SizedBox(height: 12),
                ...missions.map(
                      (mission) => Padding(
                    padding:
                    const EdgeInsets.only(bottom: 10),
                    child: MissionCard(
                      mission: mission,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeading(
                  title: 'Weekly Rankings',
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  rankings.length,
                      (index) {
                    return Padding(
                      padding:
                      const EdgeInsets.only(bottom: 8),
                      child: RankingRow(
                        rank: index + 1,
                        entry: rankings[index],
                        formattedXp:
                        _formatXp(rankings[index].xp),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// LOCAL VIEW MODELS
// ================================================================

class HomeMission {
  final String icon;
  final String title;
  final String xp;
  final bool completed;
  final VoidCallback? onTap;

  const HomeMission({
    required this.icon,
    required this.title,
    required this.xp,
    required this.completed,
    this.onTap,
  });
}

class HomeRanking {
  final String avatar;
  final String name;
  final String state;
  final int xp;
  final bool isYou;

  const HomeRanking({
    required this.avatar,
    required this.name,
    required this.state,
    required this.xp,
    required this.isYou,
  });
}

// ================================================================
// SECTION HEADING
// ================================================================

class SectionHeading extends StatelessWidget {
  final String title;
  final String? trailing;

  const SectionHeading({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECC8),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB8720A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ================================================================
// WELCOME CARD
// ================================================================

class WelcomeCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final VoidCallback onProfileTap;
  final int level;
  final String levelTitle;
  final int currentXp;
  final int xpToNextLevel;
  final int badges;
  final int sites;
  final int states;

  const WelcomeCard({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.onProfileTap,
    required this.level,
    required this.levelTitle,
    required this.currentXp,
    required this.xpToNextLevel,
    required this.badges,
    required this.sites,
    required this.states,
  });

  double get _levelProgress {
    if (level >= LevelConfig.levels.last.level) {
      return 1;
    }

    final int currentLevelMinimum =
        LevelConfig.getLevelByXp(
          currentXp,
        ).xpRequired;

    final int nextLevelMinimum =
        currentXp + xpToNextLevel;

    final int levelRange =
        nextLevelMinimum - currentLevelMinimum;

    if (levelRange <= 0) {
      return 1;
    }

    return ((currentXp - currentLevelMinimum) /
        levelRange)
        .clamp(0.0, 1.0);
  }

  String get _profileInitial {
    final String trimmedName = name.trim();

    if (trimmedName.isEmpty ||
        trimmedName == 'Loading...') {
      return 'U';
    }

    return trimmedName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool maximumLevel =
        level >= LevelConfig.levels.last.level;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F8A5C),
            Color(0xFF14532D),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: Stack(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: photoUrl != null &&
                          photoUrl!.isNotEmpty
                          ? ClipOval(
                        child: Image.network(
                          photoUrl!,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) {
                            return Text(
                              _profileInitial,
                              style:
                              const TextStyle(
                                color:
                                Colors.white,
                                fontSize: 24,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      )
                          : Text(
                        _profileInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 19,
                        height: 19,
                        decoration:
                        const BoxDecoration(
                          color: Color(0xFFF5A623),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.75),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Level $level · $levelTitle',
                      style: const TextStyle(
                        color: Color(0xFFFCD34D),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total XP',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '$currentXp',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text(
                maximumLevel
                    ? 'Maximum level reached'
                    : 'Progress to Level ${level + 1}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                maximumLevel
                    ? '$currentXp XP'
                    : '$xpToNextLevel XP remaining',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius:
            BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: _levelProgress,
              minHeight: 8,
              backgroundColor:
              Colors.white.withOpacity(0.2),
              valueColor:
              const AlwaysStoppedAnimation<Color>(
                Color(0xFF34D399),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: StatMiniCard(
                  icon: '🏅',
                  value: '$badges',
                  label: 'Badges',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatMiniCard(
                  icon: '📍',
                  value: '$sites',
                  label: 'Sites',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatMiniCard(
                  icon: '🇲🇾',
                  value: '$states',
                  label: 'States',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatMiniCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const StatMiniCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 17),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// QUICK ACTIONS
// ================================================================

class QuickActionsRow extends StatelessWidget {
  final VoidCallback onGpsCheckIn;
  final VoidCallback onNearbySites;

  const QuickActionsRow({
    super.key,
    required this.onGpsCheckIn,
    required this.onNearbySites,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QuickActionCard(
            icon: '📍',
            title: 'GPS Check-In',
            subtitle: 'Check in at nearby sites',
            colors: const [
              Color(0xFF16A34A),
              Color(0xFF0D9488),
            ],
            onTap: onGpsCheckIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: QuickActionCard(
            icon: '🗺️',
            title: 'Nearby Sites',
            subtitle: 'Explore the heritage map',
            colors: const [
              Color(0xFF4F46E5),
              Color(0xFF7C3AED),
            ],
            onTap: onNearbySites,
          ),
        ),
      ],
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: colors,
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                icon,
                style:
                const TextStyle(fontSize: 21),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// EXPLORER CARD
// ================================================================

class ExploreGuideCard extends StatelessWidget {
  final VoidCallback onTap;

  const ExploreGuideCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4F46E5),
                Color(0xFF7C3AED),
              ],
            ),
          ),
          child: const Row(
            children: [
              Text(
                '🧭',
                style: TextStyle(fontSize: 34),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Malaysia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Discover heritage sites, travel tips, and cultural guides.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// MISSION CARD
// ================================================================

class MissionCard extends StatelessWidget {
  final HomeMission mission;

  const MissionCard({
    super.key,
    required this.mission,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: mission.completed
          ? const Color(0xFFE9F9EF)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: mission.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Text(
                mission.icon,
                style:
                const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: mission.completed
                            ? const Color(0xFF16A34A)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mission.xp,
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: mission.completed
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF0F0F0),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: mission.completed
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                )
                    : const Icon(
                  Icons.arrow_forward,
                  color: Colors.grey,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// WEEKLY RANKINGS
// ================================================================

class RankingRow extends StatelessWidget {
  final int rank;
  final HomeRanking entry;
  final String formattedXp;

  const RankingRow({
    super.key,
    required this.rank,
    required this.entry,
    required this.formattedXp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: entry.isYou
            ? const Color(0xFFE9F9EF)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: entry.isYou
            ? Border.all(
          color: const Color(0xFF86EFAC),
        )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              rank == 1 ? '🏆' : '$rank',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F0F0),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              entry.avatar,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: entry.isYou
                        ? const Color(0xFF16A34A)
                        : Colors.black87,
                    fontSize: 14,
                    fontWeight: entry.isYou
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
                Text(
                  entry.state,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$formattedXp XP',
            style: const TextStyle(
              color: Color(0xFFB8720A),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}