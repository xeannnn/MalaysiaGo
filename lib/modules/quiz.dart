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
        question: 'What is the height of the golden Lord Murugan statue at Batu Caves?',
        options: ['28 metres', '35 metres', '43 metres', '55 metres'],
        correctIndex: 2,
        explanation:
        'The 43-metre gold-plated statue of Lord Murugan is the tallest in the world, built with 1,550 cubic metres of concrete.',
        xpReward: 27,
      ),
      QuizQuestion(
        question: 'Which Hindu festival draws over a million devotees to Batu Caves every year?',
        options: ['Thaipusam', 'Deepavali', 'Vesak Day', 'Ponggal'],
        correctIndex: 0,
        explanation:
        'Thaipusam is the largest annual gathering at Batu Caves, with devotees carrying kavadi up the 272 steps as an act of devotion.',
        xpReward: 26,
      ),
    ],
  };

  /// Returns site metadata for the quiz intro card, or null if no
  /// quiz exists for that site yet.
  static QuizSite? getSite(String siteId) => _sites[siteId];

  /// Returns the ordered list of quiz questions for a site. Returns
  /// an empty list if no quiz exists for that site yet.
  static List<QuizQuestion> getQuestions(String siteId) => _questions[siteId] ?? const [];

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
  final ValueChanged<int> onXpEarned;
  const QuizIntroScreen({super.key, required this.siteId, required this.onXpEarned});

  @override
  Widget build(BuildContext context) {
    final site = QuizRepository.getSite(siteId);
    final questions = QuizRepository.getQuestions(siteId);
    final totalXp = QuizRepository.totalXp(siteId);

    if (site == null || questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1130),
        body: Center(
          child: Text('No quiz available for this site yet.',
              style: TextStyle(color: Colors.white.withOpacity(0.7))),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('📍', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 6),
                            Text("You're nearby",
                                style: TextStyle(
                                    color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(site.icon, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 10),
                          Text(site.name,
                              style: const TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(site.location,
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.55))),
                      const SizedBox(height: 14),
                      Text('"${site.description}"',
                          style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withOpacity(0.75),
                              height: 1.4)),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                              child: const Text('🧠', style: TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${questions.length}-Question Heritage Quiz',
                                      style: const TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text('Earn up to +$totalXp XP for correct answers',
                                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
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
                              child: _StatBox(label: 'Questions', value: '${questions.length}')),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _StatBox(
                                  label: 'XP Reward', value: '+$totalXp', valueColor: const Color(0xFFFBBF24))),
                          const SizedBox(width: 10),
                          Expanded(child: _StatBox(label: 'Difficulty', value: site.difficulty)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => QuizScreen(siteId: siteId, onXpEarned: onXpEarned),
                        ),
                      );
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF0D9488)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('Start Quiz  →',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
  const _StatBox({required this.label, required this.value, this.valueColor = Colors.white});

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
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor)),
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
  final ValueChanged<int> onXpEarned;
  const QuizScreen({super.key, required this.siteId, required this.onXpEarned});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizSite? _site = QuizRepository.getSite(widget.siteId);
  late final List<QuizQuestion> _questions = QuizRepository.getQuestions(widget.siteId);

  int _currentIndex = 0;
  int? _selectedIndex;
  bool _answered = false;
  int _xpEarned = 0;

  QuizQuestion get _current => _questions[_currentIndex];
  bool get _isLastQuestion => _currentIndex == _questions.length - 1;

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (index == _current.correctIndex) {
        _xpEarned += _current.xpReward;
      }
    });
  }

  void _nextQuestion() {
    if (_isLastQuestion) {
      widget.onXpEarned(_xpEarned);
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
        body: Center(child: Text('Quiz unavailable', style: TextStyle(color: Colors.white))),
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
                    Text('Question ${_currentIndex + 1} of ${_questions.length}',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('+$_xpEarned XP',
                          style: const TextStyle(
                              color: Color(0xFFFBBF24), fontSize: 12, fontWeight: FontWeight.bold)),
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
                        margin: EdgeInsets.only(right: i == _questions.length - 1 ? 0 : 6),
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
                    Text(_site.name,
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_current.question,
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _nextQuestion,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(_isLastQuestion ? 'See Results  →' : 'Next Question  →',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
              decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: trailingIcon ??
                  Text(letter,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w500)),
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

  const _ExplanationCard({required this.isCorrect, required this.xpReward, required this.explanation});

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
                color: isCorrect ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(explanation, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75), height: 1.4)),
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
                const Text('Quiz Complete!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(siteName, style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.6))),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Text('+$xpEarned XP earned',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24))),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('Back to Home',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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