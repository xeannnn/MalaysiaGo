import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ================================================================
// MODELS
// ================================================================

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

  factory QuizQuestion.fromSupabase(Map<String, dynamic> data) {
    final rawOptions = data['options'];

    return QuizQuestion(
      question: data['question']?.toString() ?? '',
      options: rawOptions is List
          ? rawOptions.map((option) => option.toString()).toList()
          : const <String>[],
      correctIndex: (data['correct_index'] as num?)?.toInt() ?? 0,
      explanation: data['explanation']?.toString() ?? '',
      xpReward: (data['xp_reward'] as num?)?.toInt() ?? 0,
    );
  }

  QuizQuestion withShuffledOptions(Random random) {
    if (options.isEmpty || correctIndex < 0 || correctIndex >= options.length) {
      return this;
    }

    final correctAnswer = options[correctIndex];
    final shuffledOptions = List<String>.from(options)..shuffle(random);

    return QuizQuestion(
      question: question,
      options: shuffledOptions,
      correctIndex: shuffledOptions.indexOf(correctAnswer),
      explanation: explanation,
      xpReward: xpReward,
    );
  }
}

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

  factory QuizSite.fromSupabase(Map<String, dynamic> data) {
    return QuizSite(
      id: data['site_id']?.toString() ?? '',
      icon: data['icon']?.toString() ?? '📍',
      name: data['name']?.toString() ?? 'Heritage Site',
      location: data['location']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      difficulty: data['difficulty']?.toString() ?? 'Easy',
    );
  }
}

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

  Map<String, dynamic> toMap() {
    return {
      'siteId': siteId,
      'siteName': siteName,
      'siteIcon': siteIcon,
      'correctCount': correctCount,
      'totalQuestions': totalQuestions,
      'xpEarned': xpEarned,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory QuizAttempt.fromMap(Map<dynamic, dynamic> map) {
    return QuizAttempt(
      siteId: map['siteId']?.toString() ?? '',
      siteName: map['siteName']?.toString() ?? '',
      siteIcon: map['siteIcon']?.toString() ?? '📍',
      correctCount: (map['correctCount'] as num?)?.toInt() ?? 0,
      totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 0,
      xpEarned: (map['xpEarned'] as num?)?.toInt() ?? 0,
      completedAt:
          DateTime.tryParse(map['completedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

typedef QuizCompleteCallback = void Function(QuizAttempt attempt);

class QuizBundle {
  final QuizSite site;
  final List<QuizQuestion> questions;

  const QuizBundle({required this.site, required this.questions});
}

// ================================================================
// SUPABASE QUIZ REPOSITORY
// ================================================================

class QuizRepository {
  QuizRepository._();

  static final Random _random = Random();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<QuizBundle?> loadQuiz(String siteId, {int count = 5}) async {
    try {
      /*
       * Your existing quiz_sites table uses site_id as its primary
       * key and does not contain an is_active column.
       */
      final siteData = await _client
          .from('quiz_sites')
          .select()
          .eq('site_id', siteId)
          .maybeSingle();

      if (siteData == null) {
        debugPrint('No quiz site found in Supabase for $siteId.');
        return null;
      }

      /*
       * Your existing quiz_questions table uses display_order and
       * contains the is_active column.
       */
      final questionData = await _client
          .from('quiz_questions')
          .select()
          .eq('site_id', siteId)
          .eq('is_active', true)
          .order('display_order');

      if (questionData.isEmpty) {
        debugPrint('No active questions found for $siteId.');
        return null;
      }

      final site = QuizSite.fromSupabase(Map<String, dynamic>.from(siteData));

      final questionPool = questionData
          .map(
            (row) => QuizQuestion.fromSupabase(Map<String, dynamic>.from(row)),
          )
          .where(
            (question) =>
                question.question.isNotEmpty &&
                question.options.length >= 2 &&
                question.correctIndex >= 0 &&
                question.correctIndex < question.options.length,
          )
          .toList();

      if (questionPool.isEmpty) {
        return null;
      }

      /*
       * Randomize the pool, select up to five questions, then
       * separately randomize each question's answer choices.
       */
      questionPool.shuffle(_random);

      final selectedQuestions = questionPool
          .take(count)
          .map((question) => question.withShuffledOptions(_random))
          .toList();

      return QuizBundle(site: site, questions: selectedQuestions);
    } catch (error, stackTrace) {
      debugPrint('Failed to load quiz for $siteId: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}

// ================================================================
// QUIZ INTRO SCREEN
// ================================================================

class QuizIntroScreen extends StatefulWidget {
  final String siteId;
  final QuizCompleteCallback onQuizComplete;

  const QuizIntroScreen({
    super.key,
    required this.siteId,
    required this.onQuizComplete,
  });

  @override
  State<QuizIntroScreen> createState() => _QuizIntroScreenState();
}

class _QuizIntroScreenState extends State<QuizIntroScreen> {
  late Future<QuizBundle?> _quizFuture;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  void _loadQuiz() {
    _quizFuture = QuizRepository.loadQuiz(widget.siteId, count: 5);
  }

  void _retry() {
    setState(_loadQuiz);
  }

  void _startQuiz(QuizBundle bundle) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          site: bundle.site,
          questions: bundle.questions,
          onQuizComplete: widget.onQuizComplete,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1130),
      appBar: AppBar(
        title: const Text('Heritage Quiz'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<QuizBundle?>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
            );
          }

          final bundle = snapshot.data;

          if (bundle == null) {
            return _QuizUnavailable(onRetry: _retry);
          }

          final site = bundle.site;
          final questions = bundle.questions;

          final totalPossibleXp = questions.fold<int>(
            0,
            (total, question) => total + question.xpReward,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    '📍 You are nearby',
                    style: TextStyle(
                      color: Color(0xFF4ADE80),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(site.icon, style: const TextStyle(fontSize: 72)),
                const SizedBox(height: 14),
                Text(
                  site.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  site.location,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 15),
                ),
                const SizedBox(height: 18),
                Text(
                  site.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      _IntroInformationRow(
                        icon: Icons.quiz,
                        label: 'Questions',
                        value: '${questions.length}',
                      ),
                      const Divider(color: Colors.white12, height: 28),
                      _IntroInformationRow(
                        icon: Icons.bolt,
                        label: 'Possible XP',
                        value: '$totalPossibleXp XP',
                      ),
                      const Divider(color: Colors.white12, height: 28),
                      _IntroInformationRow(
                        icon: Icons.speed,
                        label: 'Difficulty',
                        value: site.difficulty,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _startQuiz(bundle),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Start Quiz',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _IntroInformationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _IntroInformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4ADE80)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _QuizUnavailable extends StatelessWidget {
  final VoidCallback onRetry;

  const _QuizUnavailable({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.white54),
            const SizedBox(height: 20),
            const Text(
              'Quiz unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'The quiz could not be loaded. Check your internet connection and make sure the site and questions exist in Supabase.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// QUESTION SCREEN
// ================================================================

class QuizScreen extends StatefulWidget {
  final QuizSite site;
  final List<QuizQuestion> questions;
  final QuizCompleteCallback onQuizComplete;

  const QuizScreen({
    super.key,
    required this.site,
    required this.questions,
    required this.onQuizComplete,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _correctCount = 0;
  int _xpEarned = 0;

  int? _selectedAnswerIndex;
  bool _answered = false;

  QuizQuestion get _currentQuestion => widget.questions[_currentQuestionIndex];

  bool get _isLastQuestion =>
      _currentQuestionIndex == widget.questions.length - 1;

  void _selectAnswer(int index) {
    if (_answered) {
      return;
    }

    final isCorrect = index == _currentQuestion.correctIndex;

    setState(() {
      _selectedAnswerIndex = index;
      _answered = true;

      if (isCorrect) {
        _correctCount++;
        _xpEarned += _currentQuestion.xpReward;
      }
    });
  }

  void _continueQuiz() {
    if (!_answered) {
      return;
    }

    if (_isLastQuestion) {
      _finishQuiz();
      return;
    }

    setState(() {
      _currentQuestionIndex++;
      _selectedAnswerIndex = null;
      _answered = false;
    });
  }

  void _finishQuiz() {
    final attempt = QuizAttempt(
      siteId: widget.site.id,
      siteName: widget.site.name,
      siteIcon: widget.site.icon,
      correctCount: _correctCount,
      totalQuestions: widget.questions.length,
      xpEarned: _xpEarned,
      completedAt: DateTime.now(),
    );

    widget.onQuizComplete(attempt);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => QuizResultScreen(attempt: attempt)),
    );
  }

  Color _optionBackground(int index) {
    if (!_answered) {
      return Colors.white;
    }

    if (index == _currentQuestion.correctIndex) {
      return const Color(0xFFE8F8EE);
    }

    if (index == _selectedAnswerIndex) {
      return const Color(0xFFFDE8E8);
    }

    return Colors.white;
  }

  Color _optionBorder(int index) {
    if (!_answered) {
      return const Color(0xFFE5E7EB);
    }

    if (index == _currentQuestion.correctIndex) {
      return const Color(0xFF16A34A);
    }

    if (index == _selectedAnswerIndex) {
      return const Color(0xFFDC2626);
    }

    return const Color(0xFFE5E7EB);
  }

  IconData? _optionIcon(int index) {
    if (!_answered) {
      return null;
    }

    if (index == _currentQuestion.correctIndex) {
      return Icons.check_circle;
    }

    if (index == _selectedAnswerIndex) {
      return Icons.cancel;
    }

    return null;
  }

  Color _optionIconColor(int index) {
    if (index == _currentQuestion.correctIndex) {
      return const Color(0xFF16A34A);
    }

    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final question = _currentQuestion;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(widget.site.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / widget.questions.length,
              minHeight: 7,
              backgroundColor: const Color(0xFFE5E7EB),
              color: const Color(0xFF16A34A),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Question '
                          '${_currentQuestionIndex + 1} '
                          'of ${widget.questions.length}',
                          style: const TextStyle(
                            color: Color(0xFF0F8A5F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$_xpEarned XP',
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 26),
                    ...List.generate(question.options.length, (index) {
                      final icon = _optionIcon(index);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _selectAnswer(index),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _optionBackground(index),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _optionBorder(index),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFEEF2F7),
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    question.options[index],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (icon != null)
                                  Icon(icon, color: _optionIconColor(index)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_answered) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F9EF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedAnswerIndex == question.correctIndex
                                  ? 'Correct!'
                                  : 'Correct answer: '
                                        '${question.options[question.correctIndex]}',
                              style: const TextStyle(
                                color: Color(0xFF166534),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.explanation,
                              style: const TextStyle(
                                color: Color(0xFF166534),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _answered ? _continueQuiz : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isLastQuestion ? 'Finish Quiz' : 'Next Question',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

// ================================================================
// RESULT SCREEN
// ================================================================

class QuizResultScreen extends StatelessWidget {
  final QuizAttempt attempt;

  const QuizResultScreen({super.key, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final percentage = attempt.totalQuestions == 0
        ? 0
        : ((attempt.correctCount / attempt.totalQuestions) * 100).round();

    String message;

    if (percentage == 100) {
      message = 'Perfect score!';
    } else if (percentage >= 80) {
      message = 'Excellent work!';
    } else if (percentage >= 60) {
      message = 'Great effort!';
    } else {
      message = 'Keep exploring!';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1130),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Text(attempt.siteIcon, style: const TextStyle(fontSize: 80)),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  attempt.siteName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 17),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${attempt.correctCount}/'
                        '${attempt.totalQuestions}',
                        style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Correct answers',
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '+${attempt.xpEarned} XP',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.map),
                    label: const Text(
                      'Return to Map',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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

// ================================================================
// QUIZ HISTORY SCREEN
// ================================================================

class QuizHistoryScreen extends StatelessWidget {
  final List<QuizAttempt> attempts;

  const QuizHistoryScreen({super.key, required this.attempts});

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  int _percentage(QuizAttempt attempt) {
    if (attempt.totalQuestions == 0) {
      return 0;
    }

    return ((attempt.correctCount / attempt.totalQuestions) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final sortedAttempts = List<QuizAttempt>.from(
      attempts,
    )..sort((first, second) => second.completedAt.compareTo(first.completedAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz History')),
      backgroundColor: const Color(0xFFF5F5F7),
      body: sortedAttempts.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz_outlined, size: 64, color: Colors.black38),
                    SizedBox(height: 16),
                    Text(
                      'No quizzes completed yet.',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: sortedAttempts.length,
              itemBuilder: (context, index) {
                final attempt = sortedAttempts[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE9F9EF),
                        child: Text(attempt.siteIcon),
                      ),
                      title: Text(
                        attempt.siteName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${_formatDate(attempt.completedAt)}\n'
                        '${attempt.correctCount}/'
                        '${attempt.totalQuestions} correct '
                        '(${_percentage(attempt)}%)',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        '+${attempt.xpEarned} XP',
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
