import 'package:equatable/equatable.dart';

enum ObstacleType {
  pothole,
  noTactilePaving,
  stairs,
  blockedSidewalk,
  other,
}

class Obstacle extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final ObstacleType type;
  final String description;
  final DateTime reportedAt;
  final int upvotes;

  const Obstacle({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.description,
    required this.reportedAt,
    required this.upvotes,
  });

  @override
  List<Object?> get props => [
        id,
        latitude,
        longitude,
        type,
        description,
        reportedAt,
        upvotes,
      ];
}
