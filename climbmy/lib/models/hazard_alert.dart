class HazardAlert {
  final String id;
  final String sectorId;
  final String? routeId;
  final String? userId;
  final String hazardType;
  final String description;
  final String status;
  final DateTime? createdAt;
  final String? sectorName;
  final String? routeName;

  const HazardAlert({
    required this.id,
    required this.sectorId,
    this.routeId,
    this.userId,
    required this.hazardType,
    required this.description,
    this.status = 'active',
    this.createdAt,
    this.sectorName,
    this.routeName,
  });

  factory HazardAlert.fromJson(Map<String, dynamic> json) {
    String? sName;
    String? rName;

    if (json['sectors'] is Map<String, dynamic>) {
      sName = (json['sectors'] as Map<String, dynamic>)['name'] as String?;
    }
    if (json['routes'] is Map<String, dynamic>) {
      rName = (json['routes'] as Map<String, dynamic>)['name'] as String?;
    }

    return HazardAlert(
      id: json['id'] as String,
      sectorId: json['sector_id'] as String,
      routeId: json['route_id'] as String?,
      userId: json['user_id'] as String?,
      hazardType: json['hazard_type'] as String? ?? 'other',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      sectorName: sName,
      routeName: rName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sector_id': sectorId,
      'route_id': routeId,
      'user_id': userId,
      'hazard_type': hazardType,
      'description': description,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

