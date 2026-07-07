import '../entities/navigation_route.dart';
import '../repositories/route_repository.dart';

class GetRoutesUseCase {
  final RouteRepository _repository;

  GetRoutesUseCase(this._repository);

  Future<List<NavigationRoute>> call({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) {
    return _repository.getRoutes(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );
  }
}
