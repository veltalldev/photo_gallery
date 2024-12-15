// lib/services/interfaces/i_cache_service.dart
import 'package:flutter/foundation.dart';

/// Interface for cache operations in the application.
/// Provides type-safe caching operations with optional configuration.
abstract class ICacheService {
  /// Stores data in the cache with the specified key.
  ///
  /// [key] The unique identifier for the cached data
  /// [data] The data to cache
  /// [maxAge] Optional maximum age for the cached data
  Future<void> put(String key, dynamic data, {Duration? maxAge});

  /// Retrieves data from the cache by key with type safety.
  ///
  /// [T] The expected type of the cached data
  /// Returns null if the data is not found
  Future<T?> get<T>(String key);

  /// Removes data from the cache by key.
  Future<void> remove(String key);

  /// Clears all data from the cache.
  Future<void> clear();

  /// Checks if the cache contains data for the specified key.
  Future<bool> containsKey(String key);

  /// Stream of cache statistics for monitoring.
  /// Provides insights into cache operations and performance.
  Stream<CacheStats> get stats;

  /// Cleans up resources used by the cache service.
  @mustCallSuper
  void dispose();
}

/// Statistics for cache operations.
class CacheStats {
  final DateTime timestamp;
  final CacheOperation operation;
  final String? key;
  final int? dataSizeBytes;

  const CacheStats({
    required this.timestamp,
    required this.operation,
    this.key,
    this.dataSizeBytes,
  });
}

/// Types of cache operations for monitoring.
enum CacheOperation {
  read,
  write,
  delete,
  clear,
}
