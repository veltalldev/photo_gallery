// lib/services/impl/photo_service.dart
import 'package:flutter/material.dart';
import 'package:photo_gallery/core/errors/photo_error.dart';

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
      debugPrint('PhotoService: Getting photos...');
      final cachedPhotos = await _getCachedPhotos();
      if (cachedPhotos != null) {
        return cachedPhotos;
      }
      return await _fetchAndCachePhotos();
    } catch (e) {
      debugPrint('PhotoService error: $e');
      throw PhotoLoadError(
        message: 'Failed to load photos: $e',
      );
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

  Future<List<Photo>?> _getCachedPhotos() async {
    try {
      final cached = await cacheService.get('photos');
      if (cached != null) {
        debugPrint('Cache hit: decoding photos');
        if (cached is List) {
          return cached
              .map((p) => Photo.fromJson(p as Map<String, dynamic>))
              .toList();
        }
        // If it's raw bytes, decode it
        final jsonString =
            utf8.decode(cached is List<int> ? cached : List<int>.from(cached));
        final jsonList = jsonDecode(jsonString) as List;
        return jsonList
            .map((p) => Photo.fromJson(p as Map<String, dynamic>))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('Cache decode error: $e');
      return null; // On cache error, just return null to trigger fresh fetch
    }
  }

  Future<List<Photo>> _fetchAndCachePhotos() async {
    debugPrint('Cache miss: fetching photos');
    final photos = await repository.fetchPhotos();

    try {
      final jsonString = jsonEncode(photos.map((p) => p.toJson()).toList());
      await cacheService.put('photos', utf8.encode(jsonString));
    } catch (e) {
      debugPrint('Cache store error: $e');
      // Continue even if caching fails
    }

    return photos;
  }
}
