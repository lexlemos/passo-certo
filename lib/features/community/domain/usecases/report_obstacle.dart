import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/obstacle.dart';
import '../repositories/obstacle_repository.dart';

class ReportObstacleUseCase {
  final ObstacleRepository _repository;

  ReportObstacleUseCase(this._repository);

  Future<Either<Failure, void>> call(Obstacle obstacle) {
    return _repository.reportObstacle(obstacle);
  }
}
