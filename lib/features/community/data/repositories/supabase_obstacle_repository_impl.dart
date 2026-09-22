import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/obstacle.dart';
import '../../domain/repositories/obstacle_repository.dart';
import '../datasources/obstacle_local_data_source.dart';
import '../models/obstacle_model.dart';

/// Implementação real do [ObstacleRepository] consumindo o Supabase (PostgreSQL)
/// com suporte a **Delta Sync**, **cache local** e **write-through** via
/// [ObstacleLocalDataSource].
///
/// ## Estratégia de sincronização (leitura)
///
/// | Situação               | Comportamento                                          |
/// |------------------------|--------------------------------------------------------|
/// | Primeiro sync          | Fetch completo; salva cache + timestamp.               |
/// | Syncs subsequentes     | Query filtrada por `updated_at >= lastSyncTs`.         |
/// | Supabase inacessível   | Fallback silencioso retornando o cache local.          |
///
/// ## Write-through (mutações)
///
/// Toda operação de escrita bem-sucedida atualiza o cache local imediatamente,
/// sem aguardar o próximo ciclo de Delta Sync. Isso garante que o mapa reflita
/// as mudanças instantaneamente, mesmo sem nova chamada de rede.
///
/// | Mutação           | Comportamento no cache                                   |
/// |-------------------|----------------------------------------------------------|
/// | `reportObstacle`  | Insere o novo obstáculo no topo do cache.                |
/// | `deleteObstacle`  | Remove o obstáculo do cache pelo ID.                     |
///
/// ## Threading
///
/// - **Leitura** (`getObstacles`): deserialização e mesclagem em [Isolate.run].
/// - **Escrita** (mutações): operações de cache na main thread — coleções de
///   centenas de itens, sem risco de jank.
///
/// ## Design decisions
///
/// - [SupabaseClient] e [ObstacleLocalDataSource] injetados via construtor
///   (testáveis, sem acoplamento estático).
/// - A leitura do SharedPreferences ocorre **antes** do [Isolate.run] pois
///   plugins de plataforma não são acessíveis a partir de Isolates filhos.
/// - O método privado [_updateLocalCacheWithMutation] centraliza toda a
///   lógica de leitura → transformação → escrita do cache nas mutações,
///   eliminando duplicação entre os métodos de escrita.
class SupabaseObstacleRepositoryImpl implements ObstacleRepository {
  final SupabaseClient supabaseClient;
  final ObstacleLocalDataSource localDataSource;

  static const String _logName = 'SupabaseObstacleRepositoryImpl';

  const SupabaseObstacleRepositoryImpl({
    required this.supabaseClient,
    required this.localDataSource,
  });

  // ─── Leitura ──────────────────────────────────────────────────────────────

  /// Retorna os obstáculos ativos usando Delta Sync + cache local.
  ///
  /// Fluxo:
  /// 1. Lê o `last_sync_timestamp` e o JSON do cache (main isolate).
  /// 2. Consulta o Supabase:
  ///    - Se `last_sync_timestamp` for nulo → fetch completo.
  ///    - Caso contrário → apenas registros com `updated_at >= timestamp`.
  /// 3. Mescla cache + delta dentro de um [Isolate.run] (background).
  /// 4. Persiste o resultado e atualiza o timestamp (main isolate).
  /// 5. Em caso de falha de rede → fallback silencioso para o cache local.
  @override
  Future<Either<Failure, List<Obstacle>>> getObstacles() async {
    // ── Passo 1: Ler estado do cache ANTES de entrar no Isolate ──────────────
    // SharedPreferences não é acessível dentro de Isolates filhos.
    final lastSyncTs = localDataSource.getLastSyncTimestamp();
    final cachedJson = localDataSource.getCachedObstaclesJson();

    developer.log(
      lastSyncTs != null
          ? 'Delta Sync — buscando registros atualizados após $lastSyncTs.'
          : 'Primeiro sync — buscando todos os obstáculos.',
      name: _logName,
    );

    // ── Passo 2: Query no Supabase (delta ou full) ────────────────────────
    List<Map<String, dynamic>> deltaRows;
    try {
      final query = supabaseClient.from('obstacles').select();

      final response = lastSyncTs != null
          ? await query.gte(
              'updated_at',
              lastSyncTs.toUtc().toIso8601String(),
            )
          : await query;

      deltaRows =
          (response as List<dynamic>).cast<Map<String, dynamic>>();

      developer.log(
        '${deltaRows.length} registro(s) recebido(s) do Supabase.',
        name: _logName,
      );
    } catch (e) {
      // ── Fallback offline: Supabase inacessível ────────────────────────
      developer.log(
        'Falha na chamada ao Supabase: $e\n'
        'Retornando cache local como fallback offline.',
        name: _logName,
      );
      return _obstaclesFromCacheOrEmpty(cachedJson);
    }

    // ── Passo 3: Mesclagem em background (Isolate) ────────────────────────
    final payload = ObstacleMergePayload(
      cachedJson: cachedJson,
      deltaRows: deltaRows,
    );

    final ObstacleMergeResult mergeResult;
    try {
      mergeResult = await Isolate.run(() => mergeObstaclesInIsolate(payload));
    } catch (e) {
      developer.log(
        'Erro no Isolate de mesclagem: $e\n'
        'Retornando cache local como fallback.',
        name: _logName,
      );
      return _obstaclesFromCacheOrEmpty(cachedJson);
    }

    // ── Passo 4: Persistir cache + timestamp (main isolate) ───────────────
    try {
      await localDataSource.cacheObstaclesJson(mergeResult.mergedJson);
      await localDataSource.saveLastSyncTimestamp(DateTime.now());
    } catch (e) {
      // Falha no cache não impede o retorno dos dados — apenas logamos.
      developer.log(
        'Aviso: falha ao persistir cache local: $e',
        name: _logName,
      );
    }

    // ── Passo 5: Deserializar resultado final para entidades de domínio ───
    try {
      final obstacles = mergeResult.mergedRows
          .map((row) => ObstacleModel.fromJson(row))
          .toList(growable: false);

      developer.log(
        '${obstacles.length} obstáculo(s) ativo(s) retornados.',
        name: _logName,
      );

      return Right(obstacles);
    } catch (e) {
      return Left(
        ServerFailure('Erro ao deserializar obstáculos: $e'),
      );
    }
  }

  // ─── Mutações ─────────────────────────────────────────────────────────────

  /// Persiste um novo obstáculo na tabela `obstacles` e atualiza o cache local.
  ///
  /// **Write-through**: após confirmação do Supabase, o novo obstáculo é
  /// inserido imediatamente no cache local pelo método
  /// [_updateLocalCacheWithMutation], garantindo que o próximo acesso ao mapa
  /// reflita a mudança sem necessidade de um novo pull da rede.
  ///
  /// O [Obstacle.id] recebido deve ser um UUID v4 gerado no cliente
  /// (via pacote `uuid`) para garantir idempotência e rastreabilidade local.
  ///
  /// `reported_at` é sempre enviado em UTC para consistência com `timestamptz`
  /// do PostgreSQL, independente do timezone do dispositivo do usuário.
  @override
  Future<Either<Failure, void>> reportObstacle(Obstacle obstacle) async {
    developer.log(
      'Iniciando inserção de obstáculo. ID: ${obstacle.id}, '
      'Tipo: ${obstacle.type}',
      name: _logName,
    );
    try {
      final model = ObstacleModel(
        id: obstacle.id,
        latitude: obstacle.latitude,
        longitude: obstacle.longitude,
        type: obstacle.type,
        description: obstacle.description,
        reportedAt: obstacle.reportedAt,
        updatedAt: obstacle.reportedAt,
        upvotes: obstacle.upvotes,
        reporterId: obstacle.reporterId,
        severity: obstacle.severity,
        status: obstacle.status,
      );

      await supabaseClient.from('obstacles').insert(model.toJson()).select();

      developer.log(
        'Inserção de obstáculo concluída com sucesso!',
        name: _logName,
      );

      // ── Write-through: insere no cache local imediatamente ────────────
      await _updateLocalCacheWithMutation(
        logTag: 'reportObstacle',
        transform: (index) {
          index[model.id] = model.toJson();
          developer.log(
            'Cache write-through: obstáculo ${model.id} inserido.',
            name: _logName,
          );
        },
      );

      return const Right(null);
    } on PostgrestException catch (e) {
      developer.log(
        'PostgrestException ao reportar obstáculo: ${e.message}',
        error: e,
        name: _logName,
      );
      return Left(ServerFailure('Falha ao reportar obstáculo: ${e.message}'));
    } catch (e) {
      developer.log(
        'Erro inesperado ao reportar obstáculo: $e',
        error: e,
        name: _logName,
      );
      return Left(ServerFailure('Erro inesperado ao reportar obstáculo: $e'));
    }
  }

  /// Marca um obstáculo existente como `RESOLVED` (soft-delete) e remove-o
  /// do cache local imediatamente.
  ///
  /// **Write-through**: após confirmação do Supabase, o item é removido do
  /// cache via [_updateLocalCacheWithMutation], garantindo que o mapa pare
  /// de renderizá-lo sem aguardar o próximo ciclo de Delta Sync.
  ///
  /// O obstáculo não é removido fisicamente do banco; apenas seu `status` é
  /// atualizado para `'RESOLVED'`.
  @override
  Future<Either<Failure, void>> deleteObstacle(String obstacleId) async {
    developer.log(
      'Iniciando exclusão (soft-delete) do obstáculo. ID: $obstacleId',
      name: _logName,
    );
    try {
      await supabaseClient
          .from('obstacles')
          .update({'status': 'RESOLVED'})
          .eq('id', obstacleId);

      developer.log(
        'Obstáculo marcado como RESOLVED com sucesso!',
        name: _logName,
      );

      // ── Write-through: remove do cache local imediatamente ────────────
      await _updateLocalCacheWithMutation(
        logTag: 'deleteObstacle',
        transform: (index) {
          index.remove(obstacleId);
          developer.log(
            'Cache write-through: obstáculo $obstacleId removido.',
            name: _logName,
          );
        },
      );

      return const Right(null);
    } on PostgrestException catch (e) {
      developer.log(
        'PostgrestException ao excluir obstáculo: ${e.message}',
        error: e,
        name: _logName,
      );
      return Left(ServerFailure('Falha ao excluir obstáculo: ${e.message}'));
    } catch (e) {
      developer.log(
        'Erro inesperado ao excluir obstáculo: $e',
        error: e,
        name: _logName,
      );
      return Left(ServerFailure('Erro inesperado ao excluir obstáculo: $e'));
    }
  }

  // ─── Helpers privados ─────────────────────────────────────────────────────

  /// Lê o cache local, aplica uma transformação e grava o resultado.
  ///
  /// Este método centraliza o padrão **leitura → transformação → escrita**
  /// compartilhado por todas as operações de mutação, eliminando duplicação
  /// de código e garantindo que a atualização do cache seja sempre feita
  /// de forma consistente.
  ///
  /// O parâmetro [transform] recebe o índice atual do cache
  /// (`Map<id, row>`) e deve modificá-lo in-place. Itens com
  /// `status == 'RESOLVED'` são filtrados automaticamente antes da
  /// serialização.
  ///
  /// [logTag] é usado para identificar o contexto nos logs.
  ///
  /// Falhas nesta operação são logadas, mas **nunca relançadas** — a operação
  /// principal (Supabase) já foi bem-sucedida e o estado será corrigido no
  /// próximo Delta Sync.
  Future<void> _updateLocalCacheWithMutation({
    required String logTag,
    required void Function(Map<String, Map<String, dynamic>> index) transform,
  }) async {
    try {
      // 1. Ler cache atual e construir índice id → row.
      final cachedJson = localDataSource.getCachedObstaclesJson();
      final Map<String, Map<String, dynamic>> index = {};

      if (cachedJson != null && cachedJson.isNotEmpty) {
        final rawList =
            (jsonDecode(cachedJson) as List<dynamic>)
                .cast<Map<String, dynamic>>();
        for (final row in rawList) {
          final id = row['id'] as String?;
          if (id != null) index[id] = row;
        }
      }

      // 2. Aplicar a transformação específica da mutação.
      transform(index);

      // 3. Filtrar RESOLVED (garante consistência mesmo que o caller não filtre).
      index.removeWhere(
        (_, row) =>
            (row['status'] as String?)?.toUpperCase() == 'RESOLVED',
      );

      // 4. Serializar e persistir.
      final updatedJson = jsonEncode(index.values.toList(growable: false));
      await localDataSource.cacheObstaclesJson(updatedJson);

      developer.log(
        '[$logTag] Cache local atualizado: ${index.length} item(s) ativos.',
        name: _logName,
      );
    } catch (e) {
      // Falha no cache write-through é não-fatal: o Delta Sync corrigirá
      // no próximo getObstacles().
      developer.log(
        '[$logTag] Aviso: falha ao atualizar cache local: $e',
        name: _logName,
      );
    }
  }

  /// Deserializa o [cachedJson] e retorna um [Right] com a lista de obstáculos.
  ///
  /// Retorna [Right([])] se o cache estiver vazio ou corrompido — nunca lança.
  Either<Failure, List<Obstacle>> _obstaclesFromCacheOrEmpty(
    String? cachedJson,
  ) {
    if (cachedJson == null || cachedJson.isEmpty) {
      developer.log('Cache vazio — retornando lista vazia.', name: _logName);
      return const Right([]);
    }
    try {
      final rawList =
          (jsonDecode(cachedJson) as List<dynamic>)
              .cast<Map<String, dynamic>>();

      final obstacles = rawList
          .map((row) => ObstacleModel.fromJson(row))
          .toList(growable: false);

      developer.log(
        'Fallback offline: ${obstacles.length} obstáculo(s) do cache.',
        name: _logName,
      );
      return Right(obstacles);
    } catch (e) {
      developer.log(
        'Cache corrompido — retornando lista vazia. Erro: $e',
        name: _logName,
      );
      return const Right([]);
    }
  }
}
