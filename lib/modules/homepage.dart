import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/app_header.dart';

/// Home screen. Order top to bottom:
/// AppHeader -> WelcomeCard -> QuickActionsRow -> ExploreGuideCard
/// -> Daily Missions -> Weekly Rankings.
/// `totalXp` is the user's current XP (starts at 0, grows as quizzes
/// are completed) — passed down from MainScreen in main.dart.
class HomeScreen extends StatelessWidget {
  final int totalXp;
  const HomeScreen({super.key, required this.totalXp});

  @override
  Widget build(BuildContext context) {
    const missions = [
      Mission('📍', 'Visit a heritage site today', '+50 XP', true),
      Mission('📷', 'Scan a QR code at any site', '+30 XP', false),
      Mission('📝', 'Complete a heritage quiz', '+40 XP', false),
      Mission('🤝', 'Refer a friend to MalaysiaGO', '+100 XP', false),
    ];
    const rankings = [
      RankEntry(1, '🧕', 'Albert Chin', 'Selangor', '4,820 XP', false),
      RankEntry(2, '🧑', 'Kaiser Tan', 'Penang', '4,310 XP', false),
      RankEntry(3, '🤓', 'Alston Chung (You)', 'KL', '3,940 XP', true),
      RankEntry(4, '👩', 'Mei Lin Tan', 'Malacca', '3,720 XP', false),
    ];

    return Column(
      children: [
        AppHeader(title: 'MalaysiaGO', subtitle: 'Your Heritage Journey 🇲🇾', xp: '$totalXp'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              WelcomeCard(
                name: 'Alston Chung',
                avatarEmoji: '🤓',
                level: 6,
                nextLevel: 7,
                streakDays: 7,
                currentXp: totalXp,
                xpToNextLevel: 1500,
                badges: 5,
                pieces: 24,
                states: 5,
              ),
              const SizedBox(height: 16),
              const QuickActionsRow(),
              const SizedBox(height: 16),
              const ExploreGuideCard(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daily Missions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFDECC8), borderRadius: BorderRadius.circular(12)),
                    child: const Text('1/4 Done', style: TextStyle(fontSize: 12, color: Color(0xFFB8720A))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...missions.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MissionCard(mission: m),
              )),
              const SizedBox(height: 16),
              const Text('Weekly Rankings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...rankings.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RankRow(entry: r),
              )),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- Welcome / profile card ----------
class WelcomeCard extends StatelessWidget {
  final String name;
  final String avatarEmoji;
  final int level;
  final int nextLevel;
  final int streakDays;
  final int currentXp;
  final int xpToNextLevel;
  final int badges;
  final int pieces;
  final int states;

  const WelcomeCard({
    super.key,
    required this.name,
    required this.avatarEmoji,
    required this.level,
    required this.nextLevel,
    required this.streakDays,
    required this.currentXp,
    required this.xpToNextLevel,
    required this.badges,
    required this.pieces,
    required this.states,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentXp / xpToNextLevel).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F8A5C), Color(0xFF14532D)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(avatarEmoji, style: const TextStyle(fontSize: 26)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(color: Color(0xFFF5A623), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text('$level',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selamat Datang,', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75))),
                      Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration:
                        BoxDecoration(color: const Color(0xFFF5A623), borderRadius: BorderRadius.circular(10)),
                        child: Text('✦ Level $level',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(height: 4),
                      Text('Heritage Adventurer', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 18)),
                  Text('${streakDays}d', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('XP to Level $nextLevel', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75))),
              Text('$currentXp / $xpToNextLevel',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 7, color: Colors.white.withOpacity(0.2)),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 7,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF34D6C7), Color(0xFF8B5CF6)]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: StatMiniCard(icon: '🏅', value: '$badges', label: 'Badges')),
              const SizedBox(width: 10),
              Expanded(child: StatMiniCard(icon: '🧩', value: '$pieces', label: 'Pieces')),
              const SizedBox(width: 10),
              Expanded(child: StatMiniCard(icon: '📍', value: '$states', label: 'States')),
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

  const StatMiniCard({super.key, required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.75))),
        ],
      ),
    );
  }
}

// ---------- Quick action cards ----------
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: QuickActionCard(
            icon: '📷',
            title: 'Scan QR Code',
            subtitle: 'Collect XP at sites',
            colors: [Color(0xFF16A34A), Color(0xFF0D9488)],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: QuickActionCard(
            icon: '🗺️',
            title: 'Nearby Sites',
            subtitle: '3 sites within 5 km',
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
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

  const QuickActionCard(
      {super.key, required this.icon, required this.title, required this.subtitle, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: colors),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.85))),
        ],
      ),
    );
  }
}

// ---------- Traveller's Guide card ----------
class ExploreGuideCard extends StatelessWidget {
  const ExploreGuideCard({super.key});

  @override
  Widget build(BuildContext context) {
    const chips = [
      GuideChip('⛩️', 'Batu'),
      GuideChip('🏛️', 'George'),
      GuideChip('🏰', 'Malacca'),
      GuideChip('🚆', 'Transport'),
      GuideChip('🙏', 'Etiquette'),
      GuideChip('🛡️', 'Safety'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: const Text('📖', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Explore Malaysia', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75))),
                    const Text("Traveller's Guide",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('12 heritage sites · Transport · Etiquette · Safety',
                        style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ),
              const Text('›', style: TextStyle(fontSize: 20, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final chip = chips[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(chip.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(chip.label, style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Missions & rankings ----------
class MissionCard extends StatelessWidget {
  final Mission mission;
  const MissionCard({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mission.done ? const Color(0xFFE9F9EF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(mission.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: mission.done ? const Color(0xFF16A34A) : Colors.black,
                    ),
                  ),
                  Text(mission.xp, style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A))),
                ],
              ),
            ],
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: mission.done ? const Color(0xFF16A34A) : const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              mission.done ? '✓' : '→',
              style: TextStyle(color: mission.done ? Colors.white : Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class RankRow extends StatelessWidget {
  final RankEntry entry;
  const RankRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: entry.isYou ? const Color(0xFFE9F9EF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              entry.rank == 1 ? '🏆' : '${entry.rank}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(entry.avatar, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: entry.isYou ? const Color(0xFF16A34A) : Colors.black,
                  ),
                ),
                Text(entry.state, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(entry.xp, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB8720A))),
        ],
      ),
    );
  }
}
