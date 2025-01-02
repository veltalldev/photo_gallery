// lib/services/impl/cache_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photo_gallery/core/errors/cache_error.dart';
import 'package:photo_gallery/services/interfaces/i_cache_service.dart';

class CacheService implements ICacheService {
  final DefaultCacheManager _cacheManager;

  CacheService({required DefaultCacheManager cacheManager})
      : _cacheManager = cacheManager;

  @override
  Future<void> put(String key, dynamic data, {Duration? maxAge}) async {
    try {
      final bytes = data is List<int>
          ? data // Store binary data directly
          : utf8.encode(json.encode(data)); // JSON encode other data

      await _cacheManager.putFile(
        key,
        Uint8List.fromList(bytes),
        maxAge: maxAge ?? const Duration(days: 7),
      );
    } catch (e) {
      throw CacheError('Failed to store data: $e');
    }
  }

  @override
  Future<T?> get<T>(String key) async {
    try {
      final file = await _cacheManager.getFileFromCache(key);
      if (file == null) return null;

      final bytes = await file.file.readAsBytes();

      // If we're expecting binary data (List<int> or Uint8List), return it directly
      if (T == (List<int>) || T == Uint8List) {
        return bytes as T;
      }

      // Otherwise, try to decode as JSON
      final data = json.decode(utf8.decode(bytes));
      return data as T;
    } catch (e) {
      throw CacheError('Failed to retrieve data: $e');
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _cacheManager.removeFile(key);
    } catch (e) {
      throw CacheError('Failed to remove data: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      throw CacheError('Failed to clear cache: $e');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      final file = await _cacheManager.getFileFromCache(key);
      return file != null;
    } catch (e) {
      throw CacheError('Failed to check cache: $e');
    }
  }
}
