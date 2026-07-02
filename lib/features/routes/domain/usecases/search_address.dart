import '../entities/place.dart';
import '../repositories/geocoding_repository.dart';

class SearchAddressUseCase {
  final GeocodingRepository _repository;

  SearchAddressUseCase(this._repository);

  Future<List<Place>> call(String query, {double? userLat, double? userLon}) async {
    return await _repository.searchAddress(query, userLat: userLat, userLon: userLon);
  }
}
