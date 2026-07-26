import 'package:equatable/equatable.dart';

class Place extends Equatable {
  final String name;
  final double latitude;
  final double longitude;
  final List<String> searchTerms;
  final String category;
  final int floor;
  final bool isAccessible;

  const Place({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.searchTerms = const [],
    this.category = '',
    this.floor = 0,
    this.isAccessible = true,
  });

  Place copyWith({
    String? name,
    double? latitude,
    double? longitude,
    List<String>? searchTerms,
    String? category,
    int? floor,
    bool? isAccessible,
  }) {
    return Place(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      searchTerms: searchTerms ?? this.searchTerms,
      category: category ?? this.category,
      floor: floor ?? this.floor,
      isAccessible: isAccessible ?? this.isAccessible,
    );
  }

  @override
  List<Object?> get props => [
    name,
    latitude,
    longitude,
    searchTerms,
    category,
    floor,
    isAccessible,
  ];
}
