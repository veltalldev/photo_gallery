// lib/services/interfaces/i_cache_service.dart
abstract class ICacheService {
  Future<void> put(String key, dynamic data);
  Future<dynamic> get(String key);
  Future<void> remove(String key);
  Future<void> clear();
  Future<bool> containsKey(String key);
}
