// lib/services/impl/cache_service.dart
import 'dart:async';
import 'package:photo_gallery/core/errors/app_error.dart';
import 'package:photo_gallery/services/interfaces/i_cache_service.dart';
import 'package:photo_gallery/services/photo_cache_manager.dart';

class CacheService implements ICacheService {
  final PhotoCacheManager _cacheManager;
  final StreamController<CacheStats> _statsController;
  final Map<String, Completer<void>> _ongoingOperations;

  CacheService({PhotoCacheManager? cacheManager})
      : _cacheManager = cacheManager ?? PhotoCacheManager(),
        _statsController = StreamController<CacheStats>.broadcast(),
        _ongoingOperations = {};

  @override
  Future<void> put(String key, dynamic data, {Duration? maxAge}) async {
    try {
      if (_ongoingOperations.containsKey(key)) {
        await _ongoingOperations[key]!.future;
        return;
      }

      final completer = Completer<void>();
      _ongoingOperations[key] = completer;

      await _cacheManager.putFile(
        key,
        data,
        maxAge: maxAge ?? const Duration(days: 7),
      );

      _emitStats(
        CacheOperation.write,
        key: key,
        dataSizeBytes: _calculateDataSize(data),
      );

      completer.complete();
    } catch (e, stackTrace) {
      throw CacheError('Failed to store data in cache', e);
    } finally {
      _ongoingOperations.remove(key);
    }
  }

  @override
  Future<T?> get<T>(String key) async {
    try {
      if (_ongoingOperations.containsKey(key)) {
        await _ongoingOperations[key]!.future;
      }

      final file = await _cacheManager.getFileFromCache(key);
      if (file == null) return null;

      final data = await file.file.readAsBytes();
      _emitStats(
        CacheOperation.read,
        key: key,
        dataSizeBytes: data.length,
      );

      return data as T;
    } catch (e) {
      throw CacheError('Failed to retrieve data from cache', e);
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      if (_ongoingOperations.containsKey(key)) {
        await _ongoingOperations[key]!.future;
      }

      await _cacheManager.removeFile(key);
      _emitStats(CacheOperation.delete, key: key);
    } catch (e) {
      throw CacheError('Failed to remove data from cache', e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      if (_ongoingOperations.isNotEmpty) {
        await Future.wait(_ongoingOperations.values.map((c) => c.future));
      }

      await _cacheManager.emptyCache();
      _emitStats(CacheOperation.clear);
    } catch (e) {
      throw CacheError('Failed to clear cache', e);
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      if (_ongoingOperations.containsKey(key)) {
        await _ongoingOperations[key]!.future;
      }

      final file = await _cacheManager.getFileFromCache(key);
      return file != null;
    } catch (e) {
      throw CacheError('Failed to check cache', e);
    }
  }

  @override
  Stream<CacheStats> get stats => _statsController.stream;

  void _emitStats(
    CacheOperation operation, {
    String? key,
    int? dataSizeBytes,
  }) {
    _statsController.add(CacheStats(
      timestamp: DateTime.now(),
      operation: operation,
      key: key,
      dataSizeBytes: dataSizeBytes,
    ));
  }

  int? _calculateDataSize(dynamic data) {
    if (data is List<int>) {
      return data.length;
    }
    return null;
  }

  @override
  void dispose() {
    _statsController.close();
  }
}
