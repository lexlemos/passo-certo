import '../entities/place.dart';
import '../repositories/geocoding_repository.dart';
import '../repositories/place_repository.dart';

/// Caso de uso unificado de busca de locais.
///
/// **Estratégia UFS-first com fallback Nominatim:**
///
/// ```
/// query → PlaceRepository (cache UFS)
///           ├─ resultados encontrados → retorna imediatamente (zero latência)
///           └─ lista vazia           → GeocodingRepository (Nominatim/OSM)
/// ```
///
/// Vantagens:
/// - Locais do campus UFS sempre aparecem primeiro, com nomes corretos em pt-BR.
/// - O Nominatim só é chamado quando necessário, economizando banda e respeitando
///   os rate limits da API pública.
/// - Em caso de falha de rede em qualquer camada, retorna lista vazia silenciosamente
///   para não travar a UI do usuário.
class SearchAddressUseCase {
  final PlaceRepository _placeRepository;
  final GeocodingRepository _geocodingRepository;

  const SearchAddressUseCase({
    required PlaceRepository placeRepository,
    required GeocodingRepository geocodingRepository,
  }) : _placeRepository = placeRepository,
       _geocodingRepository = geocodingRepository;

  /// Executa a busca unificada com lógica UFS-first.
  ///
  /// Parâmetros:
  /// - [query]: termo digitado pelo usuário.
  /// - [userLat], [userLon]: posição atual para relevância geográfica no Nominatim.
  Future<List<Place>> call(
    String query, {
    double? userLat,
    double? userLon,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    // ── Etapa A: busca no cache/banco da UFS ─────────────────────────────
    try {
      final ufsResult = await _placeRepository.searchPlaces(trimmedQuery);

      final ufsPlaces = ufsResult.fold(
        (_) => <Place>[], // falha silenciosa: continua para o Nominatim
        (places) => places,
      );

      // ── Etapa B: retorno imediato se a UFS respondeu com resultados ───
      if (ufsPlaces.isNotEmpty) return ufsPlaces;
    } catch (_) {
      // Falha inesperada no repositório da UFS: segue para o fallback.
    }

    // ── Etapa C: fallback para o Nominatim (OpenStreetMap) ───────────────
    try {
      return await _geocodingRepository.searchAddress(
        trimmedQuery,
        userLat: userLat,
        userLon: userLon,
      );
    } catch (_) {
      // Falha de rede no Nominatim: retorna lista vazia para não travar a UI.
      return const [];
    }
  }
}
