import 'package:photo_gallery/models/domain/photo.dart';
import 'package:photo_gallery/core/errors/photo_error.dart';

/// Helper class containing test data and mock repository functionality
class TestData {
  /// Base URL used for testing photo URLs
  static const baseUrl = 'http://47.151.18.30:8000';

  /// Path for thumbnail images
  static const thumbnailPath = '/photos/thumbnail';

  /// Path for full-size photos
  static const photosPath = '/photos';

  /// Creates a mock photo with the given ID
  static Photo getMockPhoto({String id = 'test_1'}) {
    return Photo(
      id: id,
      filename: '$id.jpg',
      createdAt: DateTime(2023),
      thumbnailUrl: '$baseUrl$thumbnailPath/$id.jpg',
      fullImageUrl: '$baseUrl$photosPath/$id.jpg',
    );
  }

  /// Creates a list of mock photos
  static List<Photo> getMockPhotos({int count = 3}) {
    return List.generate(
      count,
      (i) => getMockPhoto(id: 'test_${i + 1}'),
    );
  }
}

class MockRepositoryHelper {
  static PhotoLoadError getMockPhotoError([String? message, String? code]) {
    return PhotoLoadError(
      message: message ?? 'Mock photo error',
      code: code ?? 'MOCK_ERROR',
    );
  }
}
