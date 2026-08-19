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
  const GuideChip(this.icon, this.label);
}

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

  factory HeritageSite.fromJson(Map<String, dynamic> json) {
    return HeritageSite(
      id: json['id'].toString(),

      name: json['name'] ?? 'Unknown Heritage',

      location: json['state'] ?? json['location'] ?? 'Malaysia',

      category: json['category'] ?? 'National',

      latitude: (json['latitude'] ?? 0).toDouble(),

      longitude: (json['longitude'] ?? 0).toDouble(),

      description: json['description'] ?? '',

      imageUrl: json['imageUrl'] ?? '',

      // Default values because API does not provide these
      tags: List<String>.from(json['tags'] ?? []),

      duration: json['duration'] ?? '1–2 hours',

      xp: json['xp'] ?? 50,

      visited: json['visited'] ?? false,

      isEditorPick: json['isEditorPick'] ?? false,
    );
  }
}
