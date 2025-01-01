import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photo_gallery/core/errors/cache_error.dart';
import 'package:photo_gallery/services/interfaces/i_cache_service.dart';
import 'package:photo_gallery/services/interfaces/i_photo_cache_manager.dart';

class PhotoCacheManager implements IPhotoCacheManager {
  static const key = 'photoCache';
  final CacheManager _cacheManager;
  final _statsController = StreamController<CacheStats>.broadcast();

  static final PhotoCacheManager _instance = PhotoCacheManager._();
  factory PhotoCacheManager() => _instance;

  PhotoCacheManager._()
      : _cacheManager = CacheManager(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 500,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );

  @override
  Stream<CacheStats> get stats => _statsController.stream;

  @override
  Future<void> put(String key, dynamic data, {Duration? maxAge}) async {
    try {
      final bytes = utf8.encode(json.encode(data));
      await _cacheManager.putFile(
        key,
        Uint8List.fromList(bytes),
        maxAge: maxAge ?? const Duration(days: 7),
      );
      _statsController.add(CacheStats(
        timestamp: DateTime.now(),
        operation: CacheOperation.write,
        key: key,
        dataSizeBytes: bytes.length,
      ));
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
      final data = json.decode(utf8.decode(bytes));

      _statsController.add(CacheStats(
        timestamp: DateTime.now(),
        operation: CacheOperation.read,
        key: key,
        dataSizeBytes: bytes.length,
      ));

      return data as T;
    } catch (e) {
      throw CacheError('Failed to retrieve data: $e');
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _cacheManager.removeFile(key);
      _statsController.add(CacheStats(
        timestamp: DateTime.now(),
        operation: CacheOperation.delete,
        key: key,
      ));
    } catch (e) {
      throw CacheError('Failed to remove data: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _cacheManager.emptyCache();
      _statsController.add(CacheStats(
        timestamp: DateTime.now(),
        operation: CacheOperation.clear,
      ));
    } catch (e) {
      throw CacheError('Failed to clear cache: $e');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    final file = await _cacheManager.getFileFromCache(key);
    return file != null;
  }

  @override
  void dispose() {
    _statsController.close();
  }

  BaseCacheManager get cacheManager => _cacheManager;
}
