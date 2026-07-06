import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import '../../../community/domain/entities/obstacle.dart';
import '../../domain/entities/navigation_route.dart';
import '../../domain/repositories/route_repository.dart';

/// Perfis de rota suportados pelo OpenRouteService
enum _OrsProfile {
  /// Para pedestres sem restrição de mobilidade (calçadas comuns, atalhos)
  footWalking('foot-walking'),

  /// Para cadeirantes (evita escadas, prefere rampas e calçadas largas)
  wheelchair('wheelchair');

  final String slug;
  const _OrsProfile(this.slug);
}

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

    // Dispara as duas requisições em paralelo para menor latência
    final results = await Future.wait([
      _fetchRoute(
        profile: _OrsProfile.wheelchair,
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        obstaclesToAvoid: obstaclesToAvoid,
        apiKey: apiKey,
      ),
      _fetchRoute(
        profile: _OrsProfile.footWalking,
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        obstaclesToAvoid: obstaclesToAvoid,
        apiKey: apiKey,
      ),
    ]);

    // Filtra resultados nulos (caso um dos endpoints falhe individualmente)
    final routes = results.whereType<NavigationRoute>().toList();

    if (routes.isEmpty) {
      throw Exception('Nenhuma rota encontrada para o trajeto solicitado.');
    }

    return routes;
  }

  // ---------------------------------------------------------------------------
  // Faz a requisição para um perfil ORS específico e retorna a NavigationRoute
  // Retorna null se a requisição falhar (para não bloquear as demais)
  // ---------------------------------------------------------------------------
  Future<NavigationRoute?> _fetchRoute({
    required _OrsProfile profile,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String apiKey,
    List<Obstacle>? obstaclesToAvoid,
  }) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/${profile.slug}/geojson',
    );

    // Monta o payload base com as coordenadas [lng, lat] (padrão GeoJSON)
    final Map<String, dynamic> body = {
      'coordinates': [
        [originLng, originLat],
        [destLng, destLat],
      ],
    };

    // Adiciona polígonos de exclusão para obstáculos reportados pela comunidade
    if (obstaclesToAvoid != null && obstaclesToAvoid.isNotEmpty) {
      final List<List<List<List<double>>>> avoidPolygons = [];

      for (final obstacle in obstaclesToAvoid) {
        final double lat = obstacle.latitude;
        final double lng = obstacle.longitude;
        const double offset = 0.0001; // Bounding box de ~11x11 metros

        avoidPolygons.add([
          [
            [lng - offset, lat - offset],
            [lng + offset, lat - offset],
            [lng + offset, lat + offset],
            [lng - offset, lat + offset],
            [lng - offset, lat - offset], // fechamento do anel GeoJSON
          ]
        ]);
      }

      body['options'] = {
        'avoid_polygons': {
          'type': 'MultiPolygon',
          'coordinates': avoidPolygons,
        },
      };
    }

    try {
      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': apiKey,
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('Erro na requisição ORS: Código ${response.statusCode}');
      }

      return _parseResponse(
        json.decode(response.body),
        profile: profile,
      );
    } catch (e) {
      throw Exception('Erro de conexão ou comunicação com OpenRouteService: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Parseia o GeoJSON retornado pelo ORS e constrói a NavigationRoute
  // ---------------------------------------------------------------------------
  NavigationRoute _parseResponse(
    Map<String, dynamic> data, {
    required _OrsProfile profile,
  }) {
    double distanceMeters = 0.0;
    double durationSeconds = 0.0;
    List<RouteCoordinate> waypoints = [];
    List<RouteStep> steps = [];

    // Endpoint /geojson retorna FeatureCollection
    if (data['features'] is List && (data['features'] as List).isNotEmpty) {
      final feature = data['features'][0] as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>?;

      // Resumo: distância e duração
      if (properties?['summary'] is Map) {
        final summary = properties!['summary'] as Map;
        distanceMeters = (summary['distance'] as num?)?.toDouble() ?? 0.0;
        durationSeconds = (summary['duration'] as num?)?.toDouble() ?? 0.0;
      }

      // Geometria: lista de coordenadas [lng, lat]
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (geometry?['coordinates'] is List) {
        for (final point in geometry!['coordinates'] as List) {
          if (point is List && point.length >= 2) {
            waypoints.add(RouteCoordinate(
              (point[1] as num).toDouble(), // latitude
              (point[0] as num).toDouble(), // longitude
            ));
          }
        }
      } else if (geometry?['coordinates'] is String) {
        waypoints = _decodePolyline(geometry!['coordinates'] as String);
      }

      // Passos de navegação (turn-by-turn)
      if (properties?['segments'] is List) {
        final segments = properties!['segments'] as List;
        if (segments.isNotEmpty && segments[0] is Map) {
          final stepsData = (segments[0] as Map)['steps'] as List? ?? [];
          for (final step in stepsData) {
            final instruction = (step as Map)['instruction'] as String? ?? '';
            final stepDistance = (step['distance'] as num?)?.toDouble() ?? 0.0;
            final wayPoints = step['way_points'] as List?;
            if (instruction.isNotEmpty &&
                wayPoints != null &&
                wayPoints.length >= 2) {
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
    // Fallback para formato JSON padrão (não-geojson)
    else if (data['routes'] is List && (data['routes'] as List).isNotEmpty) {
      final route = (data['routes'] as List)[0] as Map<String, dynamic>;
      if (route['summary'] is Map) {
        final summary = route['summary'] as Map;
        distanceMeters = (summary['distance'] as num?)?.toDouble() ?? 0.0;
        durationSeconds = (summary['duration'] as num?)?.toDouble() ?? 0.0;
      }
      if (route['geometry'] is String) {
        waypoints = _decodePolyline(route['geometry'] as String);
      }
    }

    if (waypoints.isEmpty) {
      throw Exception('Nenhuma rota encontrada na resposta da API');
    }

    final distanceKm = '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    final durationMin = '${(durationSeconds / 60).round()} min';

    // Metadados específicos de cada perfil
    return switch (profile) {
      _OrsProfile.wheelchair => NavigationRoute(
          title: 'Rota para Cadeirante',
          estimatedTime: durationMin,
          distance: distanceKm,
          accessibilityScore: 0.95,
          characteristics: const [
            'ACESSÍVEL PARA CADEIRA DE RODAS',
            'EVITA ESCADAS',
            'PREFERE RAMPAS',
          ],
          waypoints: waypoints,
          steps: steps,
        ),
      _OrsProfile.footWalking => NavigationRoute(
          title: 'Rota a Pé',
          estimatedTime: durationMin,
          distance: distanceKm,
          accessibilityScore: 0.60,
          characteristics: const [
            'PEDESTRE SEM RESTRIÇÃO',
            'CAMINHO MAIS CURTO',
          ],
          waypoints: waypoints,
          steps: steps,
        ),
    };
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
