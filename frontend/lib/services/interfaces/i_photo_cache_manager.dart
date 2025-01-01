import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photo_gallery/services/interfaces/i_cache_service.dart';

/// Interface for photo-specific cache management operations
abstract class IPhotoCacheManager implements ICacheService {
  /// Get the underlying BaseCacheManager for use with CachedNetworkImage
  BaseCacheManager get cacheManager;

  /// Factory constructor to get the singleton instance
  factory IPhotoCacheManager() => throw UnimplementedError();
}
