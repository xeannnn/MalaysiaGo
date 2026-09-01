/// Bottom navigation tabs. Add a new value here, then handle it
/// in the switch inside MainScreen (main.dart).
enum BottomTab {
  home,
  map,
  scan,
  community,
  badges,
  passport,
}

extension BottomTabX on BottomTab {
  String get label {
    switch (this) {
      case BottomTab.home:
        return 'Home';
      case BottomTab.map:
        return 'Map';
      case BottomTab.scan:
        return 'Check In';
      case BottomTab.community:
        return 'Community';
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
        return '📍';
      case BottomTab.community:
        return '💬';
      case BottomTab.badges:
        return '🏅';
      case BottomTab.passport:
        return '📔';
    }
  }
}

// ============================================================
// HOME MODELS
// ============================================================

class Mission {
  final String icon;
  final String title;
  final String xp;
  final bool done;

  const Mission(
      this.icon,
      this.title,
      this.xp,
      this.done,
      );
}

class RankEntry {
  final int rank;
  final String avatar;
  final String name;
  final String state;
  final String xp;
  final bool isYou;

  const RankEntry(
      this.rank,
      this.avatar,
      this.name,
      this.state,
      this.xp,
      this.isYou,
      );
}

class GuideChip {
  final String icon;
  final String label;

  const GuideChip(
      this.icon,
      this.label,
      );
}

// ============================================================
// HERITAGE SITE MODEL
// ============================================================

class HeritageSite {
  final String id;
  final String name;
  final String location;
  final String description;
  final String category;

  final double latitude;
  final double longitude;

  final String imageUrl;

  final List<String> tags;
  final String duration;
  final int xp;

  final bool visited;
  final bool isEditorPick;

  HeritageSite({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.tags,
    required this.duration,
    required this.xp,
    required this.visited,
    required this.isEditorPick,
  });

  factory HeritageSite.fromJson(
      Map<String, dynamic> json,
      ) {
    return HeritageSite(
      id: json['id']?.toString() ?? '',
      name:
      json['name']?.toString() ??
          'Unknown Heritage',
      location:
      json['state']?.toString() ??
          json['location']?.toString() ??
          'Malaysia',
      description:
      json['description']?.toString() ?? '',
      category:
      json['category']?.toString() ??
          'National',
      latitude:
      (json['latitude'] as num?)
          ?.toDouble() ??
          0.0,
      longitude:
      (json['longitude'] as num?)
          ?.toDouble() ??
          0.0,
      imageUrl:
      json['imageUrl']?.toString() ?? '',
      tags: List<String>.from(
        json['tags'] ?? const [],
      ),
      duration:
      json['duration']?.toString() ??
          '1–2 hours',
      xp: (json['xp'] as num?)?.toInt() ?? 50,
      visited:
      json['visited'] as bool? ?? false,
      isEditorPick:
      json['isEditorPick'] as bool? ??
          false,
    );
  }
}

// ============================================================
// ACHIEVEMENT & REWARDS MODELS
// ============================================================

/// Represents a state-themed badge with pieces that unlock gradually.
class StateBadge {
  final String id;
  final String stateName;
  final String badgeIcon;
  final String badgeTheme;
  final List<String> requiredSiteIds;
  final int totalPieces;
  final String description;
  final int bonusXp;

  const StateBadge({
    required this.id,
    required this.stateName,
    required this.badgeIcon,
    required this.badgeTheme,
    required this.requiredSiteIds,
    required this.totalPieces,
    required this.description,
    this.bonusXp = 150,
  });

  int getUnlockedPieces(
      List<String> visitedSiteIds,
      ) {
    int count = 0;

    for (final String siteId
    in requiredSiteIds) {
      if (visitedSiteIds.contains(siteId)) {
        count++;
      }
    }

    return count;
  }

  bool isComplete(
      List<String> visitedSiteIds,
      ) {
    return getUnlockedPieces(
      visitedSiteIds,
    ) >=
        totalPieces;
  }

  double getProgress(
      List<String> visitedSiteIds,
      ) {
    if (totalPieces <= 0) {
      return 0.0;
    }

    return getUnlockedPieces(
      visitedSiteIds,
    ) /
        totalPieces;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stateName': stateName,
      'badgeIcon': badgeIcon,
      'badgeTheme': badgeTheme,
      'requiredSiteIds': requiredSiteIds,
      'totalPieces': totalPieces,
      'description': description,
      'bonusXp': bonusXp,
    };
  }

  factory StateBadge.fromMap(
      Map<String, dynamic> map,
      ) {
    return StateBadge(
      id: map['id']?.toString() ?? '',
      stateName:
      map['stateName']?.toString() ?? '',
      badgeIcon:
      map['badgeIcon']?.toString() ?? '',
      badgeTheme:
      map['badgeTheme']?.toString() ?? '',
      requiredSiteIds:
      List<String>.from(
        map['requiredSiteIds'] ?? const [],
      ),
      totalPieces:
      (map['totalPieces'] as num?)
          ?.toInt() ??
          0,
      description:
      map['description']?.toString() ??
          '',
      bonusXp:
      (map['bonusXp'] as num?)
          ?.toInt() ??
          150,
    );
  }
}

/// Represents a user's progress for a specific badge.
class UserBadgeProgress {
  final String badgeId;
  final String stateName;
  final String badgeIcon;
  final String badgeTheme;
  final int totalPieces;
  final int unlockedPieces;
  final bool isComplete;
  final int bonusXpEarned;
  final bool bonusClaimed;

  const UserBadgeProgress({
    required this.badgeId,
    required this.stateName,
    required this.badgeIcon,
    required this.badgeTheme,
    required this.totalPieces,
    required this.unlockedPieces,
    required this.isComplete,
    required this.bonusXpEarned,
    this.bonusClaimed = false,
  });

  double get progress {
    if (totalPieces <= 0) {
      return 0.0;
    }

    return unlockedPieces / totalPieces;
  }

  int get remainingPieces =>
      totalPieces - unlockedPieces;
}

/// Represents a user's overall achievement progress.
class UserAchievement {
  final int totalXp;
  final int level;
  final int xpToNextLevel;
  final int totalBadges;
  final int completedBadges;
  final List<UserBadgeProgress>
  badgeProgress;

  const UserAchievement({
    required this.totalXp,
    required this.level,
    required this.xpToNextLevel,
    required this.totalBadges,
    required this.completedBadges,
    required this.badgeProgress,
  });

  double get completionRate {
    if (totalBadges <= 0) {
      return 0.0;
    }

    return completedBadges / totalBadges;
  }
}

/// User level configuration.
class LevelConfig {
  final int level;
  final int xpRequired;
  final String title;

  const LevelConfig({
    required this.level,
    required this.xpRequired,
    required this.title,
  });

  static const List<LevelConfig> levels = [
    LevelConfig(
      level: 1,
      xpRequired: 0,
      title: 'Tourist',
    ),
    LevelConfig(
      level: 2,
      xpRequired: 100,
      title: 'Explorer',
    ),
    LevelConfig(
      level: 3,
      xpRequired: 250,
      title: 'Adventurer',
    ),
    LevelConfig(
      level: 4,
      xpRequired: 450,
      title: 'Historian',
    ),
    LevelConfig(
      level: 5,
      xpRequired: 700,
      title: 'Heritage Enthusiast',
    ),
    LevelConfig(
      level: 6,
      xpRequired: 1000,
      title: 'Culture Lover',
    ),
    LevelConfig(
      level: 7,
      xpRequired: 1500,
      title: 'Malaysia Insider',
    ),
    LevelConfig(
      level: 8,
      xpRequired: 2200,
      title: 'Heritage Master',
    ),
    LevelConfig(
      level: 9,
      xpRequired: 3200,
      title: 'Cultural Ambassador',
    ),
    LevelConfig(
      level: 10,
      xpRequired: 5000,
      title: 'Heritage Legend',
    ),
  ];

  static LevelConfig getLevelByXp(
      int xp,
      ) {
    LevelConfig result = levels.first;

    for (final LevelConfig level
    in levels) {
      if (xp >= level.xpRequired) {
        result = level;
      }
    }

    return result;
  }

  static LevelConfig? getNextLevel(
      int currentLevel,
      ) {
    if (currentLevel >= levels.last.level) {
      return null;
    }

    for (final LevelConfig level
    in levels) {
      if (level.level ==
          currentLevel + 1) {
        return level;
      }
    }

    return null;
  }

  static int getXpToNextLevel(
      int currentXp,
      ) {
    final LevelConfig currentLevel =
    getLevelByXp(currentXp);

    final LevelConfig? nextLevel =
    getNextLevel(
      currentLevel.level,
    );

    if (nextLevel == null) {
      return 0;
    }

    return nextLevel.xpRequired -
        currentXp;
  }
}