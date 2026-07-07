import '../entities/navigation_route.dart';
import '../repositories/route_repository.dart';

class GetRecommendedRouteUseCase {
  final RouteRepository _repository;

  GetRecommendedRouteUseCase(this._repository);

  /// Obtém as rotas do repositório e recomenda a melhor baseada em acessibilidade.
  Future<NavigationRoute?> call({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final routes = await _repository.getRoutes(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );
    if (routes.isEmpty) return null;

    // Ordena pela pontuação de acessibilidade decrescente
    final sortedRoutes = List<NavigationRoute>.from(routes)
      ..sort((a, b) => b.accessibilityScore.compareTo(a.accessibilityScore));

    return sortedRoutes.first;
  }
}
