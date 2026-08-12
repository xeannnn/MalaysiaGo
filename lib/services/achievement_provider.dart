// ============================================================
// ACHIEVEMENT PROVIDER
// Manages XP, badges, and achievement state
// ============================================================

import 'package:flutter/material.dart';
import '../models.dart';
import '../data/badge_data.dart';
import '../services/badge_service.dart';

class AchievementProvider extends ChangeNotifier {
  // ============================================================
  // STATE
  // ============================================================

  int _totalXp = 0;
  Map<String, List<String>> _visitedSites = {};
  Map<String, bool> _claimedBonuses = {};

  bool _isLoading = true;

  // ============================================================
  // GETTERS
  // ============================================================

  int get totalXp => _totalXp;
  Map<String, List<String>> get visitedSites => _visitedSites;
  Map<String, bool> get claimedBonuses => _claimedBonuses;
  bool get isLoading => _isLoading;

  /// Get user achievement summary
  UserAchievement get achievement {
    return BadgeService.getUserAchievement(_totalXp, _visitedSites);
  }

  /// Get level config
  LevelConfig get level => BadgeService.getCurrentLevel(_totalXp);

  /// Get XP to next level
  int get xpToNextLevel => BadgeService.getXpToNextLevel(_totalXp);

  /// Get user badge progress
  List<UserBadgeProgress> get badgeProgress {
    return BadgeService.getAllBadgeProgress(_visitedSites);
  }

  /// Get completed badge count
  int get completedBadges {
    return badgeProgress.where((p) => p.isComplete).length;
  }

  /// Get total badge count
  int get totalBadges => allStateBadges.length;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Load user data
  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    // Load dummy data for testing with mixed progress
    _loadDummyData();
    _isLoading = false;
    notifyListeners();
  }

  /// ============================================================
  /// DUMMY DATA WITH MIXED PROGRESS:
  /// - 25% completed badge (1 of 4 sites)
  /// - 50% completed badge (2 of 4 sites)
  /// - 100% completed badge (all 4 sites)
  /// ============================================================

  void _loadDummyData() {
    _totalXp = 320;

    // ============================================================
    // BADGE PROGRESS MIX
    // ============================================================
    //
    // ┌─────────────────────────────────────────────────────────────┐
    // │ BADGE              │ PROGRESS │ STATUS                    │
    // ├────────────────────┼──────────┼───────────────────────────┤
    // │ Kuala Lumpur       │ 4/4      │ ✅ 100% COMPLETE          │
    // │ Melaka             │ 2/4      │ 🔵 50% (Halfway there!)   │
    // │ Penang             │ 1/5      │ 🟢 20%                    │
    // │ Sarawak            │ 1/3      │ 🟡 33%                    │
    // │ Sabah              │ 1/3      │ 🟡 33%                    │
    // │ Perak              │ 0/3      │ 🔒 0% (Locked)            │
    // └────────────────────┴──────────┴───────────────────────────┘
    // ============================================================

    _visitedSites = {
      // ✅ 100% COMPLETE - Kuala Lumpur (4/4 sites)
      'badge_kl': [
        'site_klcc',
        'site_pasar_seni',
        'site_perdana_garden',
        'site_merdeka_square',
      ],

      // 🔵 50% COMPLETE - Melaka (2/4 sites)
      'badge_melaka': [
        'site_afamosa',
        'site_st_paul',
        // Missing: 'site_jonker_street', 'site_melaka_sultanate'
      ],

      // 🟢 20% COMPLETE - Penang (1/5 sites)
      'badge_penang': [
        'site_fort_cornwallis',
        // Missing: 'site_penang_street_art', 'site_khoo_kongsi',
        //          'site_kek_lok_si', 'site_pinang_peranakan'
      ],

      // 🟡 33% COMPLETE - Sarawak (1/3 sites)
      'badge_sarawak': [
        'site_sarawak_museum',
        // Missing: 'site_kuching_waterfront', 'site_semenggoh'
      ],

      // 🟡 33% COMPLETE - Sabah (1/3 sites)
      'badge_sabah': [
        'site_mt_kinabalu',
        // Missing: 'site_miso_walai', 'site_sepilok'
      ],

      // 🔒 0% COMPLETE - Perak (0/3 sites)
      'badge_perak': [
        // No sites visited yet
      ],
    };

    // Bonus claiming status
    _claimedBonuses = {
      'badge_kl': false, // Complete but bonus not claimed yet
      'badge_melaka': false,
      'badge_penang': false,
      'badge_sarawak': false,
      'badge_sabah': false,
      'badge_perak': false,
    };

    // Auto-add bonus XP for completed badges (KL is complete)
    // This happens automatically when sites are added, but for dummy data we add it manually
    // KL badge: 4/4 complete → +150 XP bonus
    _totalXp = 320 + 150; // 470 XP
  }

  /// Reset all data (for testing)
  void reset() {
    _totalXp = 0;
    _visitedSites = {};
    _claimedBonuses = {};
    notifyListeners();
  }

  // ============================================================
  // XP OPERATIONS
  // ============================================================

  /// Add XP to the user
  int addXp(int amount) {
    if (amount <= 0) return _totalXp;

    int oldXp = _totalXp;
    int oldLevel = BadgeService.getCurrentLevel(oldXp).level;

    _totalXp += amount;
    notifyListeners();

    // Check for level up
    int newLevel = BadgeService.getCurrentLevel(_totalXp).level;
    if (newLevel > oldLevel) {
      _onLevelUp(oldLevel, newLevel);
    }

    return _totalXp;
  }

  /// Add XP from visiting a site
  int addSiteVisit(String badgeId, String siteId) {
    // Check if site already visited
    if (_visitedSites.containsKey(badgeId) &&
        _visitedSites[badgeId]!.contains(siteId)) {
      return _totalXp;
    }

    // Add site to visited list
    if (!_visitedSites.containsKey(badgeId)) {
      _visitedSites[badgeId] = [];
    }
    _visitedSites[badgeId]!.add(siteId);

    // Calculate XP
    int xp = BadgeService.calculateSiteXp(siteId);
    _totalXp += xp;

    // Check if any badges were completed
    List<StateBadge> newlyCompleted = BadgeService.getNewlyCompletedBadges(
      _visitedSites,
      _visitedSites,
    );

    // For each newly completed badge, auto-add bonus XP
    for (StateBadge badge in newlyCompleted) {
      if (!_claimedBonuses.containsKey(badge.id) ||
          !_claimedBonuses[badge.id]!) {
        _claimedBonuses[badge.id] = false; // Not claimed yet
        _totalXp += badge.bonusXp;
        _claimedBonuses[badge.id] = true;
      }
    }

    notifyListeners();
    return _totalXp;
  }

  /// Add XP from completing a quiz
  int addQuizXp(int score, int totalQuestions, {bool perfect = false}) {
    int xp = BadgeService.calculateQuizXp(score, totalQuestions, perfect: perfect);
    return addXp(xp);
  }

  /// Add XP from journal entry
  int addJournalXp(int wordCount, {bool hasPhoto = false}) {
    int xp = BadgeService.calculateJournalXp(wordCount, hasPhoto: hasPhoto);
    return addXp(xp);
  }

  /// Add XP from daily streak
  int addStreakXp(int streakDays) {
    int xp = BadgeService.calculateStreakXp(streakDays);
    return addXp(xp);
  }

  // ============================================================
  // BADGE BONUS OPERATIONS
  // ============================================================

  /// Claim bonus XP for a completed badge
  int claimBadgeBonus(String badgeId) {
    // Check if already claimed
    if (_claimedBonuses.containsKey(badgeId) && _claimedBonuses[badgeId]!) {
      return 0;
    }

    StateBadge? badge = getBadgeById(badgeId);
    if (badge == null) return 0;

    List<String> visited = _visitedSites[badgeId] ?? [];
    if (!badge.isComplete(visited)) {
      return 0;
    }

    // Mark bonus as claimed
    _claimedBonuses[badgeId] = true;

    // Add bonus XP
    int bonusXp = badge.bonusXp;
    _totalXp += bonusXp;

    notifyListeners();
    return bonusXp;
  }

  /// Check if badge bonus has been claimed
  bool isBonusClaimed(String badgeId) {
    return _claimedBonuses.containsKey(badgeId) && _claimedBonuses[badgeId]!;
  }

  /// Get unclaimed bonuses
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
  // DEBUG / TESTING
  // ============================================================

  /// Simulate a visit (for testing without GPS)
  void simulateVisit(String badgeId, String siteId) {
    addSiteVisit(badgeId, siteId);
  }

  /// Simulate multiple visits (for testing)
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

    // Check for newly completed badges
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
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  void _onLevelUp(int oldLevel, int newLevel) {
    print('🎉 Level Up! $oldLevel → $newLevel');
  }
}