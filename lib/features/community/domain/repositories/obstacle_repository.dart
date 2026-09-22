import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/obstacle.dart';

abstract class ObstacleRepository {
  Future<Either<Failure, List<Obstacle>>> getObstacles();
  Future<Either<Failure, void>> reportObstacle(Obstacle obstacle);
}
