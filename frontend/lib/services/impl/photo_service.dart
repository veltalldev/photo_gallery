import 'dart:convert';

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
      // if (cached != null) {
      //   return (cached as List).map((p) => Photo.fromJson(p)).toList();
      // }
      if (cached != null) {
        try {
          final String jsonString = utf8.decode(cached as List<int>);
          final List<dynamic> jsonList = json.decode(jsonString);
          // Add type checking here
          if (jsonList.isNotEmpty && jsonList[0] is Map<String, dynamic>) {
            return jsonList
                .map((p) => Photo.fromJson(p as Map<String, dynamic>))
                .toList();
          }
          // If cached data isn't in the right format, ignore it and fetch fresh
        } catch (e) {
          // If there's any error processing cached data, ignore it and fetch fresh
        }
      }

      // Fetch from repository
      final photos = await repository.fetchPhotos();

      // Update cache
      // await cacheService.put('photos', photos.map((p) => p.toJson()).toList());
      // Convert the data to a JSON string first, then to bytes
      final String jsonString =
          json.encode(photos.map((p) => p.toJson()).toList());
      final List<int> bytes = utf8.encode(jsonString);
      await cacheService.put('photos', bytes);

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
  Future<String> getPhotoUrl(String filename) async {
    return '${await repository.baseUrl}/photos/$filename';
  }

  @override
  Future<String> getThumbnailUrl(String filename) async {
    return '${await repository.baseUrl}/photos/thumbnail/$filename';
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
