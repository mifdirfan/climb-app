class HazardAlert {
  final String id;
  final String cragId;
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
    required this.cragId,
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
    return HazardAlert(
      id: json['id'] as String,
      cragId: json['crag_id'] as String,
      sectorId: json['sector_id'] as String,
      routeId: json['route_id'] as String?,
      userId: json['user_id'] as String?,
      sectorName: json['sectors']?['name'] as String?,
      routeName: json['routes']?['name'] as String?,
      hazardType: json['hazard_type'] as String,
      description: json['description'] as String,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crag_id': cragId,
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

