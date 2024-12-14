// lib/repositories/impl/photo_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../interfaces/i_photo_repository.dart';
import '../../services/interfaces/i_cache_service.dart';
import '../../models/domain/photo.dart';

class PhotoRepository implements IPhotoRepository {
  final http.Client client;
  final ICacheService cacheService;
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
    // Implementation
    return null;
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
}
