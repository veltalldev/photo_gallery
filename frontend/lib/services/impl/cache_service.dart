// lib/services/impl/cache_service.dart
import '../interfaces/i_cache_service.dart';
import 'package:photo_gallery/services/photo_cache_manager.dart';

class CacheService implements ICacheService {
  final PhotoCacheManager _cacheManager = PhotoCacheManager();

  @override
  Future<void> put(String key, dynamic data) async {
    // Implementation using PhotoCacheManager
  }

  @override
  Future<dynamic> get(String key) async {
    // Implementation using PhotoCacheManager
  }

  @override
  Future<void> remove(String key) async {
    // Implementation using PhotoCacheManager
  }

  @override
  Future<void> clear() async {
    // Implementation using PhotoCacheManager
  }

  @override
  Future<bool> containsKey(String key) async {
    // Implementation using PhotoCacheManager
    return false;
  }
}
