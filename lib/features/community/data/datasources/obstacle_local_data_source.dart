import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

/// Contrato da fonte de dados local para obstáculos.
///
/// Responsável por persistir e recuperar a lista de obstáculos em cache
/// e o timestamp da última sincronização bem-sucedida com o Supabase.
abstract class ObstacleLocalDataSource {
  /// Retorna a string JSON do cache local, ou `null` se o cache estiver vazio.
  String? getCachedObstaclesJson();

  /// Persiste a lista de obstáculos serializada como string JSON.
  Future<void> cacheObstaclesJson(String json);

  /// Retorna o [DateTime] da última sincronização bem-sucedida, ou `null`
  /// se nunca foi sincronizado (primeira execução).
  DateTime? getLastSyncTimestamp();

  /// Persiste o timestamp da última sincronização bem-sucedida.
  Future<void> saveLastSyncTimestamp(DateTime timestamp);
}

/// Implementação de [ObstacleLocalDataSource] usando [SharedPreferences].
///
/// Chaves utilizadas:
/// - `obstacles_cache` → JSON string (serialização de `List<Map<String, dynamic>>`)
/// - `last_sync_ts`    → ISO-8601 string do último sync bem-sucedido
class ObstacleLocalDataSourceImpl implements ObstacleLocalDataSource {
  static const String _cacheKey = 'obstacles_cache';
  static const String _timestampKey = 'last_sync_ts';
  static const String _logName = 'ObstacleLocalDataSource';

  final SharedPreferences sharedPreferences;

  const ObstacleLocalDataSourceImpl({required this.sharedPreferences});

  // ─── Leitura ──────────────────────────────────────────────────────────────

  @override
  String? getCachedObstaclesJson() {
    final cached = sharedPreferences.getString(_cacheKey);
    developer.log(
      cached != null
          ? 'Cache local encontrado (${cached.length} bytes).'
          : 'Cache local vazio — primeiro sync necessário.',
      name: _logName,
    );
    return cached;
  }

  @override
  DateTime? getLastSyncTimestamp() {
    final raw = sharedPreferences.getString(_timestampKey);
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (e) {
      developer.log(
        'Falha ao parsear last_sync_ts ("$raw"): $e — timestamp ignorado.',
        name: _logName,
      );
      return null;
    }
  }

  // ─── Escrita ──────────────────────────────────────────────────────────────

  @override
  Future<void> cacheObstaclesJson(String json) async {
    await sharedPreferences.setString(_cacheKey, json);
    developer.log(
      'Cache local atualizado (${json.length} bytes).',
      name: _logName,
    );
  }

  @override
  Future<void> saveLastSyncTimestamp(DateTime timestamp) async {
    final iso = timestamp.toUtc().toIso8601String();
    await sharedPreferences.setString(_timestampKey, iso);
    developer.log('last_sync_ts salvo: $iso', name: _logName);
  }
}

// ─── Helpers de Isolate ───────────────────────────────────────────────────────

/// Payload passado para o Isolate de mesclagem.
///
/// Empacota todos os dados primitivos/serializáveis necessários para que o
/// Isolate filho execute sem tocar em plugins de plataforma ou estado global.
class ObstacleMergePayload {
  /// String JSON do cache local (pode ser nula no primeiro sync).
  final String? cachedJson;

  /// Lista de maps vinda diretamente da resposta do Supabase.
  final List<Map<String, dynamic>> deltaRows;

  const ObstacleMergePayload({
    required this.cachedJson,
    required this.deltaRows,
  });
}

/// Resultado retornado pelo Isolate após a mesclagem.
class ObstacleMergeResult {
  /// Lista final de obstáculos ativos (já filtrados e mesclados).
  final List<Map<String, dynamic>> mergedRows;

  /// JSON serializado da lista mesclada — pronto para persistir no cache.
  final String mergedJson;

  const ObstacleMergeResult({
    required this.mergedRows,
    required this.mergedJson,
  });
}

/// Função pura executada dentro do [Isolate.run()].
///
/// Passos:
/// 1. Desserializa o cache local (se existir) → mapa indexado por ID.
/// 2. Aplica os registros do delta (novos e atualizados) sobrescrevendo por ID.
/// 3. Remove itens cujo `status` seja `'RESOLVED'` (soft-delete via status).
/// 4. Serializa a lista mesclada de volta para JSON e retorna o resultado.
///
/// Esta função é **pura**: não acessa plugins, singletons nem estado externo.
ObstacleMergeResult mergeObstaclesInIsolate(ObstacleMergePayload payload) {
  // Passo 1 — Desserializar cache local para mapa id → row.
  final Map<String, Map<String, dynamic>> index = {};

  if (payload.cachedJson != null) {
    try {
      final cached =
          (jsonDecode(payload.cachedJson!) as List<dynamic>)
              .cast<Map<String, dynamic>>();
      for (final row in cached) {
        final id = row['id'] as String?;
        if (id != null) index[id] = row;
      }
    } catch (_) {
      // Cache corrompido — descarta e parte do zero.
    }
  }

  // Passo 2 — Aplicar delta (novos e atualizados sobrescrevem o cache).
  for (final row in payload.deltaRows) {
    final id = row['id'] as String?;
    if (id != null) index[id] = row;
  }

  // Passo 3 — Filtrar itens com status RESOLVED (soft-delete).
  index.removeWhere(
    (_, row) =>
        (row['status'] as String?)?.toUpperCase() == 'RESOLVED',
  );

  // Passo 4 — Serializar resultado.
  final mergedRows = index.values.toList(growable: false);
  final mergedJson = jsonEncode(mergedRows);

  return ObstacleMergeResult(mergedRows: mergedRows, mergedJson: mergedJson);
}
