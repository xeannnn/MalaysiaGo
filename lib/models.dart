
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
