import 'package:latlong2/latlong.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../../community/domain/entities/obstacle.dart';
import '../../../community/domain/repositories/obstacle_repository.dart';
import '../entities/navigation_route.dart';
import '../repositories/route_repository.dart';

class CalculateAccessibleRouteUseCase {
  final RouteRepository _routeRepository;
  CalculateAccessibleRouteUseCase(
    this._routeRepository,
  );

  Future<Either<Failure, List<NavigationRoute>>> call({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required bool avoidStairs,
    required bool requiresTactilePaving,
    List<Obstacle> activeObstacles = const [],
  }) async {
    try {
      List<Obstacle> allObstacles = List.from(activeObstacles);


      const distanceCalc = Distance();
      final originPoint = LatLng(originLat, originLng);
      final destPoint = LatLng(destLat, destLng);

      // 2. Filtra obstáculos baseado no perfil de acessibilidade do usuário e severidade
      final blockingObstacles = allObstacles.where((obstacle) {
        // Regra de negócio: apenas obstáculos bloqueantes alteram o traçado
        if (obstacle.severity != ObstacleSeverity.blocking) {
          return false;
        }

        // Ignora obstáculos se estiverem a menos de 20 metros da origem ou destino
        final obstaclePoint = LatLng(obstacle.latitude, obstacle.longitude);
        final distToOrigin = distanceCalc.as(
          LengthUnit.Meter,
          obstaclePoint,
          originPoint,
        );
        final distToDest = distanceCalc.as(
          LengthUnit.Meter,
          obstaclePoint,
          destPoint,
        );
        // Regra de Segurança Safe-Start & End: Ignora obstáculos a menos de 15 metros da origem ou destino
        if (distToOrigin < 15.0 || distToDest < 15.0) {
          return false;
        }

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
        if (requiresTactilePaving &&
            obstacle.type == ObstacleType.noTactilePaving) {
          return true;
        }
        return false;
      }).toList();

      // 3. Solicita a rota calculada contornando os polígonos geográficos dos obstáculos bloqueantes
      final routes = await _routeRepository.getRoutes(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        blockingObstacles: blockingObstacles,
      );

      return Right(routes);
    } catch (e) {
      return Left(
        ServerFailure('Falha ao calcular rota dinâmica acessível: $e'),
      );
    }
  }
}
