import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/place_repository.dart';
import 'dart:developer' as developer;
import '../models/place_model.dart';

/// Implementação real do [PlaceRepository] consumindo o Supabase (PostgreSQL).
///
/// **Estratégia de Cache em Memória:**
/// Os locais da UFS são um conjunto finito e estável (dezenas/centenas de registros).
/// Após a primeira chamada de rede, toda filtragem subsequente é feita localmente
/// em memória — latência zero para o usuário, sem nova roundtrip ao banco.
///
/// O [SupabaseClient] é injetado via construtor para permitir mocking em testes.
class SupabasePlaceRepositoryImpl implements PlaceRepository {
  final SupabaseClient supabaseClient;

  /// Cache em memória dos locais da UFS.
  /// `null` = cache ainda não populado; lista vazia = banco sem registros.
  List<Place>? _cachedPlaces;

  SupabasePlaceRepositoryImpl({required this.supabaseClient});

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Normaliza uma string removendo acentos e convertendo para minúsculas,
  /// permitindo busca insensível a acentuação (ex: "biblio" encontra "Biblioteca").
  ///
  /// Técnica: decompõe caracteres Unicode (NFD) e descarta os diacríticos
  /// (categoria Unicode Mn — Mark, Nonspacing).
  static String _normalize(String input) {
    // Decomposição canônica NFD: separa a letra base do acento.
    // replaceAll com regex elimina todos os diacríticos em uma única passagem.
    return input
        .toLowerCase()
        .replaceAll(
          RegExp(r'[\u0300-\u036f]'),
          '',
        ) // remove combining diacritics
        .replaceAllMapped(RegExp(r'[àáâãäåæ]'), (_) => 'a')
        .replaceAllMapped(RegExp(r'[èéêë]'), (_) => 'e')
        .replaceAllMapped(RegExp(r'[ìíîï]'), (_) => 'i')
        .replaceAllMapped(RegExp(r'[òóôõöø]'), (_) => 'o')
        .replaceAllMapped(RegExp(r'[ùúûü]'), (_) => 'u')
        .replaceAllMapped(RegExp(r'[ç]'), (_) => 'c')
        .replaceAllMapped(RegExp(r'[ñ]'), (_) => 'n');
  }

  /// Verifica se um [Place] corresponde à [normalizedQuery].
  ///
  /// Critérios (OR):
  /// - O `name` normalizado contém a query.
  /// - Algum dos `searchTerms` normalizados contém a query.
  static bool _matchesQuery(Place place, String normalizedQuery) {
    if (_normalize(place.name).contains(normalizedQuery)) return true;
    return place.searchTerms.any(
      (term) => _normalize(term).contains(normalizedQuery),
    );
  }

  // ─── Implementações do contrato ───────────────────────────────────────────

  /// Busca todos os locais da UFS no Supabase e popula o [_cachedPlaces].
  ///
  /// Em chamadas subsequentes, o cache já estará populado e esta função
  /// apenas retorna a lista em memória — sem nenhuma chamada de rede.
  @override
  Future<List<Place>> getUfsPlaces() async {
    if (_cachedPlaces != null) return _cachedPlaces!;

    try {
      final response = await supabaseClient
          .from('places')
          .select()
          .order('name', ascending: true);

      _cachedPlaces = (response as List<dynamic>)
          .map((row) => PlaceModel.fromJson(row as Map<String, dynamic>))
          .toList();

      return _cachedPlaces!;
    } on PostgrestException catch (e) {
      throw ServerFailure('Falha ao buscar locais da UFS: ${e.message}');
    } catch (e) {
      throw ServerFailure('Erro inesperado ao buscar locais: $e');
    }
  }

  /// Filtra o cache local pelos critérios de busca.
  ///
  /// **Fluxo:**
  /// 1. Se o cache estiver vazio, chama [getUfsPlaces()] para populá-lo.
  /// 2. Filtra em memória com [_matchesQuery] — O(n) local, zero roundtrips.
  /// 3. Retorna `Right(results)` ou `Left(ServerFailure)` em caso de falha de rede.
  @override
  Future<Either<Failure, List<Place>>> searchPlaces(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const Right([]);

    try {
      // Garante que o cache está populado (chamada de rede apenas na 1ª vez).
      final allPlaces = await getUfsPlaces();

      final normalizedQuery = _normalize(trimmedQuery);

      final results = allPlaces
          .where((place) => _matchesQuery(place, normalizedQuery))
          .toList(growable: false);

      return Right(results);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Erro inesperado ao pesquisar locais: $e'));
    }
  }

  /// Retorna todos os locais encapsulando o resultado em [Either].
  @override
  Future<Either<Failure, List<Place>>> getAllPlaces() async {
    try {
      final places = await getUfsPlaces();
      return Right(places);
    } on ServerFailure catch (failure) {
      return Left(failure);
    }
  }

  /// Invalida o cache, forçando nova busca no banco na próxima chamada.
  /// Útil após operações de escrita (ex: admin adicionou um novo local).
  void invalidateCache() => _cachedPlaces = null;

  @override
  Future<Either<Failure, Place>> addPlace(Place place) async {
    print('================================================');
    print('[DEBUG_INSERCAO] Iniciando inserção de Local');
    print('[DEBUG_INSERCAO] Nome: ${place.name}');
    try {
      final model = PlaceModel(
        name: place.name,
        latitude: place.latitude,
        longitude: place.longitude,
        searchTerms: place.searchTerms,
        category: place.category,
        floor: place.floor,
        isAccessible: place.isAccessible,
      );

      print('[DEBUG_INSERCAO] JSON a ser enviado: ${model.toJson()}');
      final response = await supabaseClient
          .from('places')
          .insert(model.toJson())
          .select()
          .single();

      print('[DEBUG_INSERCAO] Inserção concluída! Resposta: $response');
      final addedPlace = PlaceModel.fromJson(response as Map<String, dynamic>);

      // Atualização otimista no cache
      if (_cachedPlaces != null) {
        _cachedPlaces!.add(addedPlace);
      }

      return Right(addedPlace);
    } on PostgrestException catch (e) {
      print('[DEBUG_INSERCAO] PostgrestException: ${e.message}');
      print('[DEBUG_INSERCAO] Detalhes: ${e.details}, Hint: ${e.hint}');
      developer.log(
        'PostgrestException ao adicionar local: ',
        error: e,
        name: 'SupabasePlaceRepositoryImpl',
      );
      return Left(ServerFailure('Falha ao adicionar local: ${e.message}'));
    } catch (e) {
      print('[DEBUG_INSERCAO] Exception Genérica: $e');
      developer.log(
        'Erro inesperado ao adicionar local: ',
        error: e,
        name: 'SupabasePlaceRepositoryImpl',
      );
      return Left(ServerFailure('Erro inesperado ao adicionar local: $e'));
    }
  }
}
