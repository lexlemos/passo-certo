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

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Semantics(
        label:
            'Painel de Navegação Ativa. Instrução atual: $instructionText. Distância: $distanceText',
        child: Card(
          elevation: 8,
          color: AppTheme.spaceBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.mintGreen, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.navigation,
                      color: AppTheme.mintGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Navegação Ativa',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
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
                    color: Colors.white,
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
                      'Distância até a conversão:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      distanceText,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.mintGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emergencyRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
