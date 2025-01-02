import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:photo_gallery/services/impl/cache_service.dart';

void main() {
  late DefaultCacheManager mockCacheManager;
  late CacheService cacheService;

  setUp(() {
    mockCacheManager = MockDefaultCacheManager();
    cacheService = CacheService(cacheManager: mockCacheManager);
  });

  group('CacheService', () {
    test('put should store data in cache', () async {
      // TODO: Implement test
    });

    test('get should retrieve data from cache', () async {
      // TODO: Implement test
    });

    // ... more tests
  });
}
