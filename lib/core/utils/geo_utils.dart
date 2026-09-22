import 'dart:math' as math;
import '../config/app_constants.dart';

class GeoUtils {
  /// Cria um polígono de exclusão (Bounding Box) ao redor de um ponto.
  ///
  /// Utiliza matemática de coordenadas terrestres (considerando o raio da Terra)
  /// para converter metros em graus de latitude e longitude.
  ///
  /// Retorna os 5 pontos que formam um quadrado ao redor do centro,
  /// no formato GeoJSON exigido pelo OpenRouteService: [longitude, latitude].
  /// O primeiro e último ponto são idênticos para fechar o polígono.
  static List<List<double>> createBoundingBoxPolygon(
    double lat,
    double lon, {
    double radiusInMeters = AppConstants.obstacleProximityRadiusMeters,
  }) {
    const double earthRadius = 6378137.0; // Raio da Terra no equador em metros

    // Conversão de metros para graus (Latitude é constante)
    final double latDelta = (radiusInMeters / earthRadius) * (180.0 / math.pi);
    // Conversão de metros para graus (Longitude varia de acordo com o cosseno da latitude)
    final double lonDelta =
        (radiusInMeters / (earthRadius * math.cos(lat * math.pi / 180.0))) *
        (180.0 / math.pi);

    final double minLat = lat - latDelta;
    final double maxLat = lat + latDelta;
    final double minLon = lon - lonDelta;
    final double maxLon = lon + lonDelta;

    // Retorna as coordenadas no formato anel (Ring) GeoJSON: [[lon, lat], ...]
    return [
      [minLon, minLat],
      [maxLon, minLat],
      [maxLon, maxLat],
      [minLon, maxLat],
      [minLon, minLat], // Fechamento obrigatório do anel
    ];
  }
}
