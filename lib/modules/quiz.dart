import 'package:flutter/material.dart';

/// ---------------------------------------------------------------
/// HERITAGE QUIZ MODULE
/// ---------------------------------------------------------------
/// Everything for the heritage quiz feature lives in this one file
/// so it can be dropped into the project as a single, self-contained
/// unit: data models, question retrieval, and all three screens
/// (intro -> question flow -> results).
///
/// Entry point: QuizIntroScreen(siteId: '<id>')
/// ---------------------------------------------------------------

// ============================== MODELS ==============================

/// A single multiple-choice quiz question tied to a heritage site.
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int xpReward;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.xpReward,
  });
}

/// Metadata for the heritage site a quiz belongs to — shown on the
/// quiz intro card before the questions start.
class QuizSite {
  final String id;
  final String icon;
  final String name;
  final String location;
  final String category;
  final String description;
  final String difficulty;

  const QuizSite({
    required this.id,
    required this.icon,
    required this.name,
    required this.location,
    required this.category,
    required this.description,
    required this.difficulty,
  });
}

/// A record of one completed quiz attempt — used to block retakes and
/// to power the quiz history/scores screen.
class QuizAttempt {
  final String siteId;
  final String siteName;
  final String siteIcon;
  final int correctCount;
  final int totalQuestions;
  final int xpEarned;
  final DateTime completedAt;

  const QuizAttempt({
    required this.siteId,
    required this.siteName,
    required this.siteIcon,
    required this.correctCount,
    required this.totalQuestions,
    required this.xpEarned,
    required this.completedAt,
  });

  /// Plain-map form for Hive persistence (Hive can't store a custom
  /// class directly without a registered TypeAdapter, so this stores
  /// it as a Map instead — see AchievementProvider).
  Map<String, dynamic> toMap() => {
    'siteId': siteId,
    'siteName': siteName,
    'siteIcon': siteIcon,
    'correctCount': correctCount,
    'totalQuestions': totalQuestions,
    'xpEarned': xpEarned,
    'completedAt': completedAt.toIso8601String(),
  };

  factory QuizAttempt.fromMap(Map<dynamic, dynamic> map) => QuizAttempt(
    siteId: map['siteId'] as String,
    siteName: map['siteName'] as String,
    siteIcon: map['siteIcon'] as String,
    correctCount: map['correctCount'] as int,
    totalQuestions: map['totalQuestions'] as int,
    xpEarned: map['xpEarned'] as int,
    completedAt: DateTime.parse(map['completedAt'] as String),
  );
}

/// Called when a quiz is finished. MainScreen (main.dart) uses this to
/// add the XP to the running total, mark the site as completed so it
/// can't be retaken, and record a QuizAttempt for the history screen.
typedef QuizCompleteCallback = void Function(QuizAttempt attempt);

// ========================= QUESTION RETRIEVAL =========================

/// Retrieves quiz site info and quiz questions for a given heritage
/// site ID.
///
/// Currently backed by an in-memory map so the quiz UI can be built
/// and demoed without a live backend. To switch to real data later
/// (per the project proposal's Firestore backend), replace the body
/// of [getSite] and [getQuestions] with a Firestore query keyed by
/// the same `siteId` — the calling screens below don't need to change.
class QuizRepository {
  QuizRepository._();

  static final Map<String, QuizSite> _sites = {
    'batu_caves': const QuizSite(
      id: 'batu_caves',
      icon: '⛩️',
      name: 'Batu Caves',
      location: 'Selangor · Religious',
      category: 'Religious',
      description: 'Sacred limestone cathedral above Kuala Lumpur',
      difficulty: 'Easy',
    ),
    'george_town': const QuizSite(
      id: 'george_town',
      icon: '🏛️',
      name: 'George Town',
      location: 'Penang · UNESCO',
      category: 'UNESCO',
      description:
      'Historic colonial port city famous for street art and heritage shophouses',
      difficulty: 'Medium',
    ),
    'malacca_city': const QuizSite(
      id: 'malacca_city',
      icon: '🏯',
      name: 'Malacca City',
      location: 'Melaka · UNESCO',
      category: 'UNESCO',
      description:
      'Historic trading port shaped by Portuguese, Dutch, and British rule',
      difficulty: 'Medium',
    ),
    'merdeka_square': const QuizSite(
      id: 'merdeka_square',
      icon: '🏳️',
      name: 'Dataran Merdeka',
      location: 'Kuala Lumpur · National',
      category: 'National',
      description:
      'Historic square where Malaysia\'s independence was declared in 1957',
      difficulty: 'Easy',
    ),
    'masjid_zahir': const QuizSite(
      id: 'masjid_zahir',
      icon: '🕌',
      name: 'Zahir Mosque',
      location: 'Kedah · Religious',
      category: 'Religious',
      description:
      'One of Malaysia\'s oldest and grandest mosques, completed in 1912',
      difficulty: 'Easy',
    ),
    'lenggong_valley': const QuizSite(
      id: 'lenggong_valley',
      icon: '🏺',
      name: 'Lenggong Valley',
      location: 'Perak · UNESCO',
      category: 'UNESCO',
      description:
      'UNESCO-listed archaeological valley where "Perak Man" was discovered',
      difficulty: 'Medium',
    ),
    'crystal_mosque': const QuizSite(
      id: 'crystal_mosque',
      icon: '🕌',
      name: 'Crystal Mosque',
      location: 'Terengganu · Religious',
      category: 'Religious',
      description:
      'A steel-and-glass mosque on an island in the Terengganu River',
      difficulty: 'Easy',
    ),
    'taman_negara': const QuizSite(
      id: 'taman_negara',
      icon: '🌳',
      name: 'Taman Negara',
      location: 'Pahang · Nature',
      category: 'Nature',
      description: 'Widely cited as one of the world\'s oldest rainforests',
      difficulty: 'Medium',
    ),
    'sultan_abu_bakar_mosque': const QuizSite(
      id: 'sultan_abu_bakar_mosque',
      icon: '🕌',
      name: 'Sultan Abu Bakar State Mosque',
      location: 'Johor · Religious',
      category: 'Religious',
      description: 'A Victorian-Moorish mosque overlooking the Johor Strait',
      difficulty: 'Medium',
    ),
  };

  static final Map<String, List<QuizQuestion>> _questions = {
    'batu_caves': const [
      QuizQuestion(
        question: 'How many steps lead up to the Cathedral Cave at Batu Caves?',
        options: ['182 steps', '272 steps', '320 steps', '214 steps'],
        correctIndex: 1,
        explanation:
        'The iconic 272 colourful steps were repainted in 2018 in a rainbow gradient that took 15 days to complete.',
        xpReward: 27,
      ),
      QuizQuestion(
        question:
        'What is the height of the golden Lord Murugan statue at Batu Caves?',
        options: ['28 metres', '35 metres', '43 metres', '55 metres'],
        correctIndex: 2,
        explanation:
        'The 43-metre gold-plated statue of Lord Murugan is the tallest in the world, built with 1,550 cubic metres of concrete.',
        xpReward: 27,
      ),
      QuizQuestion(
        question:
        'Which Hindu festival draws over a million devotees to Batu Caves every year?',
        options: ['Thaipusam', 'Deepavali', 'Vesak Day', 'Ponggal'],
        correctIndex: 0,
        explanation:
        'Thaipusam is the largest annual gathering at Batu Caves, with devotees carrying kavadi up the 272 steps as an act of devotion.',
        xpReward: 26,
      ),
    ],
    'george_town': const [
      QuizQuestion(
        question:
        'In what year were George Town and Malacca jointly inscribed as a UNESCO World Heritage Site?',
        options: ['2000', '2008', '2012', '2015'],
        correctIndex: 1,
        explanation:
        'George Town and Malacca were jointly listed in 2008 as "Melaka and George Town, Historic Cities of the Straits of Malacca."',
        xpReward: 27,
      ),
      QuizQuestion(
        question:
        'George Town is world-famous for which public art form found throughout its streets?',
        options: [
          'Street murals',
          'Neon signage',
          'Sand sculptures',
          'Ice sculptures',
        ],
        correctIndex: 0,
        explanation:
        'Artists like Ernest Zacharevic popularised the interactive street murals that now draw visitors across George Town.',
        xpReward: 27,
      ),
      QuizQuestion(
        question:
        'Which George Town street is historically nicknamed "Harmony Street" for its cluster of temples, mosques, and churches?',
        options: [
          'Lebuh Chulia',
          'Jalan Masjid Kapitan Keling',
          'Lebuh Armenian',
          'Jalan Penang',
        ],
        correctIndex: 1,
        explanation:
        'Jalan Masjid Kapitan Keling (formerly Pitt Street) earned the nickname for the diverse houses of worship along it.',
        xpReward: 26,
      ),
    ],
    'malacca_city': const [
      QuizQuestion(
        question: 'Which European power first colonised Malacca, in 1511?',
        options: ['Portuguese', 'Dutch', 'British', 'Spanish'],
        correctIndex: 0,
        explanation:
        'Malacca fell to Portuguese forces under Afonso de Albuquerque in 1511.',
        xpReward: 27,
      ),
      QuizQuestion(
        question:
        'What is the name of the Portuguese fortress ruins still standing in Malacca today?',
        options: [
          'A Famosa',
          'Fort Cornwallis',
          'Fort Santiago',
          'Fort Margherita',
        ],
        correctIndex: 0,
        explanation:
        'A Famosa was built by the Portuguese in 1511; only the Porta de Santiago gate survives today.',
        xpReward: 27,
      ),
      QuizQuestion(
        question:
        'Which street in Malacca is best known for its antique shops and Peranakan heritage?',
        options: [
          'Jonker Street',
          'Jalan Hang Tuah',
          'Lebuh Chulia',
          'Orchard Road',
        ],
        correctIndex: 0,
        explanation:
        'Jonker Street (Jalan Hang Jebat) is the heart of Malacca\'s Peranakan and antique trading heritage.',
        xpReward: 26,
      ),
    ],
    'merdeka_square': const [
      QuizQuestion(
        question:
        'What historic event took place at Dataran Merdeka at midnight on 31 August 1957?',
        options: [
          'Declaration of Malaysia\'s independence',
          'Coronation of the first King',
          'Opening of the first railway',
          'Signing of a peace treaty',
        ],
        correctIndex: 0,
        explanation:
        'The Union Jack was lowered and the Malayan flag raised for the first time as independence was declared.',
        xpReward: 27,
      ),
      QuizQuestion(
        question:
        'What was Dataran Merdeka historically used for during the colonial era?',
        options: [
          'A cricket field ("the Padang")',
          'A horse racing track',
          'A military parade ground only',
          'A marketplace',
        ],
        correctIndex: 0,
        explanation:
        'It was known as the Selangor Club Padang, used for cricket and other colonial-era sports.',
        xpReward: 27,
      ),
      QuizQuestion(
        question:
        'Dataran Merdeka is home to one of the tallest flagpoles in the world, standing at roughly what height?',
        options: [
          '95 metres',
          '20 metres',
          '50 metres',
          'There is no flagpole',
        ],
        correctIndex: 0,
        explanation:
        'The flagpole at Dataran Merdeka stands around 95 metres tall, among the tallest in the world.',
        xpReward: 26,
      ),
    ],
    'masjid_zahir': const [
      QuizQuestion(
        question: 'In what year was Zahir Mosque completed?',
        options: ['1887', '1912', '1935', '1957'],
        correctIndex: 1,
        explanation:
        'Zahir Mosque was completed in 1912, commissioned by the Sultan of Kedah.',
        xpReward: 30,
      ),
      QuizQuestion(
        question:
        'Zahir Mosque\'s five black domes are said to represent what in Islam?',
        options: [
          'The Five Pillars of Islam',
          'The five daily prayers only',
          'The five founders of Kedah',
          'The five states of Malaysia',
        ],
        correctIndex: 0,
        explanation:
        'The mosque\'s five domes are widely said to symbolise the Five Pillars of Islam.',
        xpReward: 30,
      ),
      QuizQuestion(
        question:
        'Zahir Mosque was built on ground with what earlier significance?',
        options: [
          'The burial site of Kedah warriors who died fighting Siamese forces in 1821',
          'The site of the first Kedah royal palace',
          'A former British army barracks',
          'An ancient Buddhist temple ruin',
        ],
        correctIndex: 0,
        explanation:
        'The mosque stands where Kedah warriors killed defending the state against Siamese invasion in 1821 were laid to rest.',
        xpReward: 30,
      ),
    ],
    'lenggong_valley': const [
      QuizQuestion(
        question:
        'In what year was Lenggong Valley inscribed as a UNESCO World Heritage Site?',
        options: ['2000', '2008', '2012', '2019'],
        correctIndex: 2,
        explanation:
        'Lenggong Valley was inscribed by UNESCO in 2012 for its exceptional prehistoric record.',
        xpReward: 40,
      ),
      QuizQuestion(
        question:
        'The skeleton known as "Perak Man," found in Lenggong Valley, is estimated to be roughly how old?',
        options: ['5,000 years', '8,000 years', '11,000 years', '20,000 years'],
        correctIndex: 2,
        explanation:
        'Perak Man is estimated at around 11,000 years old, one of the most complete prehistoric skeletons found in Southeast Asia.',
        xpReward: 40,
      ),
      QuizQuestion(
        question: 'Perak Man was discovered in what type of site?',
        options: [
          'A limestone cave',
          'A riverbank rice field',
          'A hilltop temple ruin',
          'A coastal shell midden',
        ],
        correctIndex: 0,
        explanation:
        'Perak Man was unearthed in Gua Gunung Runtuh, a limestone cave within the Lenggong Valley.',
        xpReward: 40,
      ),
    ],
    'crystal_mosque': const [
      QuizQuestion(
        question: 'In what year did the Crystal Mosque officially open?',
        options: ['1998', '2003', '2008', '2015'],
        correctIndex: 2,
        explanation:
        'The Crystal Mosque opened in 2008 as part of the Islamic Heritage Park in Kuala Terengganu.',
        xpReward: 30,
      ),
      QuizQuestion(
        question: 'What modern materials give the Crystal Mosque its name?',
        options: [
          'Steel and glass',
          'Marble and gold leaf',
          'Bamboo and thatch',
          'Granite and copper',
        ],
        correctIndex: 0,
        explanation:
        'Its steel-and-glass structure, which catches and reflects light, gives the mosque its "crystal" name.',
        xpReward: 30,
      ),
      QuizQuestion(
        question: 'The Crystal Mosque sits on an island within which river?',
        options: [
          'Terengganu River',
          'Pahang River',
          'Perak River',
          'Kelantan River',
        ],
        correctIndex: 0,
        explanation:
        'The mosque is built on Wan Man Island in the Terengganu River.',
        xpReward: 30,
      ),
    ],
    'taman_negara': const [
      QuizQuestion(
        question:
        'Taman Negara is often cited as one of the world\'s oldest rainforests — roughly how old is it estimated to be?',
        options: [
          '10 million years',
          '50 million years',
          '130 million years',
          '500 million years',
        ],
        correctIndex: 2,
        explanation:
        'Taman Negara\'s rainforest is estimated at around 130 million years old, older than the Amazon.',
        xpReward: 37,
      ),
      QuizQuestion(
        question:
        'Taman Negara is home to a canopy walkway considered among the longest in the world — roughly how long is it?',
        options: [
          'Around 100 metres',
          'Around 250 metres',
          'Over 500 metres',
          'Over 2 kilometres',
        ],
        correctIndex: 2,
        explanation:
        'The canopy walkway near Kuala Tahan stretches over 500 metres, strung high above the forest floor.',
        xpReward: 37,
      ),
      QuizQuestion(
        question:
        'Which village serves as the main gateway for treks into Taman Negara?',
        options: [
          'Kuala Tahan',
          'Kuala Besut',
          'Kuala Kubu Bharu',
          'Kuala Lipis',
        ],
        correctIndex: 0,
        explanation:
        'Kuala Tahan, where the Tahan and Tembeling rivers meet, is the usual starting point for the park.',
        xpReward: 36,
      ),
    ],
    'sultan_abu_bakar_mosque': const [
      QuizQuestion(
        question:
        'Sultan Abu Bakar State Mosque is named after the Johor ruler often called the "Father of Modern Johor" — who was he?',
        options: [
          'Sultan Abu Bakar',
          'Sultan Ibrahim',
          'Sultan Iskandar',
          'Sultan Mahmud Shah',
        ],
        correctIndex: 0,
        explanation:
        'The mosque honours Sultan Abu Bakar, credited with modernising Johor in the late 19th century.',
        xpReward: 30,
      ),
      QuizQuestion(
        question:
        'The mosque overlooks which strait, with views toward Singapore?',
        options: [
          'Johor Strait',
          'Malacca Strait',
          'Penang Strait',
          'Karimata Strait',
        ],
        correctIndex: 0,
        explanation:
        'Perched on a hill in Johor Bahru, the mosque looks out over the Johor Strait.',
        xpReward: 30,
      ),
      QuizQuestion(
        question:
        'The mosque\'s architecture is an unusual blend of Islamic style with which other influence?',
        options: [
          'Victorian British',
          'Japanese',
          'Spanish colonial',
          'Scandinavian',
        ],
        correctIndex: 0,
        explanation:
        'Built between 1892 and 1900, it combines Moorish Islamic elements with Victorian British architectural style.',
        xpReward: 30,
      ),
    ],
  };

  /// Returns site metadata for the quiz intro card, or null if no
  /// quiz exists for that site yet.
  static QuizSite? getSite(String siteId) => _sites[siteId];

  /// Returns the ordered list of quiz questions for a site. Returns
  /// an empty list if no quiz exists for that site yet.
  static List<QuizQuestion> getQuestions(String siteId) =>
      _questions[siteId] ?? const [];

  /// Total possible XP for a site's quiz — used on the intro card.
  static int totalXp(String siteId) =>
      getQuestions(siteId).fold(0, (sum, q) => sum + q.xpReward);
}

// ============================ INTRO SCREEN ============================

/// Shown when the user is near a heritage site with a quiz available.
/// In the full app this is triggered by GPS proximity; for now it's
/// launched directly with a `siteId` so the flow can be demoed
/// without real location data wired up yet.
class QuizIntroScreen extends StatelessWidget {
  final String siteId;
  final QuizCompleteCallback onQuizComplete;
  const QuizIntroScreen({
    super.key,
    required this.siteId,
    required this.onQuizComplete,
  });

  @override
  Widget build(BuildContext context) {
    final site = QuizRepository.getSite(siteId);
    final questions = QuizRepository.getQuestions(siteId);
    final totalXp = QuizRepository.totalXp(siteId);

    if (site == null || questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1130),
        body: Center(
          child: Text(
            'No quiz available for this site yet.',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1130),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B1130), Color(0xFF141B4D), Color(0xFF1B1440)],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF16A34A).withOpacity(0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('📍', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 6),
                            Text(
                              "You're nearby",
                              style: TextStyle(
                                color: Color(0xFF4ADE80),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(site.icon, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 10),
                          Text(
                            site.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        site.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '"${site.description}"',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.75),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEC4899).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '🧠',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${questions.length}-Question Heritage Quiz',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Earn up to +$totalXp XP for correct answers',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              label: 'Questions',
                              value: '${questions.length}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatBox(
                              label: 'XP Reward',
                              value: '+$totalXp',
                              valueColor: const Color(0xFFFBBF24),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatBox(
                              label: 'Difficulty',
                              value: site.difficulty,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => QuizScreen(
                            siteId: siteId,
                            onQuizComplete: onQuizComplete,
                          ),
                        ),
                      );
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF16A34A), Color(0xFF0D9488)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Start Quiz  →',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _StatBox({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================== QUESTION SCREEN ===========================

/// The question-by-question quiz flow for a heritage site. Questions
/// are pulled via [QuizRepository.getQuestions] — this screen is
/// purely presentation + answer-state logic.
class QuizScreen extends StatefulWidget {
  final String siteId;
  final QuizCompleteCallback onQuizComplete;
  const QuizScreen({
    super.key,
    required this.siteId,
    required this.onQuizComplete,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizSite? _site = QuizRepository.getSite(widget.siteId);
  late final List<QuizQuestion> _questions = QuizRepository.getQuestions(
    widget.siteId,
  );

  int _currentIndex = 0;
  int? _selectedIndex;
  bool _answered = false;
  int _xpEarned = 0;
  int _correctCount = 0;

  QuizQuestion get _current => _questions[_currentIndex];
  bool get _isLastQuestion => _currentIndex == _questions.length - 1;

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (index == _current.correctIndex) {
        _xpEarned += _current.xpReward;
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_isLastQuestion) {
      widget.onQuizComplete(
        QuizAttempt(
          siteId: widget.siteId,
          siteName: _site?.name ?? '',
          siteIcon: _site?.icon ?? '📍',
          correctCount: _correctCount,
          totalQuestions: _questions.length,
          xpEarned: _xpEarned,
          completedAt: DateTime.now(),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizCompleteScreen(
            siteName: _site?.name ?? '',
            xpEarned: _xpEarned,
            totalQuestions: _questions.length,
          ),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedIndex = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_site == null || _questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1130),
        body: Center(
          child: Text(
            'Quiz unavailable',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1130),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B1130), Color(0xFF141B4D), Color(0xFF1B1440)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1} of ${_questions.length}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+$_xpEarned XP',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(_questions.length, (i) {
                    final isPast = i < _currentIndex;
                    final isCurrent = i == _currentIndex;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: i == _questions.length - 1 ? 0 : 6,
                        ),
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: (isPast || isCurrent)
                              ? const Color(0xFF34D6C7)
                              : Colors.white.withOpacity(0.12),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(_site.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      _site.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _current.question,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(_current.options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AnswerOption(
                      letter: String.fromCharCode(65 + index),
                      text: _current.options[index],
                      state: _optionState(index),
                      onTap: () => _selectAnswer(index),
                    ),
                  );
                }),
                if (_answered) ...[
                  const SizedBox(height: 4),
                  _ExplanationCard(
                    isCorrect: _selectedIndex == _current.correctIndex,
                    xpReward: _current.xpReward,
                    explanation: _current.explanation,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _nextQuestion,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _isLastQuestion
                                ? 'See Results  →'
                                : 'Next Question  →',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _AnswerState _optionState(int index) {
    if (!_answered) return _AnswerState.idle;
    if (index == _current.correctIndex) return _AnswerState.correct;
    if (index == _selectedIndex) return _AnswerState.incorrect;
    return _AnswerState.dimmed;
  }
}

enum _AnswerState { idle, correct, incorrect, dimmed }

class _AnswerOption extends StatelessWidget {
  final String letter;
  final String text;
  final _AnswerState state;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color background;
    Color border;
    Color textColor = Colors.white;
    Color circleColor = Colors.white.withOpacity(0.1);
    Widget? trailingIcon;

    switch (state) {
      case _AnswerState.idle:
        background = Colors.white.withOpacity(0.05);
        border = Colors.white.withOpacity(0.1);
        break;
      case _AnswerState.correct:
        background = const Color(0xFF16A34A).withOpacity(0.18);
        border = const Color(0xFF16A34A);
        textColor = const Color(0xFF4ADE80);
        circleColor = const Color(0xFF16A34A);
        trailingIcon = const Icon(Icons.check, color: Colors.white, size: 16);
        break;
      case _AnswerState.incorrect:
        background = const Color(0xFFDC2626).withOpacity(0.18);
        border = const Color(0xFFDC2626);
        textColor = const Color(0xFFF87171);
        circleColor = const Color(0xFFDC2626);
        trailingIcon = const Icon(Icons.close, color: Colors.white, size: 16);
        break;
      case _AnswerState.dimmed:
        background = Colors.white.withOpacity(0.03);
        border = Colors.white.withOpacity(0.06);
        textColor = Colors.white.withOpacity(0.35);
        circleColor = Colors.white.withOpacity(0.06);
        break;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child:
              trailingIcon ??
                  Text(
                    letter,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  final bool isCorrect;
  final int xpReward;
  final String explanation;

  const _ExplanationCard({
    required this.isCorrect,
    required this.xpReward,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? '✓ Correct! +$xpReward XP' : '✗ Not quite',
            style: TextStyle(
              color: isCorrect
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFFF87171),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            explanation,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.75),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================== COMPLETE SCREEN ===========================

/// Shown after the last question is answered — summarizes XP earned.
class QuizCompleteScreen extends StatelessWidget {
  final String siteName;
  final int xpEarned;
  final int totalQuestions;

  const QuizCompleteScreen({
    super.key,
    required this.siteName,
    required this.xpEarned,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1130),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B1130), Color(0xFF141B4D), Color(0xFF1B1440)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🏆', style: TextStyle(fontSize: 40)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Quiz Complete!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  siteName,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Text(
                    '+$xpEarned XP earned',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ============================ HISTORY SCREEN ============================

/// Shows every completed quiz attempt with its score and XP earned —
/// reachable via the "History" button on the Map screen.
class QuizHistoryScreen extends StatelessWidget {
  final List<QuizAttempt> attempts;
  const QuizHistoryScreen({super.key, required this.attempts});

  @override
  Widget build(BuildContext context) {
    // Most recent first.
    final sorted = List<QuizAttempt>.from(attempts)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final totalXp = attempts.fold<int>(0, (sum, a) => sum + a.xpEarned);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Quiz History',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: sorted.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📋', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                'No quizzes completed yet',
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F8A5F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quizzes Completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${sorted.length}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total XP Earned',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '+$totalXp',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...sorted.map(
                (attempt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AttemptCard(attempt: attempt),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final QuizAttempt attempt;
  const _AttemptCard({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final scorePercent = attempt.totalQuestions == 0
        ? 0
        : ((attempt.correctCount / attempt.totalQuestions) * 100).round();
    final date = attempt.completedAt;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      padding: const EdgeInsets.all(14),
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
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(attempt.siteIcon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.siteName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateLabel · ${attempt.correctCount}/${attempt.totalQuestions} correct ($scorePercent%)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '+${attempt.xpEarned} XP',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB8720A),
            ),
          ),
        ],
      ),
    );
  }
}