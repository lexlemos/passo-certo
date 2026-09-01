import '../../domain/entities/obstacle.dart';

/// Modelo de dados da camada de dados (Data Layer).
///
/// Estende [Obstacle] adicionando capacidades de serialização/desserialização
/// para o formato JSON do PostgreSQL (Supabase).
///
/// Convenção de nomenclatura:
/// - Banco (snake_case): `reporter_id`, `reported_at`, `updated_at`
/// - Dart (camelCase) : `reporterId`,  `reportedAt`,  `updatedAt`
class ObstacleModel extends Obstacle {
  /// Data/hora da última modificação do registro no banco.
  ///
  /// Corresponde à coluna `updated_at` (gerenciada pelo trigger `moddatetime`).
  /// Faz fallback para [reportedAt] em registros antigos que ainda não possuam
  /// a coluna populada.
  final DateTime updatedAt;

  const ObstacleModel({
    required super.id,
    required super.latitude,
    required super.longitude,
    required super.type,
    required super.description,
    required super.reportedAt,
    required super.upvotes,
    required super.reporterId,
    required this.updatedAt,
    super.severity,
    super.status,
  });

  // ─── Parsers de enum ──────────────────────────────────────────────────────

  /// Converte a string do banco (`'pothole'`, `'stairs'` …) para [ObstacleType].
  /// Valores desconhecidos fazem fallback para [ObstacleType.other].
  static ObstacleType _parseType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'pothole':
        return ObstacleType.pothole;
      case 'no_tactile_paving':
        return ObstacleType.noTactilePaving;
      case 'stairs':
        return ObstacleType.stairs;
      case 'blocked_sidewalk':
        return ObstacleType.blockedSidewalk;
      default:
        return ObstacleType.other;
    }
  }

  /// Converte a string do banco (`'warning'`, `'blocking'`) para [ObstacleSeverity].
  static ObstacleSeverity _parseSeverity(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'blocking':
        return ObstacleSeverity.blocking;
      default:
        return ObstacleSeverity.warning;
    }
  }

  /// Converte a string do banco (`'active'`, `'resolved'`) para [ObstacleStatus].
  static ObstacleStatus _parseStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'resolved':
        return ObstacleStatus.resolved;
      default:
        return ObstacleStatus.active;
    }
  }

  // ─── Desserialização ──────────────────────────────────────────────────────

  /// Constrói um [ObstacleModel] a partir de um mapa JSON vindo do Supabase
  /// ou do cache local.
  ///
  /// | Coluna Postgres   | Propriedade Dart | Tipo              |
  /// |-------------------|------------------|-------------------|
  /// | `id`              | id               | String (UUID)     |
  /// | `latitude`        | latitude         | double            |
  /// | `longitude`       | longitude        | double            |
  /// | `type`            | type             | ObstacleType enum |
  /// | `description`     | description      | String            |
  /// | `created_at`      | reportedAt       | DateTime (ISO8601)|
  /// | `updated_at`      | updatedAt        | DateTime (ISO8601)|
  /// | `upvotes`         | upvotes          | int               |
  /// | `reporter_id`     | reporterId       | String (UUID)     |
  /// | `severity`        | severity         | ObstacleSeverity  |
  /// | `status`          | status           | ObstacleStatus    |
  factory ObstacleModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at'] as String);

    // Fallback para `created_at` em registros antigos sem a coluna `updated_at`.
    final updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : createdAt;

    final lat = (json['latitude'] as num).toDouble();
    final lng = (json['longitude'] as num).toDouble();

    if (!lat.isFinite ||
        !lng.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      throw FormatException('Coordenada geográfica inválida: ($lat, $lng)');
    }

    return ObstacleModel(
      id: json['id'] as String,
      latitude: lat,
      longitude: lng,
      type: _parseType(json['type'] as String?),
      description: json['description'] as String? ?? '',
      reportedAt: createdAt,
      updatedAt: updatedAt,
      upvotes: json['upvotes'] as int? ?? 0,
      reporterId: json['reporter_id'] as String? ?? 'anonymous',
      severity: _parseSeverity(json['severity'] as String?),
      status: _parseStatus(json['status'] as String?),
    );
  }

  // ─── Serialização ─────────────────────────────────────────────────────────

  /// Serializa o modelo para o formato JSON.
  ///
  /// Usado tanto para INSERT no Supabase quanto para persistência no cache local.
  ///
  /// Notas:
  /// - `id` é incluído para permitir upserts; o banco usa-o como PK.
  /// - `created_at` / `updated_at` são enviados em UTC ISO-8601.
  /// - `upvotes` começa em 0 para novos registros.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'type': _typeToString(type),
      'description': description,
      'created_at': reportedAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'upvotes': upvotes,
      'reporter_id': reporterId,
      'severity': _severityToString(severity),
      'status': _statusToString(status),
    };
  }

  // ─── Serializers de enum ──────────────────────────────────────────────────

  static String _typeToString(ObstacleType type) {
    switch (type) {
      case ObstacleType.pothole:
        return 'POTHOLE';
      case ObstacleType.noTactilePaving:
        return 'NO_TACTILE_PAVING';
      case ObstacleType.stairs:
        return 'STAIRS';
      case ObstacleType.blockedSidewalk:
        return 'BLOCKED_SIDEWALK';
      case ObstacleType.other:
        return 'OTHER';
    }
  }

  static String _severityToString(ObstacleSeverity severity) {
    switch (severity) {
      case ObstacleSeverity.blocking:
        return 'BLOCKING';
      case ObstacleSeverity.warning:
        return 'WARNING';
    }
  }

  static String _statusToString(ObstacleStatus status) {
    switch (status) {
      case ObstacleStatus.resolved:
        return 'RESOLVED';
      case ObstacleStatus.active:
        return 'ACTIVE';
    }
  }
}
