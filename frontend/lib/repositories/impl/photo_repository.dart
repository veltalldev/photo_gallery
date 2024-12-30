// lib/repositories/impl/photo_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../interfaces/i_photo_repository.dart';
import '../../services/interfaces/i_cache_service.dart';
import '../../models/domain/photo.dart';
import 'package:photo_gallery/services/impl/network_config_service.dart';

class PhotoRepository implements IPhotoRepository {
  final http.Client client;
  final ICacheService cacheService;
  String? _baseUrl; // Cache the base URL

  PhotoRepository({
    required this.client,
    required this.cacheService,
  });

  @override
  Future<String> get baseUrl async {
    _baseUrl ??= await NetworkConfigService.getBaseUrl();
    print("$_baseUrl");
    return _baseUrl!;
  }

  // Update all methods to use the async baseUrl
  @override
  Future<List<Photo>> fetchPhotos() async {
    try {
      final response =
          await client.get(Uri.parse('${await baseUrl}/api/photos'));

      if (response.statusCode == 200) {
        final List<dynamic> photoList = json.decode(response.body);
        final currentBaseUrl = await baseUrl;
        return photoList
            .map((filename) => Photo(
                  id: filename,
                  filename: filename,
                  thumbnailUrl: '$currentBaseUrl/photos/thumbnail/$filename',
                  fullImageUrl: '$currentBaseUrl/photos/$filename',
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
      final response =
          await client.get(Uri.parse('${await baseUrl}/api/photos/$id'));

      if (response.statusCode == 200) {
        final currentBaseUrl = await baseUrl;
        return Photo(
          id: id,
          filename: id,
          thumbnailUrl: '$currentBaseUrl/photos/thumbnail/$id',
          fullImageUrl: '$currentBaseUrl/photos/$id',
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
      Uri.parse('${await baseUrl}/api/photos/$id'),
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
      final currentBaseUrl = await baseUrl;

      // Get metadata for the source photo
      final metadataResponse = await client.get(
        Uri.parse('$currentBaseUrl/api/metadata/$sourcePhoto'),
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
        Uri.parse('$currentBaseUrl/api/generate'),
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
