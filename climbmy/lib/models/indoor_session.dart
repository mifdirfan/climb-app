/// Represents an indoor climbing gym session logged by a user (public.indoor_sessions).
class IndoorSession {
  final String id;
  final String userId;
  final String gymId;
  final DateTime sessionDate;
  final int? durationMinutes;
  final String? feltGrade; // 'easy' | 'average' | 'hard' | 'limit'
  final int? rating; // 1 to 5
  final String? notes;
  final Map<String, int> gradeTallies;
  final DateTime? createdAt;
  final String? gymName; // Optional joined gym name from public.crags

  const IndoorSession({
    required this.id,
    required this.userId,
    required this.gymId,
    required this.sessionDate,
    this.durationMinutes,
    this.feltGrade,
    this.rating,
    this.notes,
    this.gradeTallies = const {},
    this.createdAt,
    this.gymName,
  });

  factory IndoorSession.fromJson(Map<String, dynamic> json) {
    Map<String, int> tallies = {};
    if (json['grade_tallies'] is Map) {
      (json['grade_tallies'] as Map).forEach((key, value) {
        if (value is num) {
          tallies[key.toString()] = value.toInt();
        }
      });
    }

    DateTime parsedDate;
    if (json['session_date'] != null) {
      parsedDate = DateTime.tryParse(json['session_date'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    String? parsedGymName;
    if (json['crags'] is Map<String, dynamic>) {
      parsedGymName = (json['crags'] as Map<String, dynamic>)['name'] as String?;
    }

    return IndoorSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      gymId: json['gym_id'] as String,
      sessionDate: parsedDate,
      durationMinutes: json['duration_minutes'] as int?,
      feltGrade: json['felt_grade'] as String?,
      rating: json['rating'] as int?,
      notes: json['notes'] as String?,
      gradeTallies: tallies,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      gymName: parsedGymName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'gym_id': gymId,
      'session_date':
          '${sessionDate.year.toString().padLeft(4, '0')}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}',
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (feltGrade != null) 'felt_grade': feltGrade,
      if (rating != null) 'rating': rating,
      if (notes != null) 'notes': notes,
      'grade_tallies': gradeTallies,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  IndoorSession copyWith({
    String? id,
    String? userId,
    String? gymId,
    DateTime? sessionDate,
    int? durationMinutes,
    String? feltGrade,
    int? rating,
    String? notes,
    Map<String, int>? gradeTallies,
    DateTime? createdAt,
    String? gymName,
  }) {
    return IndoorSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gymId: gymId ?? this.gymId,
      sessionDate: sessionDate ?? this.sessionDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      feltGrade: feltGrade ?? this.feltGrade,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      gradeTallies: gradeTallies ?? this.gradeTallies,
      createdAt: createdAt ?? this.createdAt,
      gymName: gymName ?? this.gymName,
    );
  }
}

