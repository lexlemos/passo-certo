import 'package:equatable/equatable.dart';

enum ObstacleType { pothole, noTactilePaving, stairs, blockedSidewalk, other }

enum ObstacleSeverity { warning, blocking }

enum ObstacleStatus { active, resolved }

class Obstacle extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final ObstacleType type;
  final String description;
  final DateTime reportedAt;
  final int upvotes;
  final ObstacleSeverity severity;
  final ObstacleStatus status;
  final String reporterId;

  const Obstacle({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.description,
    required this.reportedAt,
    required this.upvotes,
    required this.reporterId,
    this.severity = ObstacleSeverity.warning,
    this.status = ObstacleStatus.active,
  });

  Obstacle copyWith({
    String? id,
    double? latitude,
    double? longitude,
    ObstacleType? type,
    String? description,
    DateTime? reportedAt,
    int? upvotes,
    ObstacleSeverity? severity,
    ObstacleStatus? status,
    String? reporterId,
  }) {
    return Obstacle(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      description: description ?? this.description,
      reportedAt: reportedAt ?? this.reportedAt,
      upvotes: upvotes ?? this.upvotes,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      reporterId: reporterId ?? this.reporterId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    latitude,
    longitude,
    type,
    description,
    reportedAt,
    upvotes,
    severity,
    status,
    reporterId,
  ];
}
