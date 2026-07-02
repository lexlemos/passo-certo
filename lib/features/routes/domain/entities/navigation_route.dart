import 'package:flutter/foundation.dart';

class RouteCoordinate {
  final double latitude;
  final double longitude;

  const RouteCoordinate(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteCoordinate &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationRoute &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          estimatedTime == other.estimatedTime &&
          distance == other.distance &&
          accessibilityScore == other.accessibilityScore &&
          listEquals(characteristics, other.characteristics) &&
          listEquals(waypoints, other.waypoints);

  @override
  int get hashCode =>
      title.hashCode ^
      estimatedTime.hashCode ^
      distance.hashCode ^
      accessibilityScore.hashCode ^
      Object.hashAll(characteristics) ^
      Object.hashAll(waypoints);
}

