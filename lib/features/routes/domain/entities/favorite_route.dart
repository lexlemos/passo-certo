import 'package:equatable/equatable.dart';

class FavoriteRoute extends Equatable {
  final String id;
  final String userId;
  final String title;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final bool isShared;
  final String? shareCode;

  const FavoriteRoute({
    required this.id,
    required this.userId,
    required this.title,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    this.isShared = false,
    this.shareCode,
  });

  FavoriteRoute copyWith({
    String? id,
    String? userId,
    String? title,
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
    bool? isShared,
    String? shareCode,
  }) {
    return FavoriteRoute(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destLat: destLat ?? this.destLat,
      destLng: destLng ?? this.destLng,
      isShared: isShared ?? this.isShared,
      shareCode: shareCode ?? this.shareCode,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    originLat,
    originLng,
    destLat,
    destLng,
    isShared,
    shareCode,
  ];
}
