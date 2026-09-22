import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/entities/place.dart';

/// Helper imutável e performático para gerar Marcadores de Locais no flutter_map.
///
/// Ao fornecer [onTap], cada marcador se torna tocável, permitindo exibir
/// detalhes do local ou acionar a lógica de exclusão.
abstract class PlaceMarkersLayer {
  static List<Marker> buildMarkers(
    List<Place> addedPlaces, {
    void Function(Place place)? onTap,
  }) {
    return addedPlaces.map((p) {
      final String semanticLabel = onTap != null
          ? 'Local: ${p.name}. Toque para ver detalhes ou remover.'
          : 'Novo local: ${p.name}';

      final Widget markerWidget = Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.business, color: Colors.white, size: 14),
      );

      return Marker(
        point: LatLng(p.latitude, p.longitude),
        width: 36,
        height: 36,
        child: Semantics(
          label: semanticLabel,
          button: onTap != null,
          child: onTap != null
              ? GestureDetector(onTap: () => onTap(p), child: markerWidget)
              : markerWidget,
        ),
      );
    }).toList();
  }
}
