// lib/services/interfaces/i_photo_service.dart
import '../../models/domain/photo.dart';

abstract class IPhotoService {
  Future<List<Photo>> getPhotos();
  Future<Photo?> getPhoto(String id);
  Future<void> deletePhoto(String id);
  Future<void> refreshPhotos();

  // New methods
  Future<String> getPhotoUrl(String filename);
  Future<String> getThumbnailUrl(String filename);
  Future<void> generateMoreLikeThis({
    required String sourcePhoto,
    required String additionalPrompt,
    required int count,
    int? seed,
  });
}
