import 'package:equatable/equatable.dart';

class Place extends Equatable {
  /// ID único do banco (UUID). Pode ser nulo para locais criados localmente
  /// antes de serem persistidos no Supabase.
  final String? id;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> searchTerms;
  final String category;
  final int floor;
  final bool isAccessible;

  const Place({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.searchTerms = const [],
    this.category = '',
    this.floor = 0,
    this.isAccessible = true,
  });

  Place copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    List<String>? searchTerms,
    String? category,
    int? floor,
    bool? isAccessible,
  }) {
    return Place(
      id: id ?? this.id,
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
    id,
    name,
    latitude,
    longitude,
    searchTerms,
    category,
    floor,
    isAccessible,
  ];
}
