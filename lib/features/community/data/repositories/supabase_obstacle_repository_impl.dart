import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/obstacle.dart';
import '../../domain/repositories/obstacle_repository.dart';
import '../models/obstacle_model.dart';

/// Implementação real do [ObstacleRepository] consumindo o Supabase (PostgreSQL).
///
/// **Design decisions:**
/// - [SupabaseClient] injetado via construtor (testável, sem acoplamento estático).
/// - `getObstacles()` filtra apenas registros `status = 'active'` para não
///   poluir o mapa com obstáculos já resolvidos pela comunidade.
/// - `reportObstacle()` faz INSERT; o ID é gerado no cliente como UUID v4.
/// - Erros de rede são encapsulados em [ServerFailure] sem vazar stack traces
///   do Supabase para camadas superiores.
class SupabaseObstacleRepositoryImpl implements ObstacleRepository {
  final SupabaseClient supabaseClient;

  const SupabaseObstacleRepositoryImpl({required this.supabaseClient});

  // ─── Implementações do contrato ───────────────────────────────────────────

  /// Retorna apenas os obstáculos com `status = 'active'` ordenados pelo
  /// mais recente, para exibição no mapa da comunidade.
  @override
  Future<Either<Failure, List<Obstacle>>> getObstacles() async {
    try {
      final response = await supabaseClient
          .from('obstacles')
          .select()
          .eq('status', 'active')
          .order('reported_at', ascending: false);

      final obstacles = (response as List<dynamic>)
          .map((row) => ObstacleModel.fromJson(row as Map<String, dynamic>))
          .toList(growable: false);

      return Right(obstacles);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Falha ao buscar obstáculos: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado ao buscar obstáculos: $e'));
    }
  }

  /// Persiste um novo obstáculo na tabela `obstacles`.
  ///
  /// O [Obstacle.id] recebido deve ser um UUID v4 gerado no cliente
  /// (via pacote `uuid`) para garantir idempotência e rastreabilidade local.
  ///
  /// `reported_at` é sempre enviado em UTC para consistência com `timestamptz`
  /// do PostgreSQL, independente do timezone do dispositivo do usuário.
  @override
  Future<Either<Failure, void>> reportObstacle(Obstacle obstacle) async {
    try {
      // Converte a entidade de domínio para o modelo de dados com toJson.
      final model = ObstacleModel(
        id: obstacle.id,
        latitude: obstacle.latitude,
        longitude: obstacle.longitude,
        type: obstacle.type,
        description: obstacle.description,
        reportedAt: obstacle.reportedAt,
        upvotes: obstacle.upvotes,
        reporterId: obstacle.reporterId,
        severity: obstacle.severity,
        status: obstacle.status,
      );

      await supabaseClient.from('obstacles').insert(model.toJson());

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Falha ao reportar obstáculo: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado ao reportar obstáculo: $e'));
    }
  }
}
