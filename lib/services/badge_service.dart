// ============================================================
// BADGE SERVICE
// Manages XP calculation, level progression, and badge logic
// ============================================================

import '../models.dart';
import '../data/badge_data.dart';

class BadgeService {
  // ============================================================
  // BADGE DATA ACCESS
  // ============================================================

  static List<StateBadge> getAllBadges() {
    return allStateBadges;
  }

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

  static int calculateSiteXp(String siteId) {
    return 100;
  }

  static int calculateQuizXp(int score, int totalQuestions, {bool perfect = false}) {
    int baseXp = 25;
    if (perfect) {
      return baseXp + 25;
    }
    double percentage = score / totalQuestions;
    return (baseXp * percentage).round();
  }

  static int calculateJournalXp(int wordCount, {bool hasPhoto = false}) {
    int xp = 20;
    if (hasPhoto) xp += 10;
    return xp;
  }

  static int calculateStreakXp(int streakDays) {
    return 5 + streakDays.clamp(0, 15);
  }

  // ============================================================
  // LEVEL MANAGEMENT
  // ============================================================

  static LevelConfig getCurrentLevel(int totalXp) {
    return LevelConfig.getLevelByXp(totalXp);
  }

  static LevelConfig? getNextLevel(int totalXp) {
    int currentLevel = getCurrentLevel(totalXp).level;
    return LevelConfig.getNextLevel(currentLevel);
  }

  static int getXpToNextLevel(int totalXp) {
    return LevelConfig.getXpToNextLevel(totalXp);
  }

  static bool didLevelUp(int oldXp, int newXp) {
    int oldLevel = getCurrentLevel(oldXp).level;
    int newLevel = getCurrentLevel(newXp).level;
    return newLevel > oldLevel;
  }

  // ============================================================
  // BADGE UNLOCKING
  // ============================================================

  static int checkAndAwardBadgeBonus(
      String badgeId,
      List<String> visitedSites,
      ) {
    StateBadge? badge = getBadgeById(badgeId);
    if (badge == null) return 0;

    if (badge.isComplete(visitedSites)) {
      return badge.bonusXp;
    }
    return 0;
  }

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

  static UserAchievement getUserAchievement(
      int totalXp,
      Map<String, List<String>> visitedSites,
      ) {
    List<UserBadgeProgress> progress = getAllBadgeProgress(visitedSites);
    int completedBadges = progress.where((p) => p.isComplete).length;

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