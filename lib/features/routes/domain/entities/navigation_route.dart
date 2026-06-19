class RouteCoordinate {
  final double latitude;
  final double longitude;

  const RouteCoordinate(this.latitude, this.longitude);
}

class NavigationRoute {
  final String title;
  final String estimatedTime;
  final String distance;
  final double accessibilityScore; // 0.0 to 1.0 (95% = 0.95)
  final List<String> characteristics;
  final List<RouteCoordinate> waypoints;

  const NavigationRoute({
    required this.title,
    required this.estimatedTime,
    required this.distance,
    required this.accessibilityScore,
    required this.characteristics,
    required this.waypoints,
  });

  bool get isHighlyAccessible => accessibilityScore >= 0.8;
}
