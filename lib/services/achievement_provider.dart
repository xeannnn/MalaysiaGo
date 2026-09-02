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
  bool _isLoading = true;

  // Quiz tracking
  Set<String> _completedQuizIds = {};
  List<QuizAttempt> _quizHistory = [];

  // ✅ Track badges that have already been celebrated
  Set<String> _celebratedBadges = {};

  // Hive box reference
  late Box _box;

  // ============================================================
  // GETTERS
  // ============================================================

  int get totalXp => _totalXp;
  Map<String, List<String>> get visitedSites => _visitedSites;
  Map<String, bool> get claimedBonuses => _claimedBonuses;
  bool get isLoading => _isLoading;
  Set<String> get completedQuizIds => _completedQuizIds;
  List<QuizAttempt> get quizHistory => _quizHistory;
  Set<String> get celebratedBadges => _celebratedBadges;

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

  int get totalBadges => allStateBadges.length;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _box = await Hive.openBox('userProgress');
    } catch (e) {
      debugPrint('❌ Hive open error: $e');
      _box = await Hive.openBox('userProgress');
    }

    bool hasSavedData = await _loadFromHive();

    if (!hasSavedData) {
      _loadDummyData();
      await _saveToHive();
    }

    _isLoading = false;
    notifyListeners();
    debugPrint('✅ AchievementProvider loaded: XP = $_totalXp');
  }

  // ============================================================
  // HIVE PERSISTENCE
  // ============================================================

  Future<void> _saveToHive() async {
    try {
      await _box.put('totalXp', _totalXp);
      await _box.put('visitedSites', _visitedSites);
      await _box.put('claimedBonuses', _claimedBonuses);
      await _box.put('completedQuizIds', _completedQuizIds.toList());
      await _box.put('celebratedBadges', _celebratedBadges.toList());
      debugPrint('✅ Progress saved to Hive');
    } catch (e) {
      debugPrint('❌ Error saving to Hive: $e');
    }
  }

  Future<bool> _loadFromHive() async {
    try {
      final savedXp = _box.get('totalXp');
      final savedVisited = _box.get('visitedSites');
      final savedBonuses = _box.get('claimedBonuses');
      final savedQuizIds = _box.get('completedQuizIds');
      final savedCelebrated = _box.get('celebratedBadges');

      if (savedXp != null && savedVisited != null && savedBonuses != null) {
        _totalXp = savedXp;
        _visitedSites = Map<String, List<String>>.from(savedVisited);
        _claimedBonuses = Map<String, bool>.from(savedBonuses);
        if (savedQuizIds != null) {
          _completedQuizIds = Set<String>.from(savedQuizIds);
        }
        if (savedCelebrated != null) {
          _celebratedBadges = Set<String>.from(savedCelebrated);
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
  // DUMMY DATA (First Launch Only)
  // ============================================================

  void _loadDummyData() {
    _totalXp = 470;
    _visitedSites = {
      'badge_kl': [
        'site_klcc',
        'site_pasar_seni',
        'site_perdana_garden',
        'site_merdeka_square',
      ],
      'badge_melaka': [
        'site_afamosa',
        'site_st_paul',
      ],
      'badge_penang': [
        'site_fort_cornwallis',
      ],
      'badge_sarawak': [
        'site_sarawak_museum',
      ],
      'badge_sabah': [
        'site_mt_kinabalu',
      ],
      'badge_perak': [],
    };
    _claimedBonuses = {
      'badge_kl': false,
      'badge_melaka': false,
      'badge_penang': false,
      'badge_sarawak': false,
      'badge_sabah': false,
      'badge_perak': false,
    };
    _celebratedBadges = {};
    _completedQuizIds = {};
    _quizHistory = [];
  }

  void reset() async {
    _totalXp = 0;
    _visitedSites = {};
    _claimedBonuses = {};
    _completedQuizIds = {};
    _quizHistory = [];
    _celebratedBadges = {};
    notifyListeners();
    await _saveToHive();
  }

  // ============================================================
  // XP OPERATIONS
  // ============================================================

  int addXp(int amount) {
    if (amount <= 0) return _totalXp;

    int oldXp = _totalXp;
    int oldLevel = BadgeService.getCurrentLevel(oldXp).level;

    _totalXp += amount;
    notifyListeners();
    _saveToHive();

    int newLevel = BadgeService.getCurrentLevel(_totalXp).level;
    if (newLevel > oldLevel) {
      _onLevelUp(oldLevel, newLevel);
    }

    return _totalXp;
  }

  int addSiteVisit(String badgeId, String siteId) {
    if (_visitedSites.containsKey(badgeId) &&
        _visitedSites[badgeId]!.contains(siteId)) {
      return _totalXp;
    }

    if (!_visitedSites.containsKey(badgeId)) {
      _visitedSites[badgeId] = [];
    }
    _visitedSites[badgeId]!.add(siteId);

    int xp = BadgeService.calculateSiteXp(siteId);
    _totalXp += xp;

    List<StateBadge> newlyCompleted = BadgeService.getNewlyCompletedBadges(
      _visitedSites,
      _visitedSites,
    );

    for (StateBadge badge in newlyCompleted) {
      if (!_claimedBonuses.containsKey(badge.id) ||
          !_claimedBonuses[badge.id]!) {
        _claimedBonuses[badge.id] = false;
        _totalXp += badge.bonusXp;
        _claimedBonuses[badge.id] = true;
      }
    }

    notifyListeners();
    _saveToHive();
    return _totalXp;
  }

  int addQuizXp(int score, int totalQuestions, {bool perfect = false}) {
    int xp = BadgeService.calculateQuizXp(score, totalQuestions, perfect: perfect);
    return addXp(xp);
  }

  void addQuizAttempt(QuizAttempt attempt) {
    if (attempt.siteId.isEmpty) return;
    _completedQuizIds.add(attempt.siteId);
    _quizHistory.add(attempt);
    addXp(attempt.xpEarned);
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
    _saveToHive();
    return bonusXp;
  }

  bool isBonusClaimed(String badgeId) {
    return _claimedBonuses.containsKey(badgeId) && _claimedBonuses[badgeId]!;
  }

  List<StateBadge> getUnclaimedBonuses() {
    List<StateBadge> unclaimed = [];

    for (StateBadge badge in allStateBadges) {
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
  // CELEBRATED BADGES
  // ============================================================

  void markBadgeCelebrated(String badgeId) {
    if (!_celebratedBadges.contains(badgeId)) {
      _celebratedBadges.add(badgeId);
      _saveToHive();
    }
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

    for (StateBadge badge in allStateBadges) {
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
    _saveToHive();
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  void _onLevelUp(int oldLevel, int newLevel) {
    print('🎉 Level Up! $oldLevel → $newLevel');
  }
}
