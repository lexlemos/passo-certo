import 'package:flutter/material.dart';

import '../route_map_view.dart';

/// Barra de Instrução no Topo do Mapa durante o Modo de Seleção (Obstáculo ou Local).
class MapSelectionModeBanner extends StatelessWidget {
  final MapSelectionMode selectionMode;
  final VoidCallback onCancel;

  const MapSelectionModeBanner({
    super.key,
    required this.selectionMode,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (selectionMode == MapSelectionMode.none) {
      return const SizedBox.shrink();
    }

    final isObstacle = selectionMode == MapSelectionMode.obstacle;
    final topInset = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topInset + 12,
      left: 16,
      right: 16,
      child: Semantics(
        label: isObstacle
            ? 'Modo de seleção ativo: Toque no mapa para marcar a localização do novo obstáculo'
            : 'Modo de seleção ativo: Toque no mapa para marcar a localização do novo local',
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isObstacle
                ? const Color(0xFFB71C1C)
                : const Color(0xFF0D47A1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isObstacle ? Icons.warning_amber_rounded : Icons.business,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isObstacle
                      ? 'Toque no mapa para marcar a localização do novo obstáculo'
                      : 'Toque no mapa para marcar a localização do novo local',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Cancelar modo de seleção',
                child: GestureDetector(
                  onTap: onCancel,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
