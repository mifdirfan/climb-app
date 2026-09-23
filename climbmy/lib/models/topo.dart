/// Represents a topo diagram or visual wall image in Supabase (public.topos).
class Topo {
  final String id;
  final String sectorId;
  final String imageUrl;
  final String? uploadedBy;
  final DateTime? createdAt;

  // Joined attributes
  final String? sectorName;
  final String? uploaderName;

  const Topo({
    required this.id,
    required this.sectorId,
    required this.imageUrl,
    this.uploadedBy,
    this.createdAt,
    this.sectorName,
    this.uploaderName,
  });

  factory Topo.fromJson(Map<String, dynamic> json) {
    String? sName;
    String? uName;

    if (json['sectors'] is Map<String, dynamic>) {
      sName = (json['sectors'] as Map<String, dynamic>)['name'] as String?;
    }
    if (json['profiles'] is Map<String, dynamic>) {
      final pMap = json['profiles'] as Map<String, dynamic>;
      uName = (pMap['display_name'] ?? pMap['username']) as String?;
    }

    return Topo(
      id: json['id'] as String,
      sectorId: (json['sector_id'] ?? json['sectorId']) as String? ?? '',
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String? ?? '',
      uploadedBy: (json['uploaded_by'] ?? json['uploadedBy']) as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      sectorName: sName ?? json['sector_name'] as String?,
      uploaderName: uName ?? json['uploader_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sector_id': sectorId,
      'image_url': imageUrl,
      if (uploadedBy != null) 'uploaded_by': uploadedBy,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  Topo copyWith({
    String? id,
    String? sectorId,
    String? imageUrl,
    String? uploadedBy,
    DateTime? createdAt,
    String? sectorName,
    String? uploaderName,
  }) {
    return Topo(
      id: id ?? this.id,
      sectorId: sectorId ?? this.sectorId,
      imageUrl: imageUrl ?? this.imageUrl,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      sectorName: sectorName ?? this.sectorName,
      uploaderName: uploaderName ?? this.uploaderName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Topo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sectorId == other.sectorId &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => id.hashCode ^ sectorId.hashCode ^ imageUrl.hashCode;
}

