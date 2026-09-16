class RouteItem {
  final String id;
  final String sectorId;
  final String name;
  final String grade;
  final String routeType;
  final int boltCount;
  final double? heightMeters;
  final String? imgUrl;
  final String? description;
  final DateTime? createdAt;
  final String? sectorName;
  final String? cragName;

  const RouteItem({
    required this.id,
    required this.sectorId,
    required this.name,
    required this.grade,
    this.routeType = 'sport',
    this.boltCount = 0,
    this.heightMeters,
    this.imgUrl,
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

  factory RouteItem.fromJson(Map<String, dynamic> json) {
    String? sName;
    String? cName;

    // Handle nested Supabase join: sectors ( name, crags ( name ) )
    if (json['sectors'] is Map<String, dynamic>) {
      final sMap = json['sectors'] as Map<String, dynamic>;
      sName = sMap['name'] as String?;
      if (sMap['crags'] is Map<String, dynamic>) {
        final cMap = sMap['crags'] as Map<String, dynamic>;
        cName = cMap['name'] as String?;
      }
    }

    return RouteItem(
      id: json['id'] as String,
      sectorId: json['sector_id'] as String,
      name: json['name'] as String? ?? 'Unnamed Route',
      grade: json['grade'] as String? ?? '5c',
      routeType: json['route_type'] as String? ?? 'sport',
      boltCount: json['bolt_count'] as int? ?? 0,
      heightMeters: (json['height_meters'] as num?)?.toDouble(),
      imgUrl: json['img_url'] as String?,
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
      'bolt_count': boltCount,
      'height_meters': heightMeters,
      'img_url': imgUrl,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

