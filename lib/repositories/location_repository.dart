abstract class LocationRepository {
  Future<void> saveLocation({
    required double latitude,
    required double longitude,
  });
}