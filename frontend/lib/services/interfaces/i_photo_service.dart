// lib/services/interfaces/i_photo_service.dart
import 'package:photo_gallery/services/interfaces/i_cache_service.dart';

import '../../models/domain/photo.dart';

abstract class IPhotoService {
  Future<List<Photo>> getPhotos();
  Future<Photo?> getPhoto(String id);
  Future<void> deletePhoto(String id);
  Future<void> refreshPhotos();

  // New methods
  String getPhotoUrl(String filename);
  String getThumbnailUrl(String filename);
  Future<void> generateMoreLikeThis({
    required String sourcePhoto,
    required String additionalPrompt,
    required int count,
    int? seed,
  });

  // New method
  ICacheService getCacheService();
}
