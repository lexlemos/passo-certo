import '../../../community/domain/entities/obstacle.dart';
import '../../domain/entities/navigation_route.dart';
import '../../domain/repositories/route_repository.dart';

class MockRouteRepositoryImpl implements RouteRepository {
  @override
  Future<List<NavigationRoute>> getRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    List<Obstacle>? obstaclesToAvoid,
  }) async {
    // Simula uma pequena latência de rede/banco de dados
    await Future.delayed(const Duration(milliseconds: 300));
    
    return [
      NavigationRoute(
        title: 'Via CCET Park',
        estimatedTime: '15 min',
        distance: '1.2 km',
        accessibilityScore: 0.95,
        characteristics: const ['PLANO', 'CALÇADAS BOAS'],
        waypoints: const [
          RouteCoordinate(-10.9472, -37.0731),
          RouteCoordinate(-10.9450, -37.0715),
          RouteCoordinate(-10.9350, -37.0650),
        ],
      ),
      NavigationRoute(
        title: 'Via Terminal UFS',
        estimatedTime: '12 min',
        distance: '0.9 km',
        accessibilityScore: 0.60,
        characteristics: const ['ACLIVE', 'ATENÇÃO CRUZAMENTOS'],
        waypoints: const [
          RouteCoordinate(-10.9472, -37.0731),
          RouteCoordinate(-10.9430, -37.0710),
          RouteCoordinate(-10.9350, -37.0650),
        ],
      ),
    ];
  }
}
