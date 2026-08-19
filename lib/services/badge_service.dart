// ============================================================
// BADGE SERVICE
// Manages XP calculation, level progression, and badge logic
// ============================================================

import '../models.dart';
import '../data/badge_data.dart';  // Import your badge data

class BadgeService {
  // ============================================================
  // BADGE DATA ACCESS
  // ============================================================

  /// Get all state badges (from badge_data.dart)
  static List<StateBadge> getAllBadges() {
    return allStateBadges; // From badge_data.dart
  }

  /// Get a specific badge by ID
  static StateBadge? getBadgeById(String badgeId) {
    try {
      return allStateBadges.firstWhere((b) => b.id == badgeId);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // BADGE PROGRESS
  // ============================================================

  /// Get progress for a specific badge
  static UserBadgeProgress getBadgeProgress(
      StateBadge badge,
      List<String> visitedSites,
      ) {
    int unlocked = badge.getUnlockedPieces(visitedSites);
    bool complete = badge.isComplete(visitedSites);

    return UserBadgeProgress(
      badgeId: badge.id,
      stateName: badge.stateName,
      badgeIcon: badge.badgeIcon,
      badgeTheme: badge.badgeTheme,
      totalPieces: badge.totalPieces,
      unlockedPieces: unlocked,
      isComplete: complete,
      bonusXpEarned: complete ? badge.bonusXp : 0,
      bonusClaimed: false,
    );
  }

  /// Get progress for all badges
  static List<UserBadgeProgress> getAllBadgeProgress(
      Map<String, List<String>> visitedSites,
      ) {
    List<UserBadgeProgress> progress = [];

    for (StateBadge badge in allStateBadges) {
      List<String> visited = visitedSites[badge.id] ?? [];
      progress.add(getBadgeProgress(badge, visited));
    }

    return progress;
  }

  // ============================================================
  // XP CALCULATION
  // ============================================================

  /// Calculate XP from visiting a heritage site
  static int calculateSiteXp(String siteId) {
    return 100; // Base XP for any site visit
  }

  /// Calculate XP from completing a quiz
  static int calculateQuizXp(int score, int totalQuestions, {bool perfect = false}) {
    int baseXp = 25;
    if (perfect) {
      return baseXp + 25; // 50 XP for perfect score
    }
    // Partial XP based on score percentage
    double percentage = score / totalQuestions;
    return (baseXp * percentage).round();
  }

  /// Calculate XP from journal entry
  static int calculateJournalXp(int wordCount, {bool hasPhoto = false}) {
    int xp = 20;
    if (hasPhoto) xp += 10;
    return xp;
  }

  /// Calculate XP from daily streak
  static int calculateStreakXp(int streakDays) {
    return 5 + streakDays.clamp(0, 15);
  }

  // ============================================================
  // LEVEL MANAGEMENT
  // ============================================================

  /// Get current level based on XP
  static LevelConfig getCurrentLevel(int totalXp) {
    return LevelConfig.getLevelByXp(totalXp);
  }

  /// Get next level configuration
  static LevelConfig? getNextLevel(int totalXp) {
    int currentLevel = getCurrentLevel(totalXp).level;
    return LevelConfig.getNextLevel(currentLevel);
  }

  /// Get XP needed to reach next level
  static int getXpToNextLevel(int totalXp) {
    return LevelConfig.getXpToNextLevel(totalXp);
  }

  /// Check if user leveled up
  static bool didLevelUp(int oldXp, int newXp) {
    int oldLevel = getCurrentLevel(oldXp).level;
    int newLevel = getCurrentLevel(newXp).level;
    return newLevel > oldLevel;
  }

  // ============================================================
  // BADGE UNLOCKING
  // ============================================================

  /// Check if a badge is complete and return bonus XP
  static int checkAndAwardBadgeBonus(
      String badgeId,
      List<String> visitedSites,
      ) {
    StateBadge? badge = getBadgeById(badgeId);
    if (badge == null) return 0;

    if (badge.isComplete(visitedSites)) {
      return badge.bonusXp; // Returns 150 by default
    }
    return 0;
  }

  /// Get newly completed badges (was locked, now unlocked)
  static List<StateBadge> getNewlyCompletedBadges(
      Map<String, List<String>> oldVisitedSites,
      Map<String, List<String>> newVisitedSites,
      ) {
    List<StateBadge> newlyCompleted = [];

    for (StateBadge badge in allStateBadges) {
      bool wasComplete = badge.isComplete(oldVisitedSites[badge.id] ?? []);
      bool isCompleteNow = badge.isComplete(newVisitedSites[badge.id] ?? []);

      if (!wasComplete && isCompleteNow) {
        newlyCompleted.add(badge);
      }
    }

    return newlyCompleted;
  }

  // ============================================================
  // COMPLETE USER ACHIEVEMENT
  // ============================================================

  /// Get complete user achievement summary
  static UserAchievement getUserAchievement(
      int totalXp,
      Map<String, List<String>> visitedSites,
      ) {
    List<UserBadgeProgress> progress = getAllBadgeProgress(visitedSites);
    int completedBadges = progress.where((p) => p.isComplete).length;

    // Use LevelConfig for proper level calculation
    LevelConfig currentLevel = getCurrentLevel(totalXp);
    int xpToNext = getXpToNextLevel(totalXp);

    return UserAchievement(
      totalXp: totalXp,
      level: currentLevel.level,
      xpToNextLevel: xpToNext,
      totalBadges: allStateBadges.length,
      completedBadges: completedBadges,
      badgeProgress: progress,
    );
  }
}