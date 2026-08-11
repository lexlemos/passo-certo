import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/obstacle_repository.dart';

/// Use case responsável por apagar (soft-delete) um obstáculo pelo seu [id].
///
/// Marca o obstáculo como `resolved` no banco, sem apagá-lo fisicamente.
class DeleteObstacleUseCase {
  final ObstacleRepository _repository;

  DeleteObstacleUseCase(this._repository);

  Future<Either<Failure, void>> call(String obstacleId) {
    return _repository.deleteObstacle(obstacleId);
  }
}
