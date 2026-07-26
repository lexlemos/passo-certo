import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_card.dart';
import '../bloc/route_planning_bloc.dart';

class RouteListView extends StatelessWidget {
  const RouteListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
      buildWhen: (previous, current) =>
          previous.selectedRouteIndex != current.selectedRouteIndex ||
          !listEquals(previous.routes, current.routes) ||
          previous.recommendedRoute != current.recommendedRoute,
      builder: (context, state) {
        return Column(
          children: List.generate(state.routes.length, (index) {
            final route = state.routes[index];

            return RouteOptionCard(
              title: route.title,
              time: route.estimatedTime,
              distance: route.distance,
              isRecommended: route == state.recommendedRoute,
              accessibilityScore: route.accessibilityScore,
              tags: route.characteristics,
              isSelected: state.selectedRouteIndex == index,
              onTap: () => context.read<RoutePlanningBloc>().add(
                SelectRouteEvent(routeIndex: index),
              ),
            );
          }),
        );
      },
    );
  }
}

class RouteOptionCard extends StatelessWidget {
  final String title;
  final String time;
  final String distance;
  final bool isRecommended;
  final double accessibilityScore;
  final List<String> tags;
  final VoidCallback onTap;
  final bool isSelected;

  const RouteOptionCard({
    super.key,
    required this.title,
    required this.time,
    required this.distance,
    required this.isRecommended,
    required this.accessibilityScore,
    required this.tags,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighAccessibility = accessibilityScore >= 0.8;
    final accPercentage = (accessibilityScore * 100).toStringAsFixed(0);
    final accLevel = isHighAccessibility
        ? 'Alto ($accPercentage%)'
        : 'Médio ($accPercentage%)';

    return BaseCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      semanticLabel:
          "Rota $title. Tempo estimado $time. Distância $distance. Nível de acessibilidade $accLevel. Toque duas vezes para selecionar.",
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.mintGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRecommended) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.mintGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Recomendada',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      Text(
                        title,
                        style: theme.textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.mintGreen,
                      ),
                    ),
                    Text(distance, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: tags
                  .map(
                    (tag) => Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: AppTheme.softGreyBg,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text('Acessibilidade: $accLevel', style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: accessibilityScore,
              backgroundColor: AppTheme.softGreyBg,
              color: isHighAccessibility ? AppTheme.mintGreen : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}
