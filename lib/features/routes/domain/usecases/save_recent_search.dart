import '../entities/place.dart';
import '../repositories/recent_search_repository.dart';

class SaveRecentSearchUseCase {
  final RecentSearchRepository repository;

  SaveRecentSearchUseCase(this.repository);

  Future<void> call(Place place) async {
    return await repository.saveRecentSearch(place);
  }
}
