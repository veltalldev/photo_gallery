// lib/repositories/impl/photo_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../interfaces/i_photo_repository.dart';
import '../../services/interfaces/i_cache_service.dart';
import '../../models/domain/photo.dart';

class PhotoRepository implements IPhotoRepository {
  final http.Client client;
  final ICacheService cacheService;
  @override
  final String baseUrl = 'http://192.168.4.26:8000'; // TODO: Move to config

  PhotoRepository({
    required this.client,
    required this.cacheService,
  });

  @override
  Future<List<Photo>> fetchPhotos() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/api/photos'));

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
        throw Exception('Failed to load photos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading photos: $e');
    }
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
