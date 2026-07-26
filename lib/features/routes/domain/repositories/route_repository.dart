import '../../../community/domain/entities/obstacle.dart';
import '../entities/navigation_route.dart';

abstract class RouteRepository {
  Future<List<NavigationRoute>> getRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    List<Obstacle>? blockingObstacles,
  });
}
