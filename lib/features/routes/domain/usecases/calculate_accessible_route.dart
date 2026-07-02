import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../../community/domain/entities/obstacle.dart';
import '../../../community/domain/repositories/obstacle_repository.dart';
import '../entities/navigation_route.dart';
import '../repositories/route_repository.dart';

class CalculateAccessibleRouteUseCase {
  final RouteRepository _routeRepository;
  final ObstacleRepository _obstacleRepository;

  CalculateAccessibleRouteUseCase(this._routeRepository, this._obstacleRepository);

  Future<Either<Failure, List<NavigationRoute>>> call({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required bool avoidStairs,
    required bool requiresTactilePaving,
  }) async {
    try {
      // 1. Busca todos os obstáculos urbanos cadastrados de forma colaborativa
      final obstaclesResult = await _obstacleRepository.getObstacles();
      
      List<Obstacle> obstaclesToAvoid = [];

      obstaclesResult.fold(
        (failure) {
          // Em caso de falha de conexão com o banco de obstáculos, prosseguimos sem polígonos de exclusão
          // para não quebrar a geração da rota padrão para o usuário.
        },
        (obstacles) {
          // 2. Filtra obstáculos baseado no perfil de acessibilidade do usuário
          obstaclesToAvoid = obstacles.where((obstacle) {
            // Sempre evita buracos na calçada e calçadas bloqueadas
            if (obstacle.type == ObstacleType.pothole || 
                obstacle.type == ObstacleType.blockedSidewalk) {
              return true;
            }
            // Evita escadas se o usuário tiver restrições motoras/evitar escadas habilitado
            if (avoidStairs && obstacle.type == ObstacleType.stairs) {
              return true;
            }
            // Evita áreas sem piso podotátil se o usuário necessitar de piso tátil (necessidade visual)
            if (requiresTactilePaving && obstacle.type == ObstacleType.noTactilePaving) {
              return true;
            }
            return false;
          }).toList();
        },
      );

      // 3. Solicita a rota calculada contornando os polígonos geográficos dos obstáculos correspondentes
      final routes = await _routeRepository.getRoutes(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        obstaclesToAvoid: obstaclesToAvoid,
      );

      return Right(routes);
    } catch (e) {
      return Left(ServerFailure('Falha ao calcular rota dinâmica acessível: $e'));
    }
  }
}
