// lib/repositories/impl/photo_repository.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:photo_gallery/core/errors/server_error.dart';
import '../interfaces/i_photo_repository.dart';
import '../../services/interfaces/i_cache_service.dart';
import '../../models/domain/photo.dart';
import '../../core/errors/network_error.dart';
import '../../core/errors/photo_error.dart';

class PhotoRepository implements IPhotoRepository {
  final http.Client client;
  final ICacheService cacheService;
  final int maxRetries;
  final Duration timeout;
  @override
  final String baseUrl = 'http://47.151.18.30:8000'; // TODO: Move to config

  PhotoRepository({
    required this.client,
    required this.cacheService,
    this.maxRetries = 3,
    this.timeout = const Duration(seconds: 10),
  });

  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation();
      } on SocketException catch (e) {
        if (attempts >= maxRetries) {
          throw ConnectionError(
            message: 'Connection failed after $attempts attempts: ${e.message}',
            code: 'CONNECTION_ERROR',
          );
        }
        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 200 * attempts * attempts));
      } on TimeoutException {
        if (attempts >= maxRetries) {
          throw TimeoutError(
            message: 'Request timed out after $attempts attempts',
            code: 'TIMEOUT_ERROR',
          );
        }
        await Future.delayed(Duration(milliseconds: 200 * attempts * attempts));
      }
    }
  }

  @override
  Future<List<Photo>> fetchPhotos() async {
    return _withRetry(() async {
      try {
        final response = await client.get(
          Uri.parse('$baseUrl/api/photos'),
          headers: {
            'Connection': 'keep-alive',
            'Accept': 'application/json',
          },
        ).timeout(timeout);

        if (response.statusCode == 200) {
          final List<dynamic> photoList = json.decode(response.body);
          return photoList
              .map((filename) => Photo(
                    id: filename,
                    filename: filename,
                    thumbnailUrl: '$baseUrl/photos/thumbnail/$filename',
                    fullImageUrl: '$baseUrl/photos/$filename',
                  ))
              .toList();
        } else {
          throw ServerError(
            message: 'Failed to load photos: ${response.statusCode}',
            code: 'SERVER_ERROR',
            statusCode: response.statusCode,
          );
        }
      } catch (e) {
        if (e is TimeoutException || e is SocketException || e is ServerError) {
          rethrow;
        }
        throw PhotoLoadError(
          message: 'Error loading photos: $e',
          code: 'PHOTO_LOAD_ERROR',
        );
      }
    });
  }

  @override
  Future<Photo?> fetchPhoto(String id) async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/api/photos/$id'));

      if (response.statusCode == 200) {
        return Photo(
          id: id,
          filename: id,
          thumbnailUrl: '$baseUrl/photos/thumbnail/$id',
          fullImageUrl: '$baseUrl/photos/$id',
          // We could add additional metadata here from response if needed
        );
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch photo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching photo: $e');
    }
  }

  @override
  Future<void> deletePhoto(String id) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/photos/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete photo: ${response.statusCode}');
    }
  }

  @override
  Future<void> generatePhotos({
    required String sourcePhoto,
    required String additionalPrompt,
    required int count,
    int? seed,
  }) async {
    try {
      // Get metadata for the source photo
      final metadataResponse = await client.get(
        Uri.parse('$baseUrl/api/metadata/$sourcePhoto'),
      );

      if (metadataResponse.statusCode != 200) {
        throw Exception(
            'Failed to get metadata: ${metadataResponse.statusCode}');
      }

      final metadata = json.decode(metadataResponse.body);
      if (seed != null) {
        metadata['seed'] = seed;
      }

      // Trigger the generation
      final generationResponse = await client.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image_name': sourcePhoto,
          'metadata': metadata,
          'use_random_seed': seed == null,
          'seed': seed,
          'quantity': count,
          if (additionalPrompt.isNotEmpty)
            'additional_prompt': additionalPrompt,
        }),
      );

      if (generationResponse.statusCode != 200 &&
          generationResponse.statusCode != 201) {
        throw Exception('Failed to generate: ${generationResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Generation error: $e');
    }
  }
}
