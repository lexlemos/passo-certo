import 'package:flutter/material.dart';
import 'package:passo_certo/core/theme/app_theme.dart';

/// HUD de Ações do Mapa: Botões flutuantes para adicionar local, reportar obstáculo e re-centralizar GPS.
class MapActionButtonsHUD extends StatelessWidget {
  final VoidCallback onAddPlacePressed;
  final VoidCallback onAddObstaclePressed;
  final VoidCallback onRecenterPressed;

  const MapActionButtonsHUD({
    super.key,
    required this.onAddPlacePressed,
    required this.onAddObstaclePressed,
    required this.onRecenterPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: bottomInset + 24,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: 'Adicionar novo local neste ponto',
            child: FloatingActionButton.small(
              heroTag: 'add_place_btn_hud',
              backgroundColor: Colors.blue,
              onPressed: onAddPlacePressed,
              child: const Icon(
                Icons.business,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: 'Reportar obstáculo neste ponto',
            child: FloatingActionButton.small(
              heroTag: 'add_obstacle_btn_hud',
              backgroundColor: AppTheme.emergencyRed,
              onPressed: onAddObstaclePressed,
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: 'Centralizar mapa na minha localização atual',
            child: FloatingActionButton.small(
              heroTag: 'recenter_user_loc_btn_hud',
              backgroundColor: Colors.white,
              onPressed: onRecenterPressed,
              child: const Icon(
                Icons.my_location,
                color: AppTheme.spaceBlue,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
