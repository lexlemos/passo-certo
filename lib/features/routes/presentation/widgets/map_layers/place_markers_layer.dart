import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/entities/place.dart';

/// Helper imutável e performático para gerar Marcadores de Locais no flutter_map.
abstract class PlaceMarkersLayer {
  static List<Marker> buildMarkers(List<Place> addedPlaces) {
    return addedPlaces
        .map(
          (p) => Marker(
            point: LatLng(p.latitude, p.longitude),
            width: 24,
            height: 24,
            child: Semantics(
              label: 'Novo local: ${p.name}',
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        )
        .toList();
  }
}
