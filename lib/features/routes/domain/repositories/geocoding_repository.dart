import '../entities/place.dart';

abstract class GeocodingRepository {
  Future<List<Place>> searchAddress(
    String query, {
    double? userLat,
    double? userLon,
  });
  Future<Place> getPlaceFromCoordinates(double lat, double lng);
}
