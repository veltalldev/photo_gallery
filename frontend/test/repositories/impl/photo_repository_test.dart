// test/repositories/impl/photo_repository_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:photo_gallery/core/errors/photo_error.dart';
import 'package:photo_gallery/repositories/impl/photo_repository.dart';
import '../../helpers/mock_helpers.mocks.dart';
import 'mock_repository_helper.dart';

void main() {
  late MockHttpClient mockHttpClient;
  late MockICacheService mockCacheService;
  late PhotoRepository photoRepository;
  const baseUrl = 'http://47.151.18.30:8000';

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockCacheService = MockICacheService();
    photoRepository = PhotoRepository(
      client: mockHttpClient,
      cacheService: mockCacheService,
    );
  });

  group('fetchPhotos', () {
    test('should return list of photos on successful API call', () async {
      // Arrange
      final mockResponse =
          jsonEncode(['photo1.jpg', 'photo2.jpg', 'photo3.jpg']);
      when(mockHttpClient.get(Uri.parse('$baseUrl/api/photos')))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      // Act
      final photos = await photoRepository.fetchPhotos();

      // Assert
      expect(photos.length, equals(3));
      expect(photos[0].filename, equals('photo1.jpg'));
      expect(photos[0].thumbnailUrl,
          equals('$baseUrl/photos/thumbnail/photo1.jpg'));
      expect(photos[0].fullImageUrl, equals('$baseUrl/photos/photo1.jpg'));
      verify(mockHttpClient.get(Uri.parse('$baseUrl/api/photos'))).called(1);
    });

    test('should handle empty response from API', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse('$baseUrl/api/photos')))
          .thenAnswer((_) async => http.Response('[]', 200));

      // Act
      final photos = await photoRepository.fetchPhotos();

      // Assert
      expect(photos, isEmpty);
    });

    test('should throw PhotoError on network error', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse('$baseUrl/api/photos')))
          .thenThrow(MockRepositoryHelper.getMockPhotoError('Network error'));

      // Act & Assert
      expect(
        () => photoRepository.fetchPhotos(),
        throwsA(isA<PhotoLoadError>()),
      );
    });

    test('should throw exception on non-200 response', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse('$baseUrl/api/photos')))
          .thenAnswer((_) async => http.Response('Server error', 500));

      // Act & Assert
      expect(
        () => photoRepository.fetchPhotos(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to load photos: 500'),
        )),
      );
    });
  });

  group('fetchPhoto', () {
    const photoId = 'test_photo.jpg';

    test('should return photo on successful API call', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse('$baseUrl/api/photos/$photoId')))
          .thenAnswer((_) async => http.Response('{}', 200));

      // Act
      final photo = await photoRepository.fetchPhoto(photoId);

      // Assert
      expect(photo, isNotNull);
      expect(photo?.id, equals(photoId));
      expect(photo?.thumbnailUrl, equals('$baseUrl/photos/thumbnail/$photoId'));
      expect(photo?.fullImageUrl, equals('$baseUrl/photos/$photoId'));
    });

    test('should return null on 404 response', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse('$baseUrl/api/photos/$photoId')))
          .thenAnswer((_) async => http.Response('Not found', 404));

      // Act
      final photo = await photoRepository.fetchPhoto(photoId);

      // Assert
      expect(photo, isNull);
    });

    test('should throw exception on network error', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse('$baseUrl/api/photos/$photoId')))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => photoRepository.fetchPhoto(photoId),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Error fetching photo'),
        )),
      );
    });
  });

  group('deletePhoto', () {
    const photoId = 'test_photo.jpg';

    test('should complete successfully on 200 response', () async {
      // Arrange
      when(mockHttpClient.delete(Uri.parse('$baseUrl/api/photos/$photoId')))
          .thenAnswer((_) async => http.Response('', 200));

      // Act & Assert
      expect(
        () => photoRepository.deletePhoto(photoId),
        completes,
      );
    });

    test('should throw exception on non-200 response', () async {
      // Arrange
      when(mockHttpClient.delete(Uri.parse('$baseUrl/api/photos/$photoId')))
          .thenAnswer((_) async => http.Response('Error', 500));

      // Act & Assert
      expect(
        () => photoRepository.deletePhoto(photoId),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to delete photo'),
        )),
      );
    });

    test('should throw exception on network error', () async {
      // Arrange
      when(mockHttpClient.delete(Uri.parse('$baseUrl/api/photos/$photoId')))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => photoRepository.deletePhoto(photoId),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('generatePhotos', () {
    const sourcePhoto = 'source.jpg';
    final mockMetadata = {
      'prompt': 'original prompt',
      'model': {'name': 'test_model'},
    };

    test('should handle successful generation request', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse('$baseUrl/api/metadata/$sourcePhoto')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(mockMetadata), 200));

      when(mockHttpClient.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: any,
      )).thenAnswer((_) async => http.Response('{"batch_id": "test"}', 200));

      // Act & Assert
      expect(
        () => photoRepository.generatePhotos(
          sourcePhoto: sourcePhoto,
          additionalPrompt: 'more vibrant',
          count: 3,
          seed: 42,
        ),
        completes,
      );

      // Verify the generation request
      verify(mockHttpClient.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: any,
      )).called(1);
    });

    test('should throw exception when metadata fetch fails', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse('$baseUrl/api/metadata/$sourcePhoto')))
          .thenAnswer((_) async => http.Response('Error', 500));

      // Act & Assert
      expect(
        () => photoRepository.generatePhotos(
          sourcePhoto: sourcePhoto,
          additionalPrompt: '',
          count: 1,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to get metadata'),
        )),
      );
    });

    test('should throw exception when generation request fails', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse('$baseUrl/api/metadata/$sourcePhoto')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(mockMetadata), 200));

      when(mockHttpClient.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: any,
      )).thenAnswer((_) async => http.Response('Error', 500));

      // Act & Assert
      expect(
        () => photoRepository.generatePhotos(
          sourcePhoto: sourcePhoto,
          additionalPrompt: '',
          count: 1,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to trigger generation'),
        )),
      );
    });

    test('should include additional prompt in generation request', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse('$baseUrl/api/metadata/$sourcePhoto')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(mockMetadata), 200));

      when(mockHttpClient.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: any,
      )).thenAnswer((_) async => http.Response('{"batch_id": "test"}', 200));

      // Act
      await photoRepository.generatePhotos(
        sourcePhoto: sourcePhoto,
        additionalPrompt: 'more vibrant',
        count: 1,
      );

      // Assert
      verify(mockHttpClient.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: argThat(contains('more vibrant')),
      )).called(1);
    });
  });

  test('baseUrl should return configured URL', () {
    expect(photoRepository.baseUrl, equals(baseUrl));
  });
}
