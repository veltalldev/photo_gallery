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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fullImageUrl: json['fullImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (fullImageUrl != null) 'fullImageUrl': fullImageUrl,
    };
  }
}
