/// Represents an outdoor route tick / ascent log in Supabase (public.ticks).
class Tick {
  final String id;
  final String userId;
  final String routeId;
  final String tickType; // 'flash' | 'send' | 'onsight' | 'dab' | 'repeat' | 'project'
  final String? notes;
  final DateTime climbedAt;
  final DateTime? createdAt;

  // Joined attributes from public.routes, public.sectors, and public.crags
  final String? routeName;
  final String? routeGrade;
  final String? routeType;
  final String? sectorName;
  final String? cragName;
  final String? userDisplayName;

  const Tick({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.tickType,
    this.notes,
    required this.climbedAt,
    this.createdAt,
    this.routeName,
    this.routeGrade,
    this.routeType,
    this.sectorName,
    this.cragName,
    this.userDisplayName,
  });

  /// Returns true if this tick counts as a completed clean ascent.
  bool get isCleanSend {
    final lower = tickType.toLowerCase();
    return lower == 'flash' || lower == 'send' || lower == 'onsight' || lower == 'repeat';
  }

  /// Human-readable title for tick type pill.
  String get styleDisplayName {
    switch (tickType.toLowerCase()) {
      case 'onsight':
        return 'Onsight';
      case 'flash':
        return 'Flash';
      case 'send':
        return 'Redpoint / Send';
      case 'repeat':
        return 'Repeat';
      case 'dab':
        return 'Dab / Attempt';
      case 'project':
        return 'Project';
      default:
        return tickType.toUpperCase();
    }
  }

  factory Tick.fromJson(Map<String, dynamic> json) {
    String? rName;
    String? rGrade;
    String? rType;
    String? sName;
    String? cName;
    String? uName;

    if (json['routes'] is Map<String, dynamic>) {
      final rMap = json['routes'] as Map<String, dynamic>;
      rName = rMap['name'] as String?;
      rGrade = rMap['grade'] as String?;
      rType = rMap['route_type'] as String?;

      if (rMap['sectors'] is Map<String, dynamic>) {
        final sMap = rMap['sectors'] as Map<String, dynamic>;
        sName = sMap['name'] as String?;
        if (sMap['crags'] is Map<String, dynamic>) {
          cName = (sMap['crags'] as Map<String, dynamic>)['name'] as String?;
        }
      }
    }

    if (json['profiles'] is Map<String, dynamic>) {
      final pMap = json['profiles'] as Map<String, dynamic>;
      uName = (pMap['display_name'] ?? pMap['username']) as String?;
    }

    DateTime parsedClimbedAt;
    if (json['climbed_at'] != null) {
      parsedClimbedAt =
          DateTime.tryParse(json['climbed_at'] as String) ?? DateTime.now();
    } else {
      parsedClimbedAt = DateTime.now();
    }

    return Tick(
      id: json['id'] as String,
      userId: (json['user_id'] ?? json['userId']) as String? ?? '',
      routeId: (json['route_id'] ?? json['routeId']) as String? ?? '',
      tickType: (json['tick_type'] ?? json['tickType']) as String? ?? 'send',
      notes: json['notes'] as String?,
      climbedAt: parsedClimbedAt,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      routeName: rName ?? json['route_name'] as String?,
      routeGrade: rGrade ?? json['route_grade'] as String?,
      routeType: rType ?? json['route_type'] as String?,
      sectorName: sName ?? json['sector_name'] as String?,
      cragName: cName ?? json['crag_name'] as String?,
      userDisplayName: uName ?? json['user_display_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'route_id': routeId,
      'tick_type': tickType,
      if (notes != null) 'notes': notes,
      'climbed_at':
          '${climbedAt.year.toString().padLeft(4, '0')}-${climbedAt.month.toString().padLeft(2, '0')}-${climbedAt.day.toString().padLeft(2, '0')}',
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  Tick copyWith({
    String? id,
    String? userId,
    String? routeId,
    String? tickType,
    String? notes,
    DateTime? climbedAt,
    DateTime? createdAt,
    String? routeName,
    String? routeGrade,
    String? routeType,
    String? sectorName,
    String? cragName,
    String? userDisplayName,
  }) {
    return Tick(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      routeId: routeId ?? this.routeId,
      tickType: tickType ?? this.tickType,
      notes: notes ?? this.notes,
      climbedAt: climbedAt ?? this.climbedAt,
      createdAt: createdAt ?? this.createdAt,
      routeName: routeName ?? this.routeName,
      routeGrade: routeGrade ?? this.routeGrade,
      routeType: routeType ?? this.routeType,
      sectorName: sectorName ?? this.sectorName,
      cragName: cragName ?? this.cragName,
      userDisplayName: userDisplayName ?? this.userDisplayName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tick &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          routeId == other.routeId &&
          tickType == other.tickType &&
          climbedAt == other.climbedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      routeId.hashCode ^
      tickType.hashCode ^
      climbedAt.hashCode;
}

