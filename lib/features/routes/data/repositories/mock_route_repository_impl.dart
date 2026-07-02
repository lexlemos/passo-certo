import '../../domain/entities/navigation_route.dart';
import '../../domain/repositories/route_repository.dart';

class MockRouteRepositoryImpl implements RouteRepository {
  @override
  Future<List<NavigationRoute>> getRoutes() async {
    // Simula uma pequena latência de rede/banco de dados
    await Future.delayed(const Duration(milliseconds: 300));
    
    return const [
      NavigationRoute(
        title: 'Via CCET Park',
        estimatedTime: '15 min',
        distance: '1.2 km',
        accessibilityScore: 0.95,
        characteristics: ['PLANO', 'CALÇADAS BOAS'],
        waypoints: [
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
        characteristics: ['ACLIVE', 'ATENÇÃO CRUZAMENTOS'],
        waypoints: [
          RouteCoordinate(-10.9472, -37.0731),
          RouteCoordinate(-10.9430, -37.0710),
          RouteCoordinate(-10.9350, -37.0650),
        ],
      ),
    ];
  }
}
