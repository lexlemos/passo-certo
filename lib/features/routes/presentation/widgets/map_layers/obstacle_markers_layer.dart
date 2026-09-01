import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../community/domain/entities/obstacle.dart';

/// Helper imutável e performático para gerar Marcadores de Obstáculos no flutter_map.
///
/// Ao fornecer [onTap], cada marcador se torna tocável, permitindo acionar
/// a lógica de exclusão do obstáculo correspondente.
abstract class ObstacleMarkersLayer {
  static List<Marker> buildMarkers(
    List<Obstacle> obstacles, {
    void Function(Obstacle obstacle)? onTap,
  }) {
    return obstacles.map((obstacle) {
      final bool isBlocking = obstacle.severity == ObstacleSeverity.blocking;
      final Color bgColor = isBlocking
          ? const Color(0xFFD32F2F)
          : const Color(0xFFFBC02D);
      final Color iconColor = isBlocking ? Colors.white : Colors.black;
      final IconData iconData = isBlocking ? Icons.block : Icons.priority_high;
      final String semanticLabel = isBlocking
          ? 'PERIGO: Bloqueio. ${obstacle.description}. Toque para remover.'
          : 'ATENÇÃO: Aviso. ${obstacle.description}. Toque para remover.';

      final Widget markerWidget = Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(iconData, color: iconColor, size: 14),
      );

      return Marker(
        point: LatLng(obstacle.latitude, obstacle.longitude),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Semantics(
          label: semanticLabel,
          button: onTap != null,
          child: onTap != null
              ? GestureDetector(
                  onTap: () => onTap(obstacle),
                  child: markerWidget,
                )
              : markerWidget,
        ),
      );
    }).toList();
  }
}
