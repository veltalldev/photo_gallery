// lib/services/interfaces/i_photo_service.dart
import '../../models/domain/photo.dart';

abstract class IPhotoService {
  Future<List<Photo>> getPhotos();
  Future<Photo?> getPhoto(String id);
  Future<void> deletePhoto(String id);
  Future<void> refreshPhotos();
}
