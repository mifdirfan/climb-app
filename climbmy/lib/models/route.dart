/// Represents a climbing route or boulder problem (public.routes) in the simplified boulder-first schema.
class Route {
  final String id;
  final String sectorId;
  final String name;
  final String grade;
  final String routeType; // 'boulder' | 'sport' | 'trad'
  final bool isActive;
  final String? description;
  final DateTime? createdAt;
  final String? sectorName;
  final String? cragName;

  const Route({
    required this.id,
    required this.sectorId,
    required this.name,
    required this.grade,
    this.routeType = 'boulder',
    this.isActive = true,
    this.description,
    this.createdAt,
    this.sectorName,
    this.cragName,
  });

  String get locationSubtitle {
    if (sectorName != null && cragName != null) {
      return '$sectorName, $cragName';
    } else if (sectorName != null) {
      return sectorName!;
    } else if (cragName != null) {
      return cragName!;
    }
    return 'Damai Wall, Batu Caves';
  }

  factory Route.fromJson(Map<String, dynamic> json) {
    String? sName;
    String? cName;

    // Handle joined relations if available: sectors ( name, crags ( name ) )
    if (json['sectors'] is Map<String, dynamic>) {
      final sMap = json['sectors'] as Map<String, dynamic>;
      sName = sMap['name'] as String?;
      if (sMap['crags'] is Map<String, dynamic>) {
        final cMap = sMap['crags'] as Map<String, dynamic>;
        cName = cMap['name'] as String?;
      }
    }

    return Route(
      id: json['id'] as String,
      sectorId: json['sector_id'] as String,
      name: json['name'] as String? ?? 'Unnamed Route',
      grade: json['grade'] as String? ?? 'V0',
      routeType: json['route_type'] as String? ?? 'boulder',
      isActive: json['is_active'] as bool? ?? true,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      sectorName: sName,
      cragName: cName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sector_id': sectorId,
      'name': name,
      'grade': grade,
      'route_type': routeType,
      'is_active': isActive,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  Route copyWith({
    String? id,
    String? sectorId,
    String? name,
    String? grade,
    String? routeType,
    bool? isActive,
    String? description,
    DateTime? createdAt,
    String? sectorName,
    String? cragName,
  }) {
    return Route(
      id: id ?? this.id,
      sectorId: sectorId ?? this.sectorId,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      routeType: routeType ?? this.routeType,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      sectorName: sectorName ?? this.sectorName,
      cragName: cragName ?? this.cragName,
    );
  }
}

/// Type alias for backward compatibility with RouteItem references.
typedef RouteItem = Route;

