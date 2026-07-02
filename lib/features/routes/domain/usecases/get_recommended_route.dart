import '../entities/navigation_route.dart';

class GetRecommendedRouteUseCase {
  /// Recebe uma lista de rotas disponíveis e recomenda a melhor baseada em acessibilidade.
  NavigationRoute? call(List<NavigationRoute> routes) {
    if (routes.isEmpty) return null;

    // Ordena pela pontuação de acessibilidade decrescente
    final sortedRoutes = List<NavigationRoute>.from(routes)
      ..sort((a, b) => b.accessibilityScore.compareTo(a.accessibilityScore));

    return sortedRoutes.first;
  }
}
