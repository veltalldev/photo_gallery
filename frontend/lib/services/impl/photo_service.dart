// lib/services/impl/photo_service.dart
import '../interfaces/i_photo_service.dart';
import '../../repositories/interfaces/i_photo_repository.dart';
import '../../services/interfaces/i_cache_service.dart';
import '../../models/domain/photo.dart';

class PhotoService implements IPhotoService {
  final IPhotoRepository repository;
  final ICacheService cacheService;

  PhotoService({
    required this.repository,
    required this.cacheService,
  });

  @override
  Future<List<Photo>> getPhotos() async {
    try {
      // Check cache first
      final cached = await cacheService.get('photos');
      if (cached != null) {
        return (cached as List).map((p) => Photo.fromJson(p)).toList();
      }

      // Fetch from repository
      final photos = await repository.fetchPhotos();

      // Update cache
      await cacheService.put('photos', photos.map((p) => p.toJson()).toList());

      return photos;
    } catch (e) {
      throw Exception('Failed to get photos: $e');
    }
  }

  @override
  Future<Photo?> getPhoto(String id) async {
    return repository.fetchPhoto(id);
  }

  @override
  Future<void> deletePhoto(String id) async {
    await repository.deletePhoto(id);
    // Invalidate cache
    await cacheService.remove('photos');
  }

  @override
  Future<void> refreshPhotos() async {
    await cacheService.remove('photos');
    await getPhotos();
  }
}
