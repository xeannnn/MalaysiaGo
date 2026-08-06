/// Bottom navigation tabs. Add a new value here, then handle it
/// in the switch inside MainScreen (main.dart).
enum BottomTab { home, map, scan, badges, passport }

extension BottomTabX on BottomTab {
  String get label {
    switch (this) {
      case BottomTab.home:
        return 'Home';
      case BottomTab.map:
        return 'Map';
      case BottomTab.scan:
        return 'Scan';
      case BottomTab.badges:
        return 'Badges';
      case BottomTab.passport:
        return 'Passport';
    }
  }

  String get emoji {
    switch (this) {
      case BottomTab.home:
        return '🏠';
      case BottomTab.map:
        return '🗺️';
      case BottomTab.scan:
        return '📷';
      case BottomTab.badges:
        return '🏅';
      case BottomTab.passport:
        return '📔';
    }
  }
}

class Mission {
  final String icon;
  final String title;
  final String xp;
  final bool done;
  const Mission(this.icon, this.title, this.xp, this.done);
}

class RankEntry {
  final int rank;
  final String avatar;
  final String name;
  final String state;
  final String xp;
  final bool isYou;
  const RankEntry(this.rank, this.avatar, this.name, this.state, this.xp, this.isYou);
}

class GuideChip {
  final String icon;
  final String label;
  const GuideChip(this.icon, this.label);
}

// ============================================================
// ACHIEVEMENT & REWARDS MODELS NANAT
// ============================================================

class StateBadge {
  final String id;
  final String stateName;
  final String badgeIcon;
  final String badgeTheme; // e.g., "Malayan Tiger", "Hornbill"
  final List<String> requiredSiteIds;
  final int totalPieces;
  final String description;

  const StateBadge({
    required this.id,
    required this.stateName,
    required this.badgeIcon,
    required this.badgeTheme,
    required this.requiredSiteIds,
    required this.totalPieces,
    required this.description,
  });

  int getUnlockedPieces(List<String> visitedSiteIds) {
    int count = 0;
    for (String siteId in requiredSiteIds) {
      if (visitedSiteIds.contains(siteId)) {
        count++;
      }
    }
    return count;
  }

  bool isComplete(List<String> visitedSiteIds) {
    return getUnlockedPieces(visitedSiteIds) >= totalPieces;
  }

  double getProgress(List<String> visitedSiteIds) {
    return getUnlockedPieces(visitedSiteIds) / totalPieces;
  }
}

class UserBadgeProgress {
  final String badgeId;
  final String stateName;
  final String badgeIcon;
  final String badgeTheme;
  final int totalPieces;
  final int unlockedPieces;
  final bool isComplete;
  final int xpEarned;

  const UserBadgeProgress({
    required this.badgeId,
    required this.stateName,
    required this.badgeIcon,
    required this.badgeTheme,
    required this.totalPieces,
    required this.unlockedPieces,
    required this.isComplete,
    required this.xpEarned,
  });

  double get progress => totalPieces > 0 ? unlockedPieces / totalPieces : 0.0;
}

class UserAchievement {
  final int totalXp;
  final int level;
  final int xpToNextLevel;
  final int totalBadges;
  final int completedBadges;
  final List<UserBadgeProgress> badgeProgress;

  const UserAchievement({
    required this.totalXp,
    required this.level,
    required this.xpToNextLevel,
    required this.totalBadges,
    required this.completedBadges,
    required this.badgeProgress,
  });

  double get completionRate =>
      totalBadges > 0 ? completedBadges / totalBadges : 0.0;
}