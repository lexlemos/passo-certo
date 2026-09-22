import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:isolate';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import '../../../community/domain/entities/obstacle.dart';
import '../../domain/entities/navigation_route.dart';
import '../../domain/repositories/route_repository.dart';
import '../../../../core/utils/geo_utils.dart';
import 'dart:math' as math;

class RouteGeometrySimplifier {
  static List<LatLng> rdp(List<RouteCoordinate> points, double epsilon) {
    if (points.length < 3) {
      return points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    }

    double dmax = 0;
    int index = 0;

    for (int i = 1; i < points.length - 1; i++) {
      double d = _perpendicularDistance(
        points[i],
        points[0],
        points[points.length - 1],
      );
      if (d > dmax) {
        index = i;
        dmax = d;
      }
    }

    List<LatLng> res = [];
    if (dmax > epsilon) {
      List<LatLng> recResults1 = rdp(points.sublist(0, index + 1), epsilon);
      List<LatLng> recResults2 = rdp(
        points.sublist(index, points.length),
        epsilon,
      );

      res.addAll(recResults1.sublist(0, recResults1.length - 1));
      res.addAll(recResults2);
    } else {
      res.add(LatLng(points[0].latitude, points[0].longitude));
      res.add(
        LatLng(
          points[points.length - 1].latitude,
          points[points.length - 1].longitude,
        ),
      );
    }
    return res;
  }

  static double _perpendicularDistance(
    RouteCoordinate pt,
    RouteCoordinate lineStart,
    RouteCoordinate lineEnd,
  ) {
    double x0 = pt.longitude;
    double y0 = pt.latitude;
    double x1 = lineStart.longitude;
    double y1 = lineStart.latitude;
    double x2 = lineEnd.longitude;
    double y2 = lineEnd.latitude;

    double num = ((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1).abs();
    double den = math.sqrt(math.pow(y2 - y1, 2) + math.pow(x2 - x1, 2));
    if (den == 0) return 0;
    return num / den;
  }
}

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

  ORSRouteRepositoryImpl({http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<List<NavigationRoute>> getRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    List<Obstacle>? blockingObstacles,
  }) async {
    final apiKey = dotenv.env['ORS_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception(
        'Chave de API do OpenRouteService não configurada no arquivo .env',
      );
    }

    // -------------------------------------------------------------------------
    // Filtragem inteligente de obstáculos por perfil (Design Universal)
    //
    // accessibleAvoidanceList → TODOS os obstáculos bloqueantes (cadeirantes):
    //   pothole, blockedSidewalk, stairs, noTactilePaving, other
    //
    // walkingAvoidanceList → APENAS bloqueios totais de calçada para pedestres:
    //   blockedSidewalk  (o pedestre contorna buracos/piso ruim com o passo)
    // -------------------------------------------------------------------------
    final accessibleAvoidanceList = List<Obstacle>.from(
      blockingObstacles ?? [],
    );

    final walkingAvoidanceList = (blockingObstacles ?? []).where((obs) {
      return obs.type == ObstacleType.blockedSidewalk;
    }).toList();

    // Dispara as duas requisições em paralelo com listas de obstáculos distintas
    final results = await Future.wait([
      _fetchRoute(
        profile: _OrsProfile.wheelchair,
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        blockingObstacles: accessibleAvoidanceList,
        apiKey: apiKey,
      ),
      _fetchRoute(
        profile: _OrsProfile.footWalking,
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        // Lista vazia → nenhum avoid_polygon enviado → ORS traça a linha mais curta
        blockingObstacles: walkingAvoidanceList,
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
    List<Obstacle>? blockingObstacles,
  }) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/${profile.slug}/geojson',
    );

    // Payload base com coordenadas GeoJSON e enriquecimento extra_info
    final Map<String, dynamic> body = {
      'coordinates': [
        [originLng, originLat],
        [destLng, destLat],
      ],
      'extra_info': ['surface', 'steepness', 'suitability'],
    };

    final Map<String, dynamic> options = {};

    // Formatação estrita de avoid_polygons no padrão GeoJSON MultiPolygon v2 do ORS
    if (blockingObstacles != null && blockingObstacles.isNotEmpty) {
      final List<List<List<double>>> avoidPolygonRings = [];

      for (final obstacle in blockingObstacles) {
        avoidPolygonRings.add(
          GeoUtils.createBoundingBoxPolygon(
            obstacle.latitude,
            obstacle.longitude,
            radiusInMeters: 10.0,
          ),
        );
      }

      // GeoJSON MultiPolygon v2: List<Polygon> onde Polygon = List<Ring> e Ring = List<Point[lon, lat]>
      // Profundidade estrita de 4 níveis de arrays: [[[[lon, lat], ...]]]]
      final List<List<List<List<double>>>> multiPolygonCoordinates =
          avoidPolygonRings.map((ring) => [ring]).toList();

      options['avoid_polygons'] = {
        'type': 'MultiPolygon',
        'coordinates': multiPolygonCoordinates,
      };
    }

    if (options.isNotEmpty) {
      body['options'] = options;
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
        developer.log(
          'Erro HTTP ${response.statusCode} na requisição ORS (${profile.slug}): ${response.body}',
          name: 'ORSRouteRepository',
        );
        throw Exception(
          'Erro na requisição ORS: Código ${response.statusCode}',
        );
      }

      final responseBody = response.body;
      return await Isolate.run(() {
        try {
          final data = json.decode(responseBody) as Map<String, dynamic>;
          return _parseResponse(data, profile: profile);
        } catch (e) {
          throw FormatException(
            'Falha ao decodificar GeoJSON do ORS (${profile.slug}): $e',
          );
        }
      });
    } catch (e, stackTrace) {
      developer.log(
        'Erro ao buscar rota ORS para o perfil ${profile.slug}',
        error: e,
        stackTrace: stackTrace,
        name: 'ORSRouteRepository',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Parseia o GeoJSON retornado pelo ORS e constrói a NavigationRoute
  // ---------------------------------------------------------------------------
  static NavigationRoute _parseResponse(
    Map<String, dynamic> data, {
    required _OrsProfile profile,
  }) {
    double distanceMeters = 0.0;
    double durationSeconds = 0.0;
    List<RouteCoordinate> waypoints = [];
    List<RouteStep> steps = [];
    Map<String, dynamic>? properties;

    // Endpoint /geojson retorna FeatureCollection
    if (data['features'] is List && (data['features'] as List).isNotEmpty) {
      final feature = data['features'][0] as Map<String, dynamic>;
      properties = feature['properties'] as Map<String, dynamic>?;

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
            waypoints.add(
              RouteCoordinate(
                (point[1] as num).toDouble(), // latitude
                (point[0] as num).toDouble(), // longitude
              ),
            );
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
                steps.add(
                  RouteStep(
                    instruction: instruction,
                    distance: stepDistance,
                    coordinate: LatLng(coord.latitude, coord.longitude),
                  ),
                );
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

    // Cálculo de pontuação dinâmica de acessibilidade baseado no extra_info retornado
    final dynamicScore = _calculateDynamicAccessibilityScore(
      properties,
      profile,
      distanceMeters,
    );

    // Epsilon de ~2 metros em graus geográficos (aprox 0.00002)
    final displayPoints = RouteGeometrySimplifier.rdp(waypoints, 0.00002);

    // Metadados específicos de cada perfil
    return switch (profile) {
      _OrsProfile.wheelchair => NavigationRoute(
        title: 'Rota Acessível',
        estimatedTime: durationMin,
        distance: distanceKm,
        accessibilityScore: dynamicScore,
        characteristics: const [
          'ACESSÍVEL PARA CADEIRA DE RODAS',
          'EVITA ESCADAS',
          'PREFERE RAMPAS',
        ],
        waypoints: waypoints,
        displayPoints: displayPoints,
        steps: steps,
      ),
      _OrsProfile.footWalking => NavigationRoute(
        title: 'Rota a Pé',
        estimatedTime: durationMin,
        distance: distanceKm,
        accessibilityScore: dynamicScore,
        characteristics: const ['PEDESTRE SEM RESTRIÇÃO', 'CAMINHO MAIS CURTO'],
        waypoints: waypoints,
        displayPoints: displayPoints,
        steps: steps,
      ),
    };
  }

  /// Calcula a pontuação dinâmica de acessibilidade baseada em superfície, inclinação e adequabilidade
  static double _calculateDynamicAccessibilityScore(
    Map<String, dynamic>? properties,
    _OrsProfile profile,
    double distanceMeters,
  ) {
    try {
      if (properties == null) {
        return profile == _OrsProfile.wheelchair ? 0.95 : 0.60;
      }

      final extras = properties['extras'] as Map<String, dynamic>?;
      if (extras == null || extras.isEmpty) {
        return profile == _OrsProfile.wheelchair ? 0.92 : 0.60;
      }

      double penalty = 0.0;

      // 1. Análise de Inclinação (Steepness extra_info)
      if (extras['steepness'] is Map &&
          (extras['steepness'] as Map)['summary'] is List) {
        final summaryList = (extras['steepness'] as Map)['summary'] as List;
        for (final item in summaryList) {
          if (item is Map) {
            final valueCode = (item['value'] as num?)?.toInt() ?? 0;
            final amountPct = (item['amount'] as num?)?.toDouble() ?? 0.0;
            final absVal = valueCode.abs();

            // Penaliza inclinações elevadas (código 2 ou maior = >6% de aclive/declive)
            if (absVal >= 2) {
              penalty += (absVal * 0.05) * (amountPct / 100.0);
            }
          }
        }
      }

      // 2. Análise de Superfície (Surface extra_info)
      if (extras['surface'] is Map &&
          (extras['surface'] as Map)['summary'] is List) {
        final summaryList = (extras['surface'] as Map)['summary'] as List;
        for (final item in summaryList) {
          if (item is Map) {
            final valueCode = (item['value'] as num?)?.toInt() ?? 0;
            final amountPct = (item['amount'] as num?)?.toDouble() ?? 0.0;

            // Códigos de superfície irregular/desfavorável (paralelepípedo, terra, etc.)
            if (valueCode > 3) {
              penalty += 0.15 * (amountPct / 100.0);
            }
          }
        }
      }

      // 3. Análise de Adequabilidade (Suitability extra_info)
      if (extras['suitability'] is Map &&
          (extras['suitability'] as Map)['summary'] is List) {
        final summaryList = (extras['suitability'] as Map)['summary'] as List;
        for (final item in summaryList) {
          if (item is Map) {
            final valueCode = (item['value'] as num?)?.toInt() ?? 1;
            final amountPct = (item['amount'] as num?)?.toDouble() ?? 0.0;

            if (valueCode >= 3) {
              penalty += ((valueCode - 2) * 0.08) * (amountPct / 100.0);
            }
          }
        }
      }

      if (profile == _OrsProfile.wheelchair) {
        final score = (0.95 - penalty).clamp(0.40, 0.99);
        return double.parse(score.toStringAsFixed(2));
      } else {
        // Pedestres desviam naturalmente de superfícies ruins com o passo;
        // aplicamos fator de penalidade reduzido (0.25) para não punir
        // rotas a pé que cruzem buracos ou pisos irregulares esporadicamente.
        final score = (0.60 - (penalty * 0.25)).clamp(0.30, 0.70);
        return double.parse(score.toStringAsFixed(2));
      }
    } catch (_) {
      return profile == _OrsProfile.wheelchair ? 0.95 : 0.60;
    }
  }

  /// Decodificador de Polyline (Google Polyline Algorithm) de alta performance
  static List<RouteCoordinate> _decodePolyline(String encoded) {
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
