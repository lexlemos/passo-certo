import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/place.dart';
import '../repositories/place_repository.dart';

class AddPlaceUseCase {
  final PlaceRepository repository;

  AddPlaceUseCase(this.repository);

  Future<Either<Failure, Place>> call(Place place) async {
    return await repository.addPlace(place);
  }
}
