class AppConstants {
  /// Raio para colisão de obstáculos em metros.
  static const double obstacleProximityRadiusMeters = 15.0;

  /// Distância máxima de desvio permitida antes de recalcular a rota em metros.
  static const double routeRecalculationThresholdMeters = 40.0;

  /// Tempo de throttle do GPS em segundos.
  static const int gpsThrottleSeconds = 3;

  /// Coordenadas padrão da UFS
  static const double defaultMapCenterLat = -10.9472;
  static const double defaultMapCenterLng = -37.0731;
}
