import '../entities/navigation_route.dart';
import '../repositories/route_repository.dart';

class GetRoutesUseCase {
  final RouteRepository _repository;

  GetRoutesUseCase(this._repository);

  Future<List<NavigationRoute>> call() {
    return _repository.getRoutes();
  }
}
