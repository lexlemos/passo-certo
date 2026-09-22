import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/place_repository.dart';

/// Use case responsável por apagar um local pelo seu [id] do banco.
class DeletePlaceUseCase {
  final PlaceRepository _repository;

  DeletePlaceUseCase(this._repository);

  Future<Either<Failure, void>> call(String placeId) {
    return _repository.deletePlace(placeId);
  }
}
