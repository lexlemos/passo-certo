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

  // ---------------------------------------------------------------------------
  // Configurações de Zoom do Mapa (Tile Scaling para navegação pedestre interna)
  // ---------------------------------------------------------------------------

  /// Zoom máximo da câmera. Acima do nível nativo do servidor, o flutter_map
  /// aplica escala digital (over-zoom) sobre o tile do nível 19 — sem tela cinza.
  static const double mapMaxZoom = 20.0;

  /// Nível máximo de tile que o servidor CartoCDN disponibiliza.
  /// Requisições HTTP para zooms acima deste nível retornariam 404/tile cinza.
  static const int mapMaxNativeZoom = 19;
}
