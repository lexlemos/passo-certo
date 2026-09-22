import '../../domain/entities/place.dart';
import '../../domain/repositories/recent_search_repository.dart';
import '../datasources/recent_search_local_data_source.dart';

class RecentSearchRepositoryImpl implements RecentSearchRepository {
  final RecentSearchLocalDataSource localDataSource;

  RecentSearchRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Place>> getRecentSearches() async {
    try {
      return await localDataSource.getRecentSearches();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveRecentSearch(Place place) async {
    try {
      await localDataSource.saveRecentSearch(place);
    } catch (e) {
      // Ignorar erros de persistência local por enquanto
    }
  }
}
