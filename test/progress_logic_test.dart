import 'package:flutter_test/flutter_test.dart';
import 'package:malaysiago/data/badge_data.dart';
import 'package:malaysiago/modules/mappage.dart';
import 'package:malaysiago/services/badge_service.dart';

void main() {
  test('every mapped heritage site contributes to a state badge', () {
    final badgeSiteIds = activeStateBadges
        .expand((badge) => badge.requiredSiteIds)
        .toSet();
    final mapSiteIds = heritageMapSites.map((site) => site.id).toSet();

    expect(badgeSiteIds.containsAll(mapSiteIds), isTrue);
    expect(mapSiteIds.containsAll(badgeSiteIds), isTrue);
    expect(
      heritageMapSites.map((site) => site.id).toSet().length,
      heritageMapSites.length,
    );
  });

  test('GPS visit and quiz XP calculations reject invalid awards', () {
    expect(BadgeService.calculateSiteXp('batu_caves'), 50);
    expect(BadgeService.calculateQuizXp(0, 0), 0);
    expect(BadgeService.calculateQuizXp(0, 5), 0);
    expect(BadgeService.calculateQuizXp(5, 5, perfect: true), 50);
  });
}
