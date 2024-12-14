// lib/repositories/interfaces/i_photo_repository.dart
import '../../models/domain/photo.dart';

abstract class IPhotoRepository {
  Future<List<Photo>> fetchPhotos();
  Future<Photo?> fetchPhoto(String id);
  Future<void> deletePhoto(String id);
}
