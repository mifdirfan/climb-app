/// Represents a user profile in Supabase (public.profiles).
class Profile {
  final String id; // References auth.users(id)
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String gradeSystem; // 'v_scale' | 'french'
  final DateTime? createdAt;

  const Profile({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.gradeSystem = 'v_scale',
    this.createdAt,
  });

  bool get isVScale => gradeSystem == 'v_scale';
  bool get isFrench => gradeSystem == 'french';

  /// Returns user's display name or fallback username / Climber.
  String get nameOrClimber {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }
    return 'Climber';
  }

  /// Initial letter for fallback avatar circles.
  String get initial {
    final name = nameOrClimber;
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C';
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: (json['display_name'] ?? json['displayName']) as String?,
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      gradeSystem: json['grade_system'] as String? ?? 'v_scale',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'grade_system': gradeSystem,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? gradeSystem,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gradeSystem: gradeSystem ?? this.gradeSystem,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          displayName == other.displayName &&
          avatarUrl == other.avatarUrl &&
          gradeSystem == other.gradeSystem;

  @override
  int get hashCode =>
      id.hashCode ^
      username.hashCode ^
      displayName.hashCode ^
      avatarUrl.hashCode ^
      gradeSystem.hashCode;
}

