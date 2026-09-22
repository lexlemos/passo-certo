import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/place.dart';

/// Contrato de domínio para acesso aos locais (POIs) da UFS.
///
/// Segue o princípio da Inversão de Dependência (DIP): a camada de domínio
/// depende apenas desta abstração, nunca de detalhes de infraestrutura
/// (Supabase, HTTP, cache etc.).
abstract class PlaceRepository {
  /// Retorna todos os locais da UFS cadastrados no banco, ordenados por nome.
  Future<List<Place>> getUfsPlaces();

  /// Retorna todos os locais com tratamento explícito de falhas via [Either].
  Future<Either<Failure, List<Place>>> getAllPlaces();

  /// Busca locais por nome ou termo de pesquisa.
  Future<Either<Failure, List<Place>>> searchPlaces(String query);

  /// Adiciona um novo local da UFS e atualiza o cache.
  Future<Either<Failure, Place>> addPlace(Place place);
}
