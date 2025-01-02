import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_gallery/services/interfaces/i_cache_service.dart';
import 'package:http/http.dart' as http;

class PhotoCacheImageProvider extends ImageProvider<PhotoCacheImageProvider> {
  final String url;
  final ICacheService cacheService;

  PhotoCacheImageProvider({
    required this.url,
    required this.cacheService,
  });

  @override
  ImageStreamCompleter loadImage(
    PhotoCacheImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(
    PhotoCacheImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    try {
      final bytes = await cacheService.get<List<int>>('image:$url');
      if (bytes != null) {
        final uint8List =
            bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
        final buffer = await ui.ImmutableBuffer.fromUint8List(uint8List);
        return decode(buffer);
      }

      // If not in cache, fetch and store
      final response = await http.get(Uri.parse(url));
      final imageBytes = response.bodyBytes;
      await cacheService.put('image:$url', imageBytes);
      final buffer = await ui.ImmutableBuffer.fromUint8List(imageBytes);
      return decode(buffer);
    } catch (e) {
      throw Exception('Failed to load image: $e');
    }
  }

  @override
  Future<PhotoCacheImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<PhotoCacheImageProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is PhotoCacheImageProvider && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
