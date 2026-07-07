import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/place.dart';
import '../../domain/repositories/geocoding_repository.dart';

class NominatimGeocodingRepositoryImpl implements GeocodingRepository {
  final http.Client _client;

  NominatimGeocodingRepositoryImpl({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<List<Place>> searchAddress(String query, {double? userLat, double? userLon}) async {
    if (query.trim().isEmpty) return const [];

    String urlStr = 'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&addressdetails=1'
      '&limit=5'
      '&countrycodes=br';

    if (userLat != null && userLon != null) {
      urlStr += '&lat=$userLat&lon=$userLon';
    }

    final url = Uri.parse(urlStr);

    try {
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': 'PassoCertoApp/1.0.0 (contact: allex.lima.dev@gmail.com)',
          'Accept-Language': 'pt-BR,pt;q=0.9',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Nominatim HTTP Error: ${response.statusCode}');
      }

      final List<dynamic> data = json.decode(response.body);
      final List<Place> places = [];

      for (final item in data) {
        final displayName = item['display_name'] as String? ?? '';
        final latStr = item['lat'] as String?;
        final lonStr = item['lon'] as String?;

        if (displayName.isNotEmpty && latStr != null && lonStr != null) {
          final lat = double.tryParse(latStr);
          final lng = double.tryParse(lonStr);

          if (lat != null && lng != null) {
            places.add(Place(
              name: displayName,
              latitude: lat,
              longitude: lng,
            ));
          }
        }
      }

      return places;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<Place> getPlaceFromCoordinates(double lat, double lng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json'
      '&lat=$lat'
      '&lon=$lng'
      '&addressdetails=1',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': 'PassoCertoApp/1.0.0 (contact: allex.lima.dev@gmail.com)',
          'Accept-Language': 'pt-BR,pt;q=0.9',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Nominatim HTTP Error: ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map) {
        throw Exception('Formato de resposta inválido do Nominatim');
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
      final address = data['address'] as Map?;
      String name = '';

      if (address != null) {
        final parts = <String>[];
        if (address['road'] != null) parts.add(address['road'].toString());
        if (address['suburb'] != null) parts.add(address['suburb'].toString());
        if (address['city'] != null || address['town'] != null || address['village'] != null) {
          parts.add((address['city'] ?? address['town'] ?? address['village']).toString());
        }
        name = parts.join(', ');
      }

      if (name.isEmpty) {
        name = data['display_name']?.toString() ?? 'Localização Atual';
      }

      return Place(
        name: name,
        latitude: lat,
        longitude: lng,
      );
    } catch (_) {
      // Fallback resiliente: evita crashar ou travar a UI caso o Nominatim esteja fora do ar
      return Place(
        name: 'Localização Atual ($lat, $lng)',
        latitude: lat,
        longitude: lng,
      );
    }
  }
}
