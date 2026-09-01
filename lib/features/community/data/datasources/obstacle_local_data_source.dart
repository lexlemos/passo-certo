import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

abstract class ObstacleLocalDataSource {
  Future<List<Map<String, dynamic>>> queryViewport(
    double minLat,
    double minLng,
    double maxLat,
    double maxLng,
  );
  Future<void> upsertAll(List<Map<String, dynamic>> obstacles);
  Future<void> markResolved(String id);
}

class ObstacleLocalDataSourceImpl implements ObstacleLocalDataSource {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final docsPath = await getApplicationDocumentsDirectory();
    final path = join(docsPath.path, 'passo_certo_obstacles.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE obstacles(
            id TEXT PRIMARY KEY,
            latitude REAL,
            longitude REAL,
            status TEXT,
            data TEXT
          )
        ''');
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> queryViewport(
    double minLat,
    double minLng,
    double maxLat,
    double maxLng,
  ) async {
    final db = await database;
    final maps = await db.query(
      'obstacles',
      where:
          'latitude >= ? AND latitude <= ? AND longitude >= ? AND longitude <= ? AND status != ?',
      whereArgs: [minLat, maxLat, minLng, maxLng, 'RESOLVED'],
    );
    return maps
        .map((row) => jsonDecode(row['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  @override
  Future<void> upsertAll(List<Map<String, dynamic>> obstacles) async {
    if (obstacles.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final obs in obstacles) {
      final id = obs['id'] as String;
      final lat = (obs['latitude'] as num).toDouble();
      final lng = (obs['longitude'] as num).toDouble();
      final status = obs['status'] as String?;

      batch.insert('obstacles', {
        'id': id,
        'latitude': lat,
        'longitude': lng,
        'status': status ?? 'ACTIVE',
        'data': jsonEncode(obs),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> markResolved(String id) async {
    final db = await database;
    await db.update(
      'obstacles',
      {'status': 'RESOLVED'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
