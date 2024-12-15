// lib/repositories/interfaces/i_photo_repository.dart
import '../../models/domain/photo.dart';

abstract class IPhotoRepository {
  Future<List<Photo>> fetchPhotos();
  Future<Photo?> fetchPhoto(String id);
  Future<void> deletePhoto(String id);

  // New method for generation
  Future<void> generatePhotos({
    required String sourcePhoto,
    required String additionalPrompt,
    required int count,
    int? seed,
  });

  // Base URL accessor
  String get baseUrl;
}
