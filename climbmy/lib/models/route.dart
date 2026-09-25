/// Represents a climbing route or boulder problem (public.routes) in the simplified boulder-first schema.
class Route {
  final String id;
  final String cragId; 
  final String? sectorId; 
  final String name;
  final String grade;
  final String routeType; // 'boulder' 
  final bool isActive;
  final String? description;
  final String? firstAscent;
  final DateTime? createdAt;
  final String? imageUrl;
  
  // Joined display attributes
  final String? sectorName;
  final String? cragName;
  

  const Route({
    required this.id,
    required this.cragId, 
    this.sectorId, 
    required this.name,
    required this.grade,
    this.routeType = 'boulder',
    this.isActive = true,
    this.description,
    this.firstAscent,
    this.createdAt,
    this.sectorName,
    this.cragName,
    this.imageUrl,
  });

  String get locationSubtitle {
    if (sectorName != null && cragName != null) {
      return '$sectorName, $cragName';
    } else if (cragName != null) {
      return cragName!;
    } else if (sectorName != null) {
      return sectorName!;
    }
    return 'Outdoor Crag';
  }

  factory Route.fromJson(Map<String, dynamic> json) {
    String? sName;
    String? cName;
    String? cId = json['crag_id'] as String?;

    // Handle joined relations if available: sectors ( name, crag_id, crags ( name ) )
    if (json['sectors'] is Map<String, dynamic>) {
      final sMap = json['sectors'] as Map<String, dynamic>;
      sName = sMap['name'] as String?;
      cId ??= sMap['crag_id'] as String?;
      if (sMap['crags'] is Map<String, dynamic>) {
        cName = (sMap['crags'] as Map<String, dynamic>)['name'] as String?;
      }
    }

    if (json['crags'] is Map<String, dynamic>) {
      cName ??= (json['crags'] as Map<String, dynamic>)['name'] as String?;
    }

    return Route(
      id: json['id'] as String,
      cragId: cId ?? (json['crag_id'] as String? ?? ''),
      sectorId: json['sector_id'] as String?,
      name: json['name'] as String? ?? 'Unnamed Boulder',
      grade: json['grade'] as String? ?? 'V0',
      routeType: json['route_type'] as String? ?? 'boulder',
      isActive: json['is_active'] as bool? ?? true,
      description: json['description'] as String?,
      firstAscent: json['first_ascent'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      sectorName: sName,
      cragName: cName,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crag_id': cragId,
      if (sectorId != null) 'sector_id': sectorId,
      'name': name,
      'grade': grade,
      'route_type': routeType,
      'is_active': isActive,
      if (description != null) 'description': description,
      if (firstAscent != null) 'first_ascent': firstAscent,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  Route copyWith({
    String? id,
    String? cragId,
    String? sectorId,
    String? name,
    String? grade,
    String? routeType,
    bool? isActive,
    String? description,
    String? firstAscent,
    DateTime? createdAt,
    String? sectorName,
    String? cragName,
    String? imageUrl,
  }) {
    return Route(
      id: id ?? this.id,
      cragId: cragId ?? this.cragId,
      sectorId: sectorId ?? this.sectorId,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      routeType: routeType ?? this.routeType,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      firstAscent: firstAscent ?? this.firstAscent,
      createdAt: createdAt ?? this.createdAt,
      sectorName: sectorName ?? this.sectorName,
      cragName: cragName ?? this.cragName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

typedef RouteItem = Route;