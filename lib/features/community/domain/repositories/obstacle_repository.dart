import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/obstacle.dart';

abstract class ObstacleRepository {
  Future<Either<Failure, List<Obstacle>>> getObstaclesInViewport(
    double minLat,
    double minLng,
    double maxLat,
    double maxLng,
  );
  Future<Either<Failure, void>> reportObstacle(Obstacle obstacle);
  Future<Either<Failure, void>> deleteObstacle(String obstacleId);
}
