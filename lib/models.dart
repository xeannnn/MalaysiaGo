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

//Data Model & Serialization for Heritage Site
class HeritageSite {
  final String id;
  final String name;
  final String state;
  final String category;
  final String description;
  final String imageUrl;
  final double rating;
  final String unescoYear;
  final String locationCoordinates;

  HeritageSite({
    required this.id,
    required this.name,
    required this.state,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.rating = 4.5,
    required this.unescoYear,
    required this.locationCoordinates,
  });

  factory HeritageSite.fromJson(Map<String, dynamic> json) {
    return HeritageSite(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      state: json['state'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/300',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      unescoYear: json['unescoYear'] ?? 'N/A',
      locationCoordinates: json['locationCoordinates'] ?? '',
    );
  }
}