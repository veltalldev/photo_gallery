// lib/services/impl/cache_service.dart
import 'dart:async';
import 'package:photo_gallery/services/interfaces/i_cache_service.dart';
import 'package:photo_gallery/services/interfaces/i_photo_cache_manager.dart';
import 'package:photo_gallery/services/impl/photo_cache_manager.dart';
import 'package:photo_gallery/core/errors/cache_error.dart';

class CacheService implements ICacheService {
  final IPhotoCacheManager _cacheManager;
  final StreamController<CacheStats> _statsController;
  final Map<String, Completer<void>> _ongoingOperations;

  CacheService({IPhotoCacheManager? cacheManager})
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

      await _cacheManager.put(key, data, maxAge: maxAge);
      _emitStats(
        CacheOperation.write,
        key: key,
        dataSizeBytes: _calculateDataSize(data),
      );

      completer.complete();
    } catch (e) {
      throw CacheError('Failed to store data in cache');
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

      final data = await _cacheManager.get<T>(key);
      if (data != null) {
        _emitStats(
          CacheOperation.read,
          key: key,
          dataSizeBytes: _calculateDataSize(data),
        );
      }
      return data;
    } catch (e) {
      throw CacheError('Failed to retrieve data from cache');
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      if (_ongoingOperations.containsKey(key)) {
        await _ongoingOperations[key]!.future;
      }

      await _cacheManager.remove(key);
      _emitStats(CacheOperation.delete, key: key);
    } catch (e) {
      throw CacheError('Failed to remove data from cache');
    }
  }

  @override
  Future<void> clear() async {
    try {
      if (_ongoingOperations.isNotEmpty) {
        await Future.wait(_ongoingOperations.values.map((c) => c.future));
      }

      await _cacheManager.clear();
      _emitStats(CacheOperation.clear);
    } catch (e) {
      throw CacheError('Failed to clear cache');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      if (_ongoingOperations.containsKey(key)) {
        await _ongoingOperations[key]!.future;
      }

      return await _cacheManager.containsKey(key);
    } catch (e) {
      throw CacheError('Failed to check cache');
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
