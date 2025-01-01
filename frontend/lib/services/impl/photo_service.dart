// lib/services/impl/photo_service.dart
import '../interfaces/i_photo_service.dart';
import '../../repositories/interfaces/i_photo_repository.dart';
import '../../services/interfaces/i_cache_service.dart';
import '../../models/domain/photo.dart';
import 'dart:convert';

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
        // Decode the UTF-8 bytes back to a string, then parse as JSON
        final jsonString = utf8.decode(List<int>.from(cached));
        final jsonList = jsonDecode(jsonString) as List;
        return jsonList
            .map((p) => Photo.fromJson(p as Map<String, dynamic>))
            .toList();
      }

      // Fetch from repository
      final photos = await repository.fetchPhotos();

      // Convert to JSON string then to UTF-8 bytes before caching
      final jsonString = jsonEncode(photos.map((p) => p.toJson()).toList());
      await cacheService.put('photos', utf8.encode(jsonString));

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

  @override
  String getPhotoUrl(String filename) {
    return '${repository.baseUrl}/photos/$filename';
  }

  @override
  String getThumbnailUrl(String filename) {
    return '${repository.baseUrl}/photos/thumbnail/$filename';
  }

  @override
  Future<void> generateMoreLikeThis({
    required String sourcePhoto,
    required String additionalPrompt,
    required int count,
    int? seed,
  }) async {
    try {
      await repository.generatePhotos(
        sourcePhoto: sourcePhoto,
        additionalPrompt: additionalPrompt,
        count: count,
        seed: seed,
      );

      // Invalidate cache since new photos were generated
      await cacheService.remove('photos');
    } catch (e) {
      throw Exception('Failed to generate photos: $e');
    }
  }
}
