// test/services/impl/cache_service_test.dart

import 'package:file/file.dart' as files; // Use the file package
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photo_gallery/core/errors/app_error.dart';
import 'package:photo_gallery/services/impl/cache_service.dart';
import 'package:photo_gallery/services/interfaces/i_cache_service.dart';
import 'package:photo_gallery/services/photo_cache_manager.dart';

// Generate mocks
@GenerateNiceMocks([MockSpec<PhotoCacheManager>()])
@GenerateNiceMocks([MockSpec<files.File>()])
@GenerateNiceMocks([MockSpec<FileInfo>()])
import 'cache_service_test.mocks.dart';

void main() {
  late CacheService cacheService;
  late MockPhotoCacheManager mockCacheManager;
  late files.File mockFile;
  late FileInfo mockFileInfo;
  late Uint8List testData;

  setUp(() {
    mockCacheManager = MockPhotoCacheManager();
    mockFile = MockFile() as files.File;
    mockFileInfo = MockFileInfo();
    testData = Uint8List.fromList([1, 2, 3]);
    cacheService = CacheService(cacheManager: mockCacheManager);

    // Setup default mock behavior
    when(mockFile.readAsBytes()).thenAnswer((_) async => testData);
    when(mockFileInfo.file).thenReturn(mockFile);
  });

  group('put', () {
    test('should store data successfully', () async {
      // Arrange
      const key = 'test_key';

      // Use thenAnswer for async operations
      when(mockCacheManager.putFile(
        any,
        any,
        maxAge: anyNamed('maxAge'),
      )).thenAnswer((_) async => mockFile);

      // Act
      await cacheService.put(key, testData);

      // Assert
      verify(mockCacheManager.putFile(
        key,
        testData,
        maxAge: anyNamed('maxAge'),
      )).called(1);
    });

    test('should throw CacheError when storage fails', () async {
      // Arrange
      const key = 'test_key';
      when(mockCacheManager.putFile(
        any,
        any,
        maxAge: anyNamed('maxAge'),
      )).thenThrow(Exception('Storage failed'));

      // Act & Assert
      expect(
        () => cacheService.put(key, testData),
        throwsA(isA<CacheError>()),
      );
    });
  });

  group('get', () {
    test('should retrieve stored data successfully', () async {
      // Arrange
      const key = 'test_key';
      when(mockCacheManager.getFileFromCache(any))
          .thenAnswer((_) async => mockFileInfo);

      // Act
      final result = await cacheService.get<Uint8List>(key);

      // Assert
      expect(result, equals(testData));
      verify(mockCacheManager.getFileFromCache(key)).called(1);
    });

    test('should return null when key not found', () async {
      // Arrange
      const key = 'nonexistent_key';
      when(mockCacheManager.getFileFromCache(any))
          .thenAnswer((_) async => null);

      // Act
      final result = await cacheService.get(key);

      // Assert
      expect(result, isNull);
    });
    test('should throw CacheError when retrieval fails', () async {
      // Arrange
      const key = 'test_key';
      when(mockCacheManager.getFileFromCache(any))
          .thenThrow(Exception('Retrieval failed'));

      // Act & Assert
      expect(
        () => cacheService.get(key),
        throwsA(isA<CacheError>()),
      );
    });
  });

  group('remove', () {
    test('should remove data successfully', () async {
      // Arrange
      const key = 'test_key';
      when(mockCacheManager.removeFile(any)).thenAnswer((_) async => true);

      // Act
      await cacheService.remove(key);

      // Assert
      verify(mockCacheManager.removeFile(key)).called(1);
    });

    test('should throw CacheError when removal fails', () async {
      // Arrange
      const key = 'test_key';
      when(mockCacheManager.removeFile(any))
          .thenThrow(Exception('Removal failed'));

      // Act & Assert
      expect(
        () => cacheService.remove(key),
        throwsA(isA<CacheError>()),
      );
    });
  });

  group('clear', () {
    test('should clear all data successfully', () async {
      // Arrange
      when(mockCacheManager.emptyCache()).thenAnswer((_) async => true);

      // Act
      await cacheService.clear();

      // Assert
      verify(mockCacheManager.emptyCache()).called(1);
    });

    test('should throw CacheError when clear fails', () async {
      // Arrange
      when(mockCacheManager.emptyCache()).thenThrow(Exception('Clear failed'));

      // Act & Assert
      expect(
        () => cacheService.clear(),
        throwsA(isA<CacheError>()),
      );
    });
  });

  group('containsKey', () {
    test('should return true for existing key', () async {
      // Arrange
      const key = 'test_key';
      when(mockCacheManager.getFileFromCache(any))
          .thenAnswer((_) async => mockFileInfo);

      // Act
      final result = await cacheService.containsKey(key);

      // Assert
      expect(result, isTrue);
    });

    test('should return false for non-existing key', () async {
      // Arrange
      const key = 'nonexistent_key';
      when(mockCacheManager.getFileFromCache(any))
          .thenAnswer((_) async => null);

      // Act
      final result = await cacheService.containsKey(key);

      // Assert
      expect(result, isFalse);
    });
  });

  group('stats', () {
    test('should emit stats for cache operations', () async {
      // Arrange
      const key = 'test_key';
      when(mockCacheManager.putFile(
        any,
        any,
        maxAge: anyNamed('maxAge'),
      )).thenAnswer((_) async => mockFile);

      // Act & Assert
      expectLater(
        cacheService.stats,
        emitsInOrder([
          predicate((CacheStats stats) =>
              stats.operation == CacheOperation.write &&
              stats.key == key &&
              stats.dataSizeBytes == testData.length),
        ]),
      );

      await cacheService.put(key, testData);
    });
  });
}
