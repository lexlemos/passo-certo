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
        if (state.routes.isEmpty) {
          return const SizedBox.shrink();
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.15,
          ),
          itemCount: state.routes.length,
          itemBuilder: (context, index) {
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
          },
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
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      semanticLabel:
          "Rota $title. Tempo estimado $time. Distância $distance. Nível de acessibilidade $accLevel. Toque duas vezes para selecionar.",
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.mintGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRecommended) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.mintGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Recomendada',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        time,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.mintGreen,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Acessibilidade: $accPercentage%',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: accessibilityScore,
                    minHeight: 4,
                    backgroundColor: AppTheme.softGreyBg,
                    color: isHighAccessibility
                        ? AppTheme.mintGreen
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
