import '../entities/place.dart';
import '../repositories/recent_search_repository.dart';

class GetRecentSearchesUseCase {
  final RecentSearchRepository repository;

  GetRecentSearchesUseCase(this.repository);

  Future<List<Place>> call() async {
    return await repository.getRecentSearches();
  }
}
