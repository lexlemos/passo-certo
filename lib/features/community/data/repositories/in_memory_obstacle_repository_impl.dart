import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/obstacle.dart';
import '../../domain/repositories/obstacle_repository.dart';

class InMemoryObstacleRepositoryImpl implements ObstacleRepository {
  final List<Obstacle> _obstacles = [
    Obstacle(
      id: '1',
      latitude: -10.9472,
      longitude: -37.0731,
      type: ObstacleType.pothole,
      description: 'Buraco na calçada próximo à entrada do CCET',
      reportedAt: DateTime.now().subtract(const Duration(days: 2)),
      upvotes: 12,
    ),
    Obstacle(
      id: '2',
      latitude: -10.9350,
      longitude: -37.0650,
      type: ObstacleType.blockedSidewalk,
      description: 'Entulho bloqueando a rampa de acessibilidade do Terminal',
      reportedAt: DateTime.now().subtract(const Duration(hours: 5)),
      upvotes: 8,
    ),
    Obstacle(
      id: '3',
      latitude: -10.9430,
      longitude: -37.0710,
      type: ObstacleType.noTactilePaving,
      description: 'Ausência de piso podotátil na faixa de pedestres',
      reportedAt: DateTime.now().subtract(const Duration(days: 1)),
      upvotes: 4,
    ),
  ];

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
