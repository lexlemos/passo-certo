import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../domain/entities/navigation_route.dart';
import '../../../../../core/theme/app_theme.dart';

abstract class RoutePolylineLayer {
  static List<Polyline> buildPolylines({
    required List<NavigationRoute> routes,
    required int selectedRouteIndex,
  }) {
    final List<Polyline> polylines = [];

    // Adiciona as rotas não selecionadas primeiro
    for (int i = 0; i < routes.length; i++) {
      if (i == selectedRouteIndex) continue;
      final route = routes[i];
      final isAccessible =
          route.title.toLowerCase().contains('acessível') ||
          route.accessibilityScore >= 0.8;
      final unselectedColor = isAccessible
          ? AppTheme.mintGreen.withValues(alpha: 0.50)
          : const Color(0xFF2196F3).withValues(alpha: 0.55);

      polylines.add(
        Polyline(
          points: route.displayPoints,
          color: unselectedColor,
          strokeWidth: 6,
        ),
      );
    }

    // Adiciona a rota selecionada
    if (selectedRouteIndex >= 0 && selectedRouteIndex < routes.length) {
      final selectedRoute = routes[selectedRouteIndex];
      final isAccessible =
          selectedRoute.title.toLowerCase().contains('acessível') ||
          selectedRoute.accessibilityScore >= 0.8;
      final selectedColor = isAccessible
          ? AppTheme.mintGreen
          : const Color(0xFF2196F3);

      polylines.add(
        Polyline(
          points: selectedRoute.displayPoints,
          color: selectedColor,
          strokeWidth: 9,
        ),
      );
    }

    return polylines;
  }
}
