import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import '../../../community/domain/entities/obstacle.dart';
import '../../domain/entities/navigation_route.dart';
import '../../domain/repositories/route_repository.dart';

class ORSRouteRepositoryImpl implements RouteRepository {
  final http.Client _client;

  ORSRouteRepositoryImpl({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<NavigationRoute>> getRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    List<Obstacle>? obstaclesToAvoid,
  }) async {
    final apiKey = dotenv.env['ORS_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('Chave de API do OpenRouteService não configurada no arquivo .env');
    }

    final url = Uri.parse('https://api.openrouteservice.org/v2/directions/wheelchair/geojson');

    // Inicializa o payload base com as coordenadas de início e fim
    final Map<String, dynamic> body = {
      'coordinates': [
        [originLng, originLat],
        [destLng, destLat]
      ]
    };

    // Caso existam obstáculos a serem evitados, constrói os polígonos de exclusão (avoid_polygons)
    if (obstaclesToAvoid != null && obstaclesToAvoid.isNotEmpty) {
      final List<List<List<List<double>>>> avoidPolygons = [];

      for (final obstacle in obstaclesToAvoid) {
        final double lat = obstacle.latitude;
        final double lng = obstacle.longitude;
        const double offset = 0.0001; // Bounding box de aproximadamente 11x11 metros

        final double minLat = lat - offset;
        final double maxLat = lat + offset;
        final double minLng = lng - offset;
        final double maxLng = lng + offset;

        // O anel de coordenadas no GeoJSON deve ser fechado (primeira coordenada idêntica à última)
        // Ordem recomendada de desenho do polígono (sentido horário):
        avoidPolygons.add([
          [
            [minLng, minLat],
            [maxLng, minLat],
            [maxLng, maxLat],
            [minLng, maxLat],
            [minLng, minLat]
          ]
        ]);
      }

      body['options'] = {
        'avoid_polygons': {
          'type': 'MultiPolygon',
          'coordinates': avoidPolygons,
        }
      };
    }

    try {
      final response = await _client.post(
        url,
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Erro na requisição ORS: Código ${response.statusCode}');
      }

      final data = json.decode(response.body);
      
      double distanceMeters = 0.0;
      double durationSeconds = 0.0;
      List<RouteCoordinate> waypoints = [];
      List<RouteStep> steps = [];

      // Sendo o endpoint "/geojson", a resposta é estruturada como FeatureCollection
      if (data['features'] != null && data['features'] is List && data['features'].isNotEmpty) {
        final feature = data['features'][0];
        final properties = feature['properties'];
        if (properties != null && properties['summary'] != null && properties['summary'] is Map) {
          final summary = properties['summary'] as Map;
          distanceMeters = (summary['distance'] as num?)?.toDouble() ?? 0.0;
          durationSeconds = (summary['duration'] as num?)?.toDouble() ?? 0.0;
        }
        
        final geometry = feature['geometry'];
        if (geometry != null) {
          if (geometry['coordinates'] != null && geometry['coordinates'] is List) {
            final coords = geometry['coordinates'] as List;
            for (final point in coords) {
              if (point is List && point.length >= 2) {
                // GeoJSON coordinates são retornados como [longitude, latitude]
                waypoints.add(RouteCoordinate(
                  (point[1] as num).toDouble(),
                  (point[0] as num).toDouble(),
                ));
              }
            }
          } else if (geometry is String) {
            waypoints = _decodePolyline(geometry);
          }
        }

        // Extrai os passos/instruções de navegação do segmento GeoJSON
        if (properties != null && properties['segments'] != null && properties['segments'] is List) {
          final segments = properties['segments'] as List;
          if (segments.isNotEmpty && segments[0] is Map && segments[0]['steps'] != null && segments[0]['steps'] is List) {
            final stepsData = segments[0]['steps'] as List;
            for (final step in stepsData) {
              final instruction = step['instruction'] as String? ?? '';
              final stepDistance = (step['distance'] as num?)?.toDouble() ?? 0.0;
              final wayPoints = step['way_points'] as List?;
              if (instruction.isNotEmpty && wayPoints != null && wayPoints.length >= 2) {
                final startIndex = wayPoints[0] as int;
                if (startIndex < waypoints.length) {
                  final coord = waypoints[startIndex];
                  steps.add(RouteStep(
                    instruction: instruction,
                    distance: stepDistance,
                    coordinate: LatLng(coord.latitude, coord.longitude),
                  ));
                }
              }
            }
          }
        }
      } 
      // Fallback para o formato JSON padrão caso necessário
      else if (data['routes'] != null && data['routes'] is List && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final summary = route['summary'];
        if (summary != null && summary is Map) {
          distanceMeters = (summary['distance'] as num?)?.toDouble() ?? 0.0;
          durationSeconds = (summary['duration'] as num?)?.toDouble() ?? 0.0;
        }
        final geometryStr = route['geometry'];
        if (geometryStr is String) {
          waypoints = _decodePolyline(geometryStr);
        }
      }

      if (waypoints.isEmpty) {
        throw Exception('Nenhuma rota encontrada na resposta da API');
      }

      final distanceKm = '${(distanceMeters / 1000).toStringAsFixed(1)} km';
      final durationMin = '${(durationSeconds / 60).round()} min';

      return [
        NavigationRoute(
          title: 'Rota Acessível (ORS)',
          estimatedTime: durationMin,
          distance: distanceKm,
          accessibilityScore: 0.90,
          characteristics: const ['ACESSIBILIDADE DE CADEIRA DE RODAS', 'APOIO DE INFRAESTRUTURA'],
          waypoints: waypoints,
          steps: steps,
        ),
      ];
    } catch (e) {
      throw Exception('Erro de conexão ou comunicação com OpenRouteService: $e');
    }
  }

  /// Decodificador de Polyline (Google Polyline Algorithm) de alta performance
  List<RouteCoordinate> _decodePolyline(String encoded) {
    final List<RouteCoordinate> poly = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(RouteCoordinate(lat / 1e5, lng / 1e5));
    }

    return poly;
  }
}
