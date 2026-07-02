import '../entities/navigation_route.dart';

abstract class RouteRepository {
  Future<List<NavigationRoute>> getRoutes();
}
