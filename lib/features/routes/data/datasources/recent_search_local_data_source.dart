import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/place.dart';

abstract class RecentSearchLocalDataSource {
  Future<List<Place>> getRecentSearches();
  Future<void> saveRecentSearch(Place place);
}

class RecentSearchLocalDataSourceImpl implements RecentSearchLocalDataSource {
  static const String _key = 'recent_searches';
  final SharedPreferences sharedPreferences;

  RecentSearchLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<Place>> getRecentSearches() async {
    final jsonString = sharedPreferences.getString(_key);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => _placeFromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> saveRecentSearch(Place place) async {
    final searches = await getRecentSearches();

    // Remove duplicate if exists
    searches.removeWhere((p) => p.name == place.name);

    // Add to the top
    searches.insert(0, place);

    // Keep only last 5
    if (searches.length > 5) {
      searches.removeLast();
    }

    final jsonList = searches.map((p) => _placeToJson(p)).toList();
    await sharedPreferences.setString(_key, json.encode(jsonList));
  }

  Map<String, dynamic> _placeToJson(Place place) {
    return {
      'name': place.name,
      'latitude': place.latitude,
      'longitude': place.longitude,
      'category': place.category,
      'floor': place.floor,
      'isAccessible': place.isAccessible,
    };
  }

  Place _placeFromJson(Map<String, dynamic> json) {
    return Place(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category'] as String? ?? '',
      floor: json['floor'] as int? ?? 0,
      isAccessible: json['isAccessible'] as bool? ?? true,
    );
  }
}
