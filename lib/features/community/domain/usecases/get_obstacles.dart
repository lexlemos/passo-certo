import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/obstacle.dart';
import '../repositories/obstacle_repository.dart';

class GetObstaclesUseCase {
  final ObstacleRepository _repository;

  GetObstaclesUseCase(this._repository);

  Future<Either<Failure, List<Obstacle>>> call({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
  }) {
    return _repository.getObstaclesInViewport(minLat, minLng, maxLat, maxLng);
  }
}
