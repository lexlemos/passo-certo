import '../../domain/entities/place.dart';

/// Modelo de dados da camada de dados (Data Layer).
///
/// Estende [Place] adicionando a capacidade de desserialização a partir
/// do JSON retornado pela tabela `places` do Supabase (PostgreSQL).
///
/// Separar o modelo da entidade segue o princípio de Responsabilidade Única
/// (SRP): a entidade carrega regras de negócio; o modelo, o contrato de I/O.
class PlaceModel extends Place {
  const PlaceModel({
    required super.name,
    required super.latitude,
    required super.longitude,
    super.searchTerms,
    super.category,
    super.floor,
    super.isAccessible,
  });

  // ─── Desserialização ──────────────────────────────────────────────────────

  /// Constrói um [PlaceModel] a partir de um mapa JSON vindo do Supabase.
  ///
  /// Campos do banco → propriedades da entidade:
  /// | Coluna Postgres       | Propriedade Dart     | Tipo              |
  /// |-----------------------|----------------------|-------------------|
  /// | `name`                | name                 | String            |
  /// | `latitude`            | latitude             | double            |
  /// | `longitude`           | longitude            | double            |
  /// | `search_terms`        | searchTerms          | `List<String>`    |
  /// | `category`            | category             | String            |
  /// | `floor`               | floor                | int               |
  /// | `is_accessible`       | isAccessible         | bool              |
  ///
  /// O cast `List<String>.from(...)` é O(n) mas inevitável: o Supabase retorna
  /// arrays Postgres como `List<dynamic>`. Não há loop adicional — `.from` usa
  /// iteração interna nativa do SDK do Dart, sem alocações intermediárias.
  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      searchTerms: List<String>.from(json['search_terms'] as List? ?? const []),
      category: json['category'] as String? ?? '',
      floor: json['floor'] as int? ?? 0,
      isAccessible: json['is_accessible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'search_terms': searchTerms,
      'category': category,
      'floor': floor,
      'is_accessible': isAccessible,
    };
  }
}
