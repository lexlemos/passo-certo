import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../community/domain/entities/obstacle.dart';

/// Helper imutável e performático para gerar Marcadores de Obstáculos no flutter_map.
abstract class ObstacleMarkersLayer {
  static List<Marker> buildMarkers(List<Obstacle> obstacles) {
    return obstacles.map((obstacle) {
      final bool isBlocking = obstacle.severity == ObstacleSeverity.blocking;
      final Color bgColor = isBlocking
          ? const Color(0xFFD32F2F)
          : const Color(0xFFFBC02D);
      final Color iconColor = isBlocking ? Colors.white : Colors.black;
      final IconData iconData = isBlocking ? Icons.block : Icons.priority_high;
      final String semanticLabel = isBlocking
          ? 'PERIGO: Bloqueio. ${obstacle.description}'
          : 'ATENÇÃO: Aviso. ${obstacle.description}';

      return Marker(
        point: LatLng(obstacle.latitude, obstacle.longitude),
        width: 24,
        height: 24,
        alignment: Alignment.center,
        child: Semantics(
          label: semanticLabel,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(iconData, color: iconColor, size: 14),
          ),
        ),
      );
    }).toList();
  }
}
