import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';
import 'package:image/image.dart' as img;
import 'package:quiver/collection.dart' show LruMap;

import '../interfaces/i_cache_service.dart';
import '../../core/errors/cache_error.dart';

class ThumbnailConfig {
  final int maxWidth;
  final int maxHeight;
  final int quality;

  const ThumbnailConfig({
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
  });
}

class PhotoCacheManager implements ICacheService {
  static const defaultThumbnailConfig = ThumbnailConfig(
    maxWidth: 200,
    maxHeight: 200,
    quality: 85,
  );

  final ICacheService _baseCache;
  final int _maxCacheSize;
  final int _memoryCacheSize;
  final ThumbnailConfig _thumbnailConfig;
  final _lock = Lock();
  final LruMap<String, Uint8List> _memoryCache;

  PhotoCacheManager({
    required ICacheService baseCache,
    int maxCacheSize = 100 * 1024 * 1024,
    int memoryCacheSize = 50,
    ThumbnailConfig? thumbnailConfig,
  })  : _baseCache = baseCache,
        _maxCacheSize = maxCacheSize,
        _memoryCacheSize = memoryCacheSize,
        _thumbnailConfig = thumbnailConfig ?? defaultThumbnailConfig,
        _memoryCache = LruMap<String, Uint8List>(maximumSize: memoryCacheSize);

  @override
  Future<void> put(String key, dynamic data, {Duration? maxAge}) async {
    await _lock.synchronized(() async {
      if (data is! List<int>) {
        throw CacheError('Photo cache only accepts binary data');
      }

      // Validate image format
      if (!_isValidImageData(data)) {
        throw CacheError('Invalid image format');
      }

      // Check cache size and evict if necessary
      await _manageCacheSize();

      // Store original image
      await _baseCache.put('$key.original', data, maxAge: maxAge);

      // Generate and store thumbnail
      final thumbnail = await _generateThumbnail(data);
      await _baseCache.put('$key.thumb', thumbnail, maxAge: maxAge);

      // Cache thumbnail in memory
      _memoryCache['$key.thumb'] = Uint8List.fromList(thumbnail);
    });
  }

  @override
  Future<T?> get<T>(String key) async {
    return await _lock.synchronized(() async {
      // Check memory cache first for thumbnails
      if (key.endsWith('.thumb')) {
        final cached = _memoryCache[key];
        if (cached != null) return cached as T;
      }

      final data = await _baseCache.get<T>(key);
      if (data == null) return null;

      // Ensure we return Uint8List for image data
      if (data is List<int>) {
        return Uint8List.fromList(data) as T;
      }

      return data;
    });
  }

  @override
  Future<void> remove(String key) async {
    await _lock.synchronized(() async {
      _memoryCache.remove('$key.thumb');
      await _baseCache.remove('$key.original');
      await _baseCache.remove('$key.thumb');
    });
  }

  @override
  Future<void> clear() async {
    await _lock.synchronized(() async {
      _memoryCache.clear();
      await _baseCache.clear();
    });
  }

  @override
  Future<bool> containsKey(String key) async {
    return await _lock.synchronized(() async {
      if (key.endsWith('.thumb') && _memoryCache.containsKey(key)) {
        return true;
      }
      return await _baseCache.containsKey('$key.original');
    });
  }

  bool _isValidImageData(List<int> data) {
    try {
      final decoder = img.findDecoderForData(data);
      return decoder != null;
    } catch (_) {
      return false;
    }
  }

  Future<List<int>> _generateThumbnail(List<int> originalImage) async {
    try {
      final original = img.decodeImage(Uint8List.fromList(originalImage));
      if (original == null) throw CacheError('Failed to decode image');

      final double ratio = original.width / original.height;
      int width = _thumbnailConfig.maxWidth;
      int height = (width / ratio).round();

      if (height > _thumbnailConfig.maxHeight) {
        height = _thumbnailConfig.maxHeight;
        width = (height * ratio).round();
      }

      final thumbnail = img.copyResize(
        original,
        width: width,
        height: height,
        interpolation: img.Interpolation.linear,
      );

      return img.encodeJpg(thumbnail, quality: _thumbnailConfig.quality);
    } catch (e) {
      throw CacheError('Failed to generate thumbnail: $e');
    }
  }

  Future<Directory> _getCacheDirectory() async {
    final baseCacheDir = await getTemporaryDirectory();
    final cacheDir = Directory(path.join(baseCacheDir.path, 'photo_cache'));

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  Future<int> _calculateCacheSize() async {
    try {
      int totalSize = 0;
      final cacheDir = await _getCacheDirectory();

      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      throw CacheError('Failed to calculate cache size: $e');
    }
  }

  Future<void> _evictOldestFiles() async {
    try {
      final cacheDir = await _getCacheDirectory();
      final files = <FileSystemEntity>[];

      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          files.add(entity);
        }
      }

      files.sort((a, b) {
        final aStats = a.statSync();
        final bStats = b.statSync();
        return aStats.accessed.compareTo(bStats.accessed);
      });

      int currentSize = await _calculateCacheSize();
      for (final file in files) {
        if (currentSize <= _maxCacheSize) break;

        if (file is File) {
          final fileSize = await file.length();
          await file.delete();
          currentSize -= fileSize;
        }
      }
    } catch (e) {
      throw CacheError('Failed to evict old files: $e');
    }
  }

  Future<void> _manageCacheSize() async {
    try {
      final cacheSize = await _calculateCacheSize();
      if (cacheSize > _maxCacheSize) {
        await _evictOldestFiles();
      }
    } catch (e) {
      throw CacheError('Failed to manage cache size: $e');
    }
  }
}
