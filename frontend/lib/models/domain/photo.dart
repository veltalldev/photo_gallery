// lib/models/domain/photo.dart

class Photo {
  final String id;
  final String filename;
  final DateTime? createdAt;
  final String? thumbnailUrl;
  final String? fullImageUrl;

  Photo({
    required this.id,
    required this.filename,
    this.createdAt,
    this.thumbnailUrl,
    this.fullImageUrl,
  });

  Photo copyWith({
    String? id,
    String? filename,
    DateTime? createdAt,
    String? thumbnailUrl,
    String? fullImageUrl,
  }) {
    return Photo(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      createdAt: createdAt ?? this.createdAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fullImageUrl: fullImageUrl ?? this.fullImageUrl,
    );
  }

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      filename: json['filename'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      thumbnailUrl: json['thumbnail_url'] as String?,
      fullImageUrl: json['full_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'created_at': createdAt?.toIso8601String(),
        'thumbnail_url': thumbnailUrl,
        'full_image_url': fullImageUrl,
      };
}
