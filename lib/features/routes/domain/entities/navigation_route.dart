import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

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

class RouteStep {
  final String instruction;
  final double distance;
  final LatLng coordinate;

  const RouteStep({
    required this.instruction,
    required this.distance,
    required this.coordinate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteStep &&
          runtimeType == other.runtimeType &&
          instruction == other.instruction &&
          distance == other.distance &&
          coordinate == other.coordinate;

  @override
  int get hashCode => instruction.hashCode ^ distance.hashCode ^ coordinate.hashCode;
}

class NavigationRoute {
  final String title;
  final String estimatedTime;
  final String distance;
  final double accessibilityScore; // 0.0 to 1.0 (95% = 0.95)
  final List<String> characteristics;
  final List<RouteCoordinate> waypoints;
  final List<RouteStep> steps;
  final List<LatLng> latLngWaypoints;

  NavigationRoute({
    required this.title,
    required this.estimatedTime,
    required this.distance,
    required this.accessibilityScore,
    required this.characteristics,
    required this.waypoints,
    this.steps = const [],
  }) : latLngWaypoints = waypoints.map((c) => LatLng(c.latitude, c.longitude)).toList();

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
          listEquals(waypoints, other.waypoints) &&
          listEquals(steps, other.steps) &&
          listEquals(latLngWaypoints, other.latLngWaypoints);

  @override
  int get hashCode =>
      title.hashCode ^
      estimatedTime.hashCode ^
      distance.hashCode ^
      accessibilityScore.hashCode ^
      Object.hashAll(characteristics) ^
      Object.hashAll(waypoints) ^
      Object.hashAll(steps) ^
      Object.hashAll(latLngWaypoints);
}
