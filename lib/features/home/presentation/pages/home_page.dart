import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_card.dart';
import '../widgets/emergency_dialog_sheet.dart';
import '../../../community/presentation/widgets/report_obstacle_bottom_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Seção de Boas-vindas (Topo)
          Text('Olá, Maria!', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text('Onde vamos hoje?', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),

          // 2. Card Principal de Rota
          BaseCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            isButton: true,
            onTapHint: 'Iniciar navegação segura passo a passo',
            semanticLabel:
                'Botão Iniciar Rota. Toque para iniciar uma navegação segura passo a passo',
            onTap: () {
              context.go('/routes');
            },
            gradient: const LinearGradient(
              colors: [AppTheme.mintGreen, AppColors.darkTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.explore,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Iniciar Rota',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Navegação segura passo a passo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Card de Ação Rápida: Reportar Obstáculo
          BaseCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(16),
            isButton: true,
            onTapHint: 'Reportar problemas ou barreiras na via de tráfego',
            semanticLabel: 'Botão Reportar Obstáculo',
            onTap: () {
              // Abre o bottom sheet de reporte com uma localização simulada padrão (próximo à UFS)
              ReportObstacleBottomSheet.show(
                context,
                const LatLng(-10.9472, -37.0731),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.lightBlueBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.alertBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Reportar Obstáculo',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Card de Emergência (Inferior)
          BaseCard(
            backgroundColor: AppTheme.emergencyRed,
            isButton: true,
            onTapHint:
                'Efetuar ligação telefônica de emergência para SAMU ou DIASE imediatamente',
            semanticLabel: 'Botão de Emergência. Ligar para SAMU ou DIASE',
            onTap: () => EmergencyDialogSheet.show(context),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sensors,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergência',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ligar para SAMU/DIASE',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.phone, color: Colors.white, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
