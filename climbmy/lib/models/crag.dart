class Crag {
  final String id;
  final String name;
  final String state;
  final String? approachNotes;
  final double? parkingLat;
  final double? parkingLong;
  final String? access;
  final DateTime? createdAt;
  final int routeCount;
  final List<String> styles;

  const Crag({
    required this.id,
    required this.name,
    required this.state,
    this.approachNotes,
    this.parkingLat,
    this.parkingLong,
    this.access,
    this.createdAt,
    this.routeCount = 0,
    this.styles = const ['SPORT'],
  });

  factory Crag.fromJson(Map<String, dynamic> json) {
    return Crag(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed Crag',
      state: json['state'] as String? ?? 'Malaysia',
      approachNotes: json['approach_notes'] as String?,
      parkingLat: (json['parking_lat'] as num?)?.toDouble(),
      parkingLong: (json['parking_long'] as num?)?.toDouble(),
      access: json['access'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      routeCount: json['route_count'] as int? ?? (json['routes_count'] as int? ?? 0),
      styles: (json['styles'] as List<dynamic>?)
              ?.map((e) => e.toString().toUpperCase())
              .toList() ??
          const ['SPORT'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'approach_notes': approachNotes,
      'parking_lat': parkingLat,
      'parking_long': parkingLong,
      'access': access,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

