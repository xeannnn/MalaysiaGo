import 'package:flutter_test/flutter_test.dart';
import 'package:malaysiago/data/badge_data.dart';
import 'package:malaysiago/models.dart';
import 'package:malaysiago/modules/mappage.dart';
import 'package:malaysiago/services/badge_service.dart';
import 'package:malaysiago/services/location_checkin_policy.dart';

void main() {
  test('bundled and remote map sites contribute to state badges', () {
    final badgeSiteIds = activeStateBadges
        .expand((badge) => badge.requiredSiteIds)
        .toSet();
    final mapSiteIds = heritageMapSites.map((site) => site.id).toSet();

    expect(badgeSiteIds.containsAll(mapSiteIds), isTrue);
    expect(
      heritageMapSites.map((site) => site.id).toSet().length,
      heritageMapSites.length,
    );

    final mergedSites = mergeHeritageMapSites([
      HeritageSite(
        id: 'fort_cornwallis',
        name: 'Fort Cornwallis',
        location: 'Penang',
        description: 'Historic fort in George Town.',
        category: 'National',
        latitude: 5.4205,
        longitude: 100.3439,
        imageUrl: '',
        tags: const ['National'],
        duration: '1 hour',
        xp: 80,
        visited: false,
        isEditorPick: false,
      ),
    ]);

    expect(mergedSites.any((site) => site.id == 'fort_cornwallis'), isTrue);
    expect(
      mergedSites.where((site) => site.id == 'fort_cornwallis').single.hasQuiz,
      isTrue,
    );

    final nationalSites = filterHeritageMapSites(mergedSites, 'National');
    expect(nationalSites, isNotEmpty);
    expect(nationalSites.every((site) => site.category == 'National'), isTrue);
    expect(
      filterHeritageMapSites(mergedSites, 'All').length,
      mergedSites.length,
    );
  });

  test('GPS visit and quiz XP calculations reject invalid awards', () {
    expect(BadgeService.calculateSiteXp('batu_caves'), 50);
    expect(BadgeService.calculateQuizXp(0, 0), 0);
    expect(BadgeService.calculateQuizXp(0, 5), 0);
    expect(BadgeService.calculateQuizXp(5, 5, perfect: true), 50);
  });

  test('heritage check-in requires both proximity and GPS accuracy', () {
    expect(
      canCheckInAtHeritageSite(distanceMeters: 100, accuracyMeters: 100),
      isTrue,
    );
    expect(
      canCheckInAtHeritageSite(distanceMeters: 100.1, accuracyMeters: 20),
      isFalse,
    );
    expect(
      canCheckInAtHeritageSite(distanceMeters: 20, accuracyMeters: 100.1),
      isFalse,
    );
    expect(
      canCheckInAtHeritageSite(
        distanceMeters: double.infinity,
        accuracyMeters: 10,
      ),
      isFalse,
    );
  });
}
