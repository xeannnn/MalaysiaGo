const double heritageCheckInRadiusMeters = 100;
const double maximumHeritageGpsAccuracyMeters = 100;

bool canCheckInAtHeritageSite({
  required double distanceMeters,
  required double accuracyMeters,
}) {
  return distanceMeters.isFinite &&
      accuracyMeters.isFinite &&
      distanceMeters >= 0 &&
      accuracyMeters >= 0 &&
      distanceMeters <= heritageCheckInRadiusMeters &&
      accuracyMeters <= maximumHeritageGpsAccuracyMeters;
}
