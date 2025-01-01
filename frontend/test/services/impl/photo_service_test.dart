// test/services/impl/photo_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:photo_gallery/core/errors/cache_error.dart';
import 'package:photo_gallery/core/errors/photo_error.dart';
import 'package:photo_gallery/services/impl/photo_service.dart';
import 'package:photo_gallery/core/errors/app_error.dart';
import '../../helpers/mock_helpers.dart';
import '../../helpers/mock_helpers.mocks.dart';

void main() {
  late MockIPhotoRepository mockPhotoRepository;
  late MockICacheService mockCacheService;
  late PhotoService photoService;

  setUp(() {
    mockPhotoRepository = MockIPhotoRepository();
    mockCacheService = MockICacheService();
    photoService = PhotoService(
      repository: mockPhotoRepository,
      cacheService: mockCacheService,
    );

    // Use TestData constant instead of hardcoded value
    when(mockPhotoRepository.baseUrl).thenReturn(TestData.baseUrl);
  });

  group('getPhotos', () {
    test('should return cached photos when available', () async {
      // Arrange
      final mockPhotos = TestData.getMockPhotos();
      when(mockCacheService.get('photos'))
          .thenAnswer((_) async => mockPhotos.map((p) => p.toJson()).toList());

      // Act
      final result = await photoService.getPhotos();

      // Assert
      expect(result, equals(mockPhotos));
      verify(mockCacheService.get('photos')).called(1);
      verifyNever(mockPhotoRepository.fetchPhotos());
    });

    test('should fetch and cache photos when cache is empty', () async {
      // Arrange
      final mockPhotos = TestData.getMockPhotos();
      when(mockCacheService.get('photos')).thenAnswer((_) async => null);
      when(mockPhotoRepository.fetchPhotos())
          .thenAnswer((_) async => mockPhotos);

      // Act
      final result = await photoService.getPhotos();

      // Assert
      expect(result, equals(mockPhotos));
      verify(mockCacheService.get('photos')).called(1);
      verify(mockPhotoRepository.fetchPhotos()).called(1);
      verify(mockCacheService.put(
        'photos',
        mockPhotos.map((p) => p.toJson()).toList(),
      )).called(1);
    });

    test('should throw AppError when both cache and fetch fail', () async {
      // Arrange
      when(mockCacheService.get('photos')).thenThrow(CacheError('Cache error'));
      when(mockPhotoRepository.fetchPhotos())
          .thenThrow(PhotoLoadError(message: 'Network error'));

      // Act & Assert
      expect(
        () => photoService.getPhotos(),
        throwsA(isA<PhotoLoadError>()),
      );
    });
  });

  group('getPhoto', () {
    test('should return photo when found', () async {
      // Arrange
      final mockPhoto = TestData.getMockPhoto(id: 'test_id');
      when(mockPhotoRepository.fetchPhoto('test_id'))
          .thenAnswer((_) async => mockPhoto);

      // Act
      final result = await photoService.getPhoto('test_id');

      // Assert
      expect(result, equals(mockPhoto));
      verify(mockPhotoRepository.fetchPhoto('test_id')).called(1);
    });

    test('should return null when photo not found', () async {
      // Arrange
      when(mockPhotoRepository.fetchPhoto('non_existent'))
          .thenAnswer((_) async => null);

      // Act
      final result = await photoService.getPhoto('non_existent');

      // Assert
      expect(result, isNull);
    });
  });

  group('deletePhoto', () {
    test('should delete photo and invalidate cache', () async {
      // Arrange
      const photoId = 'test_photo_1';

      // Act
      await photoService.deletePhoto(photoId);

      // Assert
      verify(mockPhotoRepository.deletePhoto(photoId)).called(1);
      verify(mockCacheService.remove('photos')).called(1);
    });

    test('should throw AppError when delete fails', () async {
      // Arrange
      const photoId = 'test_photo_1';
      when(mockPhotoRepository.deletePhoto(photoId))
          .thenThrow(Exception('Delete failed'));

      // Act & Assert
      expect(
        () => photoService.deletePhoto(photoId),
        throwsA(isA<AppError>()),
      );
    });
  });

  group('refreshPhotos', () {
    test('should fetch fresh photos and update cache', () async {
      // Arrange
      final mockPhotos = TestData.getMockPhotos();
      when(mockPhotoRepository.fetchPhotos())
          .thenAnswer((_) async => mockPhotos);

      // Act
      await photoService.refreshPhotos();

      // Assert
      verify(mockPhotoRepository.fetchPhotos()).called(1);
      verify(mockCacheService.put(
        'photos',
        mockPhotos.map((p) => p.toJson()).toList(),
      )).called(1);
    });

    test('should throw AppError when refresh fails', () async {
      // Arrange
      when(mockPhotoRepository.fetchPhotos())
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => photoService.refreshPhotos(),
        throwsA(isA<AppError>()),
      );
    });
  });

  group('URL generation', () {
    test('should generate correct thumbnail URL', () {
      // Arrange
      const filename = 'test.jpg';
      const expected = '${TestData.baseUrl}${TestData.thumbnailPath}/test.jpg';

      // Act
      final result = photoService.getThumbnailUrl(filename);

      // Assert
      expect(result, equals(expected));
    });

    test('should generate correct full photo URL', () {
      // Arrange
      const filename = 'test.jpg';
      const expected = '${TestData.baseUrl}${TestData.photosPath}/test.jpg';

      // Act
      final result = photoService.getPhotoUrl(filename);

      // Assert
      expect(result, equals(expected));
    });
  });

  group('generateMoreLikeThis', () {
    test('should call repository with correct parameters', () async {
      // Arrange
      const sourcePhoto = 'test_photo';
      const additionalPrompt = 'more vibrant';
      const count = 3;
      const seed = 42;

      // Act
      await photoService.generateMoreLikeThis(
        sourcePhoto: sourcePhoto,
        additionalPrompt: additionalPrompt,
        count: count,
        seed: seed,
      );

      // Assert
      verify(mockPhotoRepository.generatePhotos(
        sourcePhoto: sourcePhoto,
        additionalPrompt: additionalPrompt,
        count: count,
        seed: seed,
      )).called(1);
      verify(mockCacheService.remove('photos')).called(1);
    });

    test('should throw AppError when generation fails', () async {
      // Arrange
      when(mockPhotoRepository.generatePhotos(
        sourcePhoto: any,
        additionalPrompt: any,
        count: any,
        seed: any,
      )).thenThrow(Exception('Generation failed'));

      // Act & Assert
      expect(
        () => photoService.generateMoreLikeThis(
          sourcePhoto: 'test',
          additionalPrompt: '',
          count: 1,
        ),
        throwsA(isA<AppError>()),
      );
    });
  });
}
