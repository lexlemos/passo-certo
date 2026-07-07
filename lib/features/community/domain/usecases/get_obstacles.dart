import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/obstacle.dart';
import '../repositories/obstacle_repository.dart';

class GetObstaclesUseCase {
  final ObstacleRepository _repository;

  GetObstaclesUseCase(this._repository);

  Future<Either<Failure, List<Obstacle>>> call() {
    return _repository.getObstacles();
  }
}
