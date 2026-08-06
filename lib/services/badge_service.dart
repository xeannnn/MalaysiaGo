import 'package:flutter/material.dart';
import '../models.dart';

class BadgeService {
  // In production, these would come from Firestore/Hive
  static final Map<String, List<String>> _userVisitedSites = {};

  /// Get all state badges
  static List<StateBadge> getAllBadges() {
    // Return from your data source
    return []; // Add your badge data here
  }

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
      xpEarned: complete ? 150 : 0,
    );
  }

  /// Check if a badge is complete and award bonus XP
  static int checkAndAwardBadgeBonus(
      String badgeId,
      List<String> visitedSites,
      ) {
    // Find the badge
    StateBadge? badge = getAllBadges().firstWhere(
          (b) => b.id == badgeId,
      orElse: () => throw Exception('Badge not found'),
    );

    if (badge.isComplete(visitedSites)) {
      return 150; // Bonus XP
    }
    return 0;
  }

  /// Get total user progress
  static UserAchievement getUserAchievement(
      int totalXp,
      List<StateBadge> allBadges,
      Map<String, List<String>> visitedSites,
      ) {
    List<UserBadgeProgress> progress = [];

    for (StateBadge badge in allBadges) {
      List<String> visited = visitedSites[badge.id] ?? [];
      progress.add(getBadgeProgress(badge, visited));
    }

    int completed = progress.where((p) => p.isComplete).length;

    // Level calculation
    int level = 1;
    int xpToNext = 100;
    // Add your level logic here

    return UserAchievement(
      totalXp: totalXp,
      level: level,
      xpToNext: xpToNext,
      totalBadges: allBadges.length,
      completedBadges: completed,
      badgeProgress: progress,
    );
  }
}