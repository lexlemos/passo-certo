import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/obstacle.dart';
import '../../domain/repositories/obstacle_repository.dart';

class InMemoryObstacleRepositoryImpl implements ObstacleRepository {
  final List<Obstacle> _obstacles = [];

  @override
  Future<Either<Failure, List<Obstacle>>> getObstacles() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Right(List<Obstacle>.unmodifiable(_obstacles));
  }

  @override
  Future<Either<Failure, void>> reportObstacle(Obstacle obstacle) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _obstacles.add(obstacle);
    return const Right(null);
  }
}
