import '../entities/navigation_route.dart';
import '../repositories/route_repository.dart';

class GetRecommendedRouteUseCase {
  final RouteRepository _repository;

  GetRecommendedRouteUseCase(this._repository);

  /// Obtém as rotas do repositório e recomenda a melhor baseada em acessibilidade.
  Future<NavigationRoute?> call() async {
    final routes = await _repository.getRoutes();
    if (routes.isEmpty) return null;

    // Ordena pela pontuação de acessibilidade decrescente
    final sortedRoutes = List<NavigationRoute>.from(routes)
      ..sort((a, b) => b.accessibilityScore.compareTo(a.accessibilityScore));

    return sortedRoutes.first;
  }
}
