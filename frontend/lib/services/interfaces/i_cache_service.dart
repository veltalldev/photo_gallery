abstract class ICacheService {
  /// Stores data in the cache with the specified key
  Future<void> put(String key, dynamic data, {Duration? maxAge});

  /// Retrieves data from the cache by key with type safety
  Future<T?> get<T>(String key);

  /// Removes data from the cache by key
  Future<void> remove(String key);

  /// Clears all data from the cache
  Future<void> clear();

  /// Checks if the cache contains data for the specified key
  Future<bool> containsKey(String key);
}
