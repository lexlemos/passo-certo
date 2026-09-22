import '../../domain/entities/place.dart';

abstract class RecentSearchRepository {
  Future<List<Place>> getRecentSearches();
  Future<void> saveRecentSearch(Place place);
}
