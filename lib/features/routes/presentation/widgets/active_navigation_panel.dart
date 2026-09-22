import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/active_navigation_bloc.dart';

class ActiveNavigationPanel extends StatelessWidget {
  const ActiveNavigationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeNavState = context.watch<ActiveNavigationBloc>().state;

    if (!activeNavState.isActive) {
      return const SizedBox.shrink();
    }

    final step = activeNavState.currentStep;
    final instructionText =
        step?.instruction ?? 'Siga em frente pela rota acessível';
    final distanceText = activeNavState.distanceToNextStep > 0
        ? '${activeNavState.distanceToNextStep.toStringAsFixed(0)} m'
        : 'Próximo';

    final remainingMeters = activeNavState.remainingDistanceMeters;
    final remainingDistanceText = remainingMeters >= 1000
        ? '${(remainingMeters / 1000).toStringAsFixed(1)} km'
        : '${remainingMeters.toStringAsFixed(0)} m';
    final remainingTimeText = '${activeNavState.remainingDurationMinutes} min';

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Semantics(
        label:
            'Painel de Navegação Ativa. Instrução atual: $instructionText. Distância da conversão: $distanceText. Restante: $remainingDistanceText. Tempo estimado: $remainingTimeText.',
        child: Card(
          elevation: 6,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.mintGreen.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.mintGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: AppTheme.spaceBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Navegação Ativa',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.spaceBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (activeNavState.isOffRoute)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.emergencyRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Fora de Rota',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  instructionText,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.spaceBlue,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Próxima conversão:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      distanceText,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.spaceBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.softGreyBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Distância Restante',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            remainingDistanceText,
                            style: const TextStyle(
                              color: AppTheme.spaceBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      Column(
                        children: [
                          const Text(
                            'Chegada (ETA)',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            remainingTimeText,
                            style: const TextStyle(
                              color: AppTheme.spaceBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<ActiveNavigationBloc>().add(
                      StopNavigationEvent(),
                    );
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    'Encerrar Navegação',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emergencyRed,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
