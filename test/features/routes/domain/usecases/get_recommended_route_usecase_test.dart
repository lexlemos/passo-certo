import 'package:flutter_test/flutter_test.dart';
import 'package:passo_certo/features/routes/domain/entities/navigation_route.dart';
import 'package:passo_certo/features/routes/domain/repositories/route_repository.dart';
import 'package:passo_certo/features/routes/domain/usecases/get_recommended_route.dart';

class FakeRouteRepository implements RouteRepository {
  final List<NavigationRoute> routes;
  FakeRouteRepository(this.routes);

  @override
  Future<List<NavigationRoute>> getRoutes() async => routes;
}

void main() {
  late GetRecommendedRouteUseCase useCase;

  group('GetRecommendedRouteUseCase Tests', () {
    test('should return null when repository returns no routes', () async {
      final fakeRepo = FakeRouteRepository([]);
      useCase = GetRecommendedRouteUseCase(fakeRepo);

      final result = await useCase();

      expect(result, isNull);
    });

    test('should return the route with the highest accessibility score', () async {
      const routeLow = NavigationRoute(
        title: 'Rota de Baixa Acessibilidade',
        estimatedTime: '10 min',
        distance: '1.0 km',
        accessibilityScore: 0.5,
        characteristics: [],
        waypoints: [],
      );
      const routeHigh = NavigationRoute(
        title: 'Rota de Alta Acessibilidade',
        estimatedTime: '12 min',
        distance: '1.2 km',
        accessibilityScore: 0.95,
        characteristics: [],
        waypoints: [],
      );
      const routeMedium = NavigationRoute(
        title: 'Rota de Média Acessibilidade',
        estimatedTime: '15 min',
        distance: '1.5 km',
        accessibilityScore: 0.75,
        characteristics: [],
        waypoints: [],
      );

      final fakeRepo = FakeRouteRepository([routeLow, routeHigh, routeMedium]);
      useCase = GetRecommendedRouteUseCase(fakeRepo);

      final result = await useCase();

      expect(result, equals(routeHigh));
    });
  });
}
