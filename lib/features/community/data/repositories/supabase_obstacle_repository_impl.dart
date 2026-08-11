import 'dart:developer' as developer;
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
          .eq('status', 'ACTIVE')
          .order('created_at', ascending: false);

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

  /// Marca um obstáculo existente como `RESOLVED` (soft-delete).
  ///
  /// O obstáculo não é removido fisicamente; apenas seu `status` é atualizado
  /// para `'RESOLVED'`, fazendo com que ele deixe de aparecer no mapa
  /// (pois [getObstacles] filtra apenas `status = 'ACTIVE'`).
  @override
  Future<Either<Failure, void>> deleteObstacle(String obstacleId) async {
    developer.log(
      'Iniciando exclusão (soft-delete) do Obstáculo. ID: $obstacleId',
      name: 'SupabaseObstacleRepositoryImpl',
    );
    try {
      await supabaseClient
          .from('obstacles')
          .update({'status': 'RESOLVED'})
          .eq('id', obstacleId);

      developer.log(
        'Obstáculo marcado como RESOLVED com sucesso!',
        name: 'SupabaseObstacleRepositoryImpl',
      );

      return const Right(null);
    } on PostgrestException catch (e) {
      developer.log(
        'PostgrestException ao excluir obstáculo: ${e.message}',
        error: e,
        name: 'SupabaseObstacleRepositoryImpl',
      );
      return Left(ServerFailure('Falha ao excluir obstáculo: ${e.message}'));
    } catch (e) {
      developer.log(
        'Erro inesperado ao excluir obstáculo: $e',
        error: e,
        name: 'SupabaseObstacleRepositoryImpl',
      );
      return Left(ServerFailure('Erro inesperado ao excluir obstáculo: $e'));
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
    developer.log(
      'Iniciando inserção de Obstáculo. ID: ${obstacle.id}, Tipo: ${obstacle.type}',
      name: 'SupabaseObstacleRepositoryImpl',
    );
    try {
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

      await supabaseClient.from('obstacles').insert(model.toJson()).select();
      developer.log(
        'Inserção de obstáculo concluída com sucesso!',
        name: 'SupabaseObstacleRepositoryImpl',
      );

      return const Right(null);
    } on PostgrestException catch (e) {
      developer.log(
        'PostgrestException ao reportar obstáculo: ${e.message}',
        error: e,
        name: 'SupabaseObstacleRepositoryImpl',
      );
      return Left(ServerFailure('Falha ao reportar obstáculo: ${e.message}'));
    } catch (e) {
      developer.log(
        'Erro inesperado ao reportar obstáculo: $e',
        error: e,
        name: 'SupabaseObstacleRepositoryImpl',
      );
      return Left(ServerFailure('Erro inesperado ao reportar obstáculo: $e'));
    }
  }
}

