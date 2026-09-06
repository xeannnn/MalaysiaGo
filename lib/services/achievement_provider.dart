// ============================================================
// ACHIEVEMENT PROVIDER
// Manages XP, badges, and achievement state with Hive persistence
// ============================================================

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../data/badge_data.dart';
import '../services/badge_service.dart';
import '../modules/quiz.dart';

class AchievementProvider extends ChangeNotifier {
  // ============================================================
  // STATE
  // ============================================================

  int _totalXp = 0;
  Map<String, List<String>> _visitedSites = {};
  Map<String, bool> _claimedBonuses = {};
  Set<String> _completedQuizIds = {};
  List<QuizAttempt> _quizHistory = [];
  bool _isLoading = true;

  // Hive box reference
  late Box _box;

  // ============================================================
  // GETTERS
  // ============================================================

  int get totalXp => _totalXp;
  Map<String, List<String>> get visitedSites => _visitedSites;
  Map<String, bool> get claimedBonuses => _claimedBonuses;
  Set<String> get completedQuizIds => _completedQuizIds;
  List<QuizAttempt> get quizHistory => _quizHistory;
  bool get isLoading => _isLoading;
  Set<String> get visitedHeritageSiteIds =>
      _visitedSites.values.expand((siteIds) => siteIds).toSet();

  UserAchievement get achievement {
    return BadgeService.getUserAchievement(_totalXp, _visitedSites);
  }

  LevelConfig get level => BadgeService.getCurrentLevel(_totalXp);

  int get xpToNextLevel => BadgeService.getXpToNextLevel(_totalXp);

  List<UserBadgeProgress> get badgeProgress {
    return BadgeService.getAllBadgeProgress(_visitedSites);
  }

  int get completedBadges {
    return badgeProgress.where((p) => p.isComplete).length;
  }

  int get totalBadges => activeStateBadges.length;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Loads locally persisted achievement data.
  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    // Open Hive box
    _box = await Hive.openBox('userProgress');

    bool hasSavedData = await _loadFromHive();

    if (!hasSavedData) {
      // A real user must start with an empty passport and zero XP.
      _loadEmptyData();
      await _saveToHive();
    }

    _isLoading = false;
    notifyListeners();
    debugPrint('✅ AchievementProvider loaded: XP = $_totalXp');
  }

  // ============================================================
  // HIVE PERSISTENCE
  // ============================================================

  /// Saves all user progress to Hive
  Future<void> _saveToHive() async {
    try {
      await _box.put('totalXp', _totalXp);
      await _box.put('visitedSites', _visitedSites);
      await _box.put('claimedBonuses', _claimedBonuses);
      await _box.put('completedQuizIds', _completedQuizIds.toList());
      await _box.put(
        'quizHistory',
        _quizHistory.map((a) => a.toMap()).toList(),
      );
      await _box.put('progressSchemaVersion', 2);
      debugPrint('✅ Progress saved to Hive');
    } catch (e) {
      debugPrint('❌ Error saving to Hive: $e');
    }
  }

  /// Loads user progress from Hive
  /// Returns true if data was loaded, false if no data exists
  Future<bool> _loadFromHive() async {
    try {
      final savedXp = _box.get('totalXp');
      final savedVisited = _box.get('visitedSites');
      final savedBonuses = _box.get('claimedBonuses');
      final savedCompletedQuizIds = _box.get('completedQuizIds');
      final savedQuizHistory = _box.get('quizHistory');

      if (savedXp != null && savedVisited != null && savedBonuses != null) {
        _totalXp = (savedXp as num).toInt();
        _visitedSites = (savedVisited as Map).map(
          (key, value) =>
              MapEntry(key.toString(), List<String>.from(value as Iterable)),
        );
        _claimedBonuses = (savedBonuses as Map).map(
          (key, value) => MapEntry(key.toString(), value == true),
        );

        // These two fields were added after the above three, so older
        // saved data may not have them yet — default to empty rather
        // than fail the whole load.
        if (savedCompletedQuizIds != null) {
          _completedQuizIds = Set<String>.from(savedCompletedQuizIds);
        }
        if (savedQuizHistory != null) {
          _quizHistory = (savedQuizHistory as List)
              .map(
                (m) => QuizAttempt.fromMap(Map<String, dynamic>.from(m as Map)),
              )
              .toList();
        }

        final schemaVersion =
            (_box.get('progressSchemaVersion') as num?)?.toInt() ?? 1;
        if (schemaVersion < 2) {
          _migrateLegacyProgress();
          await _saveToHive();
        }

        debugPrint('✅ Data loaded from Hive: XP = $_totalXp');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error loading from Hive: $e');
      return false;
    }
  }

  // ============================================================
  // DEFAULT DATA (First Launch Only)
  // ============================================================

  void _loadEmptyData() {
    _totalXp = 0;
    _visitedSites = {};
    _claimedBonuses = {};
    _completedQuizIds = {};
    _quizHistory = [];
  }

  void _migrateLegacyProgress() {
    final hasDemoSeed =
        _totalXp == 470 &&
        _completedQuizIds.isEmpty &&
        (_visitedSites['badge_kl']?.contains('site_klcc') ?? false);
    if (hasDemoSeed) {
      _loadEmptyData();
      return;
    }

    const aliases = <String, String>{
      'site_merdeka_square': 'merdeka_square',
      'site_batu_caves': 'batu_caves',
      'site_penang_street_art': 'george_town',
      'site_jonker_street': 'malacca_city',
      'site_kek_lok_si': 'kek_lok_si',
      'site_taman_negara': 'taman_negara',
    };

    _visitedSites = _visitedSites.map(
      (badgeId, siteIds) => MapEntry(
        badgeId,
        siteIds.map((siteId) => aliases[siteId] ?? siteId).toSet().toList(),
      ),
    );
  }

  /// Resets all data (for testing)
  Future<void> reset() async {
    _loadEmptyData();
    notifyListeners();
    await _saveToHive();
  }

  // ============================================================
  // XP OPERATIONS
  // ============================================================

  /// Add XP and save to Hive
  int addXp(int amount) {
    if (amount <= 0) return _totalXp;

    int oldXp = _totalXp;
    int oldLevel = BadgeService.getCurrentLevel(oldXp).level;

    _totalXp += amount;
    notifyListeners();
    _saveToHive(); // ✅ Persist

    int newLevel = BadgeService.getCurrentLevel(_totalXp).level;
    if (newLevel > oldLevel) {
      _onLevelUp(oldLevel, newLevel);
    }

    return _totalXp;
  }

  /// Add XP from visiting a site and save.
  ///
  /// [xp] is optional for backward compatibility. Heritage Explorer should
  /// pass site.xp so the amount shown on the site card matches the amount
  /// actually awarded. Other modules can omit it and use the default
  /// BadgeService calculation.
  int addSiteVisit(String badgeId, String siteId, {int? xp}) {
    if (_visitedSites.containsKey(badgeId) &&
        _visitedSites[badgeId]!.contains(siteId)) {
      return _totalXp;
    }

    if (!_visitedSites.containsKey(badgeId)) {
      _visitedSites[badgeId] = [];
    }

    _visitedSites[badgeId]!.add(siteId);

    final int awardedXp = xp ?? BadgeService.calculateSiteXp(siteId);
    _totalXp += awardedXp;

    notifyListeners();
    _saveToHive();
    return _totalXp;
  }

  /// Records a verified GPS heritage visit.
  ///
  /// The third parameter is optional so existing two-argument calls keep
  /// compiling. Heritage Explorer should pass the site's XP:
  ///
  /// provider.addHeritageVisit(site.id, stateName, site.xp);
  int addHeritageVisit(String siteId, String stateName, [int? xp]) {
    String? badgeIdFromSite;
    for (final badge in activeStateBadges) {
      if (badge.requiredSiteIds.contains(siteId)) {
        badgeIdFromSite = badge.id;
        break;
      }
    }

    final normalizedState = stateName.split('·').first.toLowerCase().trim();

    const badgeByState = <String, String>{
      'kuala lumpur': 'badge_kl',
      'selangor': 'badge_selangor',
      'penang': 'badge_penang',
      'pulau pinang': 'badge_penang',
      'perak': 'badge_perak',
      'kedah': 'badge_kedah',
      'perlis': 'badge_perlis',
      'melaka': 'badge_melaka',
      'malacca': 'badge_melaka',
      'johor': 'badge_johor',
      'negeri sembilan': 'badge_ns',
      'pahang': 'badge_pahang',
      'terengganu': 'badge_tganu',
      'kelantan': 'badge_kelantan',
      'sarawak': 'badge_sarawak',
      'sabah': 'badge_sabah',
      'putrajaya': 'badge_putrajaya',
      'labuan': 'badge_labuan',
    };

    final badgeId =
        badgeIdFromSite ?? badgeByState[normalizedState] ?? 'badge_other';

    return addSiteVisit(badgeId, siteId, xp: xp);
  }

  int addQuizXp(int score, int totalQuestions, {bool perfect = false}) {
    int xp = BadgeService.calculateQuizXp(
      score,
      totalQuestions,
      perfect: perfect,
    );
    return addXp(xp);
  }

  /// Records a completed quiz attempt: marks the site as done (so it
  /// can't be retaken), adds it to history, and awards its XP. Calling
  /// this again for a site that's already completed is a no-op — the
  /// guard lives here (not just in the UI) so the state can't be
  /// double-counted even if a screen somehow calls this twice.
  void addQuizAttempt(QuizAttempt attempt) {
    if (_completedQuizIds.contains(attempt.siteId)) return;

    _completedQuizIds.add(attempt.siteId);
    _quizHistory.add(attempt);

    if (attempt.xpEarned > 0) {
      addXp(attempt.xpEarned); // addXp already notifies + saves
    } else {
      notifyListeners();
      _saveToHive();
    }
  }

  int addJournalXp(int wordCount, {bool hasPhoto = false}) {
    int xp = BadgeService.calculateJournalXp(wordCount, hasPhoto: hasPhoto);
    return addXp(xp);
  }

  int addStreakXp(int streakDays) {
    int xp = BadgeService.calculateStreakXp(streakDays);
    return addXp(xp);
  }

  // ============================================================
  // BADGE BONUS OPERATIONS
  // ============================================================

  int claimBadgeBonus(String badgeId) {
    if (_claimedBonuses.containsKey(badgeId) && _claimedBonuses[badgeId]!) {
      return 0;
    }

    StateBadge? badge = getBadgeById(badgeId);
    if (badge == null) return 0;

    List<String> visited = _visitedSites[badgeId] ?? [];
    if (!badge.isComplete(visited)) {
      return 0;
    }

    _claimedBonuses[badgeId] = true;
    int bonusXp = badge.bonusXp;
    _totalXp += bonusXp;

    notifyListeners();
    _saveToHive(); // ✅ Persist
    return bonusXp;
  }

  bool isBonusClaimed(String badgeId) {
    return _claimedBonuses.containsKey(badgeId) && _claimedBonuses[badgeId]!;
  }

  List<StateBadge> getUnclaimedBonuses() {
    List<StateBadge> unclaimed = [];

    for (StateBadge badge in activeStateBadges) {
      List<String> visited = _visitedSites[badge.id] ?? [];
      if (badge.isComplete(visited)) {
        if (!_claimedBonuses.containsKey(badge.id) ||
            !_claimedBonuses[badge.id]!) {
          unclaimed.add(badge);
        }
      }
    }

    return unclaimed;
  }

  // ============================================================
  // DEBUG / TESTING
  // ============================================================

  void simulateVisit(String badgeId, String siteId) {
    addSiteVisit(badgeId, siteId);
  }

  void simulateBulkVisits(Map<String, List<String>> visits) {
    int totalXpGained = 0;

    visits.forEach((badgeId, siteIds) {
      for (String siteId in siteIds) {
        if (_visitedSites.containsKey(badgeId) &&
            _visitedSites[badgeId]!.contains(siteId)) {
          continue;
        }

        if (!_visitedSites.containsKey(badgeId)) {
          _visitedSites[badgeId] = [];
        }
        _visitedSites[badgeId]!.add(siteId);
        totalXpGained += BadgeService.calculateSiteXp(siteId);
      }
    });

    _totalXp += totalXpGained;

    for (StateBadge badge in activeStateBadges) {
      List<String> visited = _visitedSites[badge.id] ?? [];
      if (badge.isComplete(visited)) {
        if (!_claimedBonuses.containsKey(badge.id) ||
            !_claimedBonuses[badge.id]!) {
          _claimedBonuses[badge.id] = true;
          _totalXp += badge.bonusXp;
        }
      }
    }

    notifyListeners();
    _saveToHive(); // ✅ Persist
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  void _onLevelUp(int oldLevel, int newLevel) {
    debugPrint('🎉 Level Up! $oldLevel → $newLevel');
  }
}
