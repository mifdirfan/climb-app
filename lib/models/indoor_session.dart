class IndoorSession {
  final String id;
  final String userId;
  final String gymId;
  final DateTime sessionDate;
  final int? durationMinutes;
  final String? feltGrade;
  final int? rating;
  final String? notes;
  final Map<String, int> gradeTallies;
  final String? gymName; // Joined from public.crags

  const IndoorSession({
    required this.id,
    required this.userId,
    required this.gymId,
    required this.sessionDate,
    this.durationMinutes,
    this.feltGrade,
    this.rating,
    this.notes,
    required this.gradeTallies,
    this.gymName,
  });

  factory IndoorSession.fromJson(Map<String, dynamic> json) {
    return IndoorSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      gymId: json['gym_id'] as String,
      sessionDate: DateTime.parse(json['session_date'] as String),
      durationMinutes: json['duration_minutes'] as int?,
      feltGrade: json['felt_grade'] as String?,
      rating: json['rating'] as int?,
      notes: json['notes'] as String?,
      gradeTallies: Map<String, int>.from(json['grade_tallies'] as Map? ?? {}),
      gymName: json['crags']?['name'] as String?, // Supabase join
    );
  }
}