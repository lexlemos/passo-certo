import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/obstacle.dart';
import '../../domain/repositories/obstacle_repository.dart';
import '../datasources/obstacle_local_data_source.dart';
import '../models/obstacle_model.dart';

class SupabaseObstacleRepositoryImpl implements ObstacleRepository {
  final SupabaseClient supabaseClient;
  final ObstacleLocalDataSource localDataSource;

  static const String _logName = 'SupabaseObstacleRepositoryImpl';

  const SupabaseObstacleRepositoryImpl({
    required this.supabaseClient,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Obstacle>>> getObstaclesInViewport(
    double minLat,
    double minLng,
    double maxLat,
    double maxLng,
  ) async {
    developer.log('Buscando obstáculos na viewport', name: _logName);

    try {
      final response = await supabaseClient.rpc(
        'active_obstacles_in_bbox',
        params: {
          'min_lat': minLat,
          'min_lng': minLng,
          'max_lat': maxLat,
          'max_lng': maxLng,
        },
      );

      final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();

      // Isolate para parsing pesado em background
      final obstacles = await Isolate.run(
        () => rows
            .where((row) => _hasValidCoordinates(row))
            .map(ObstacleModel.fromJson)
            .toList(growable: false),
      );

      // Atualiza o cache local offline de forma assíncrona
      localDataSource.upsertAll(rows).catchError((e) {
        developer.log(
          'Aviso: falha ao persistir cache local: $e',
          name: _logName,
        );
      });

      developer.log(
        '${obstacles.length} obstáculo(s) retornado(s)',
        name: _logName,
      );
      return Right(obstacles);
    } catch (e) {
      developer.log('Falha na chamada ao Supabase: $e', name: _logName);

      // Fallback offline via SQLite
      try {
        final cachedRows = await localDataSource.queryViewport(
          minLat,
          minLng,
          maxLat,
          maxLng,
        );
        final obstacles = await Isolate.run(
          () => cachedRows.map(ObstacleModel.fromJson).toList(growable: false),
        );
        developer.log(
          'Fallback offline: ${obstacles.length} obstáculo(s)',
          name: _logName,
        );
        return Right(obstacles);
      } catch (cacheErr) {
        developer.log('Falha no fallback: $cacheErr', name: _logName);
        return const Right([]);
      }
    }
  }

  static bool _hasValidCoordinates(Map<String, dynamic> row) {
    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return false;
    return lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  @override
  Future<Either<Failure, void>> reportObstacle(Obstacle obstacle) async {
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

      final inserted = await supabaseClient
          .from('obstacles')
          .insert(model.toJson())
          .select();

      // Write-through cache
      if (inserted.isNotEmpty) {
        await localDataSource.upsertAll(inserted);
      }

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Falha ao reportar obstáculo: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado ao reportar obstáculo: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteObstacle(String obstacleId) async {
    try {
      await supabaseClient
          .from('obstacles')
          .update({'status': 'RESOLVED'})
          .eq('id', obstacleId);

      // Write-through cache
      await localDataSource.markResolved(obstacleId);

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Falha ao excluir obstáculo: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado ao excluir obstáculo: $e'));
    }
  }
}
