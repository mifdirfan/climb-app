/// Represents an outdoor climbing sector / wall in Supabase (public.sectors).
class Sector {
  final String id;
  final String cragId;
  final String name;
  final String? description;
  final DateTime? createdAt;

  // Joined / computed attributes
  final String? cragName;
  final int routeCount;

  const Sector({
    required this.id,
    required this.cragId,
    required this.name,
    this.description,
    this.createdAt,
    this.cragName,
    this.routeCount = 0,
  });

  factory Sector.fromJson(Map<String, dynamic> json) {
    String? cName;
    if (json['crags'] is Map<String, dynamic>) {
      cName = (json['crags'] as Map<String, dynamic>)['name'] as String?;
    }

    return Sector(
      id: json['id'] as String,
      cragId: (json['crag_id'] ?? json['cragId']) as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Sector',
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      cragName: cName ?? json['crag_name'] as String?,
      routeCount: (json['route_count'] ?? json['routes_count'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crag_id': cragId,
      'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  Sector copyWith({
    String? id,
    String? cragId,
    String? name,
    String? description,
    DateTime? createdAt,
    String? cragName,
    int? routeCount,
  }) {
    return Sector(
      id: id ?? this.id,
      cragId: cragId ?? this.cragId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      cragName: cragName ?? this.cragName,
      routeCount: routeCount ?? this.routeCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sector &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          cragId == other.cragId &&
          name == other.name &&
          description == other.description;

  @override
  int get hashCode =>
      id.hashCode ^ cragId.hashCode ^ name.hashCode ^ description.hashCode;
}

