// lib/models/profile.dart
class Profile {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String gradeSystem; // 'v_scale' or 'french'
  final DateTime createdAt;

  Profile({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.gradeSystem = 'v_scale',
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      gradeSystem: json['grade_system'] as String? ?? 'v_scale',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'grade_system': gradeSystem,
    };
  }

  Profile copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? gradeSystem,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gradeSystem: gradeSystem ?? this.gradeSystem,
      createdAt: createdAt,
    );
  }
}