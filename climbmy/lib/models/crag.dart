/// Represents a grade tag in an indoor climbing gym's custom grading scale.
class GymGradeTag {
  final String label;
  final String? hex;
  final int? vMin;
  final int? vMax;

  const GymGradeTag({
    required this.label,
    this.hex,
    this.vMin,
    this.vMax,
  });

  factory GymGradeTag.fromJson(Map<String, dynamic> json) {
    return GymGradeTag(
      label: json['label'] as String? ?? '',
      hex: json['hex'] as String?,
      vMin: (json['v_min'] ?? json['vMin']) as int?,
      vMax: (json['v_max'] ?? json['vMax']) as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      if (hex != null) 'hex': hex,
      if (vMin != null) 'v_min': vMin,
      if (vMax != null) 'v_max': vMax,
    };
  }

  GymGradeTag copyWith({
    String? label,
    String? hex,
    int? vMin,
    int? vMax,
  }) {
    return GymGradeTag(
      label: label ?? this.label,
      hex: hex ?? this.hex,
      vMin: vMin ?? this.vMin,
      vMax: vMax ?? this.vMax,
    );
  }
}

/// Represents a climbing venue (either an indoor gym or outdoor crag) in Supabase.
class Crag {
  final String id;
  final String name;
  final String venueType; // 'indoor' | 'outdoor'
  final String state;

  // Indoor-specific attributes
  final String? address;
  final String? operatingHours;
  final String? phone;
  final String? instagram;
  final List<GymGradeTag> gradingScale;

  // Outdoor-specific attributes
  final String? approachNotes;
  final double? parkingLat;
  final double? parkingLong;
  final String? accessRestrictions;

  // System and UI attributes
  final DateTime? createdAt;
  final int routeCount;
  final List<String> styles;

  const Crag({
    required this.id,
    required this.name,
    required this.state,
    this.venueType = 'outdoor',
    this.address,
    this.operatingHours,
    this.phone,
    this.instagram,
    this.gradingScale = const [],
    this.approachNotes,
    this.parkingLat,
    this.parkingLong,
    String? accessRestrictions,
    String? access,
    this.createdAt,
    this.routeCount = 0,
    this.styles = const ['SPORT'],
  }) : accessRestrictions = accessRestrictions ?? access;

  bool get isIndoor => venueType == 'indoor';
  bool get isOutdoor => venueType == 'outdoor';
  String? get access => accessRestrictions;

  factory Crag.fromJson(Map<String, dynamic> json) {
    List<GymGradeTag> parsedGradingScale = [];
    if (json['grading_scale'] is List) {
      parsedGradingScale = (json['grading_scale'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => GymGradeTag.fromJson(item))
          .toList();
    }

    return Crag(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed Venue',
      venueType: json['venue_type'] as String? ?? 'outdoor',
      state: json['state'] as String? ?? 'Malaysia',
      address: json['address'] as String?,
      operatingHours: json['operating_hours'] as String?,
      phone: json['phone'] as String?,
      instagram: json['instagram'] as String?,
      gradingScale: parsedGradingScale,
      approachNotes: json['approach_notes'] as String?,
      parkingLat: (json['parking_lat'] as num?)?.toDouble(),
      parkingLong: (json['parking_long'] as num?)?.toDouble(),
      accessRestrictions: json['access_restrictions'] as String? ?? json['access'] as String?,
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
      'venue_type': venueType,
      'state': state,
      if (address != null) 'address': address,
      if (operatingHours != null) 'operating_hours': operatingHours,
      if (phone != null) 'phone': phone,
      if (instagram != null) 'instagram': instagram,
      'grading_scale': gradingScale.map((tag) => tag.toJson()).toList(),
      if (approachNotes != null) 'approach_notes': approachNotes,
      if (parkingLat != null) 'parking_lat': parkingLat,
      if (parkingLong != null) 'parking_long': parkingLong,
      if (accessRestrictions != null) 'access_restrictions': accessRestrictions,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  Crag copyWith({
    String? id,
    String? name,
    String? venueType,
    String? state,
    String? address,
    String? operatingHours,
    String? phone,
    String? instagram,
    List<GymGradeTag>? gradingScale,
    String? approachNotes,
    double? parkingLat,
    double? parkingLong,
    String? accessRestrictions,
    DateTime? createdAt,
    int? routeCount,
    List<String>? styles,
  }) {
    return Crag(
      id: id ?? this.id,
      name: name ?? this.name,
      venueType: venueType ?? this.venueType,
      state: state ?? this.state,
      address: address ?? this.address,
      operatingHours: operatingHours ?? this.operatingHours,
      phone: phone ?? this.phone,
      instagram: instagram ?? this.instagram,
      gradingScale: gradingScale ?? this.gradingScale,
      approachNotes: approachNotes ?? this.approachNotes,
      parkingLat: parkingLat ?? this.parkingLat,
      parkingLong: parkingLong ?? this.parkingLong,
      accessRestrictions: accessRestrictions ?? this.accessRestrictions,
      createdAt: createdAt ?? this.createdAt,
      routeCount: routeCount ?? this.routeCount,
      styles: styles ?? this.styles,
    );
  }
}
