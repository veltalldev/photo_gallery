// test/helpers/mock_helpers.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:photo_gallery/repositories/interfaces/i_photo_repository.dart';
import 'package:photo_gallery/services/interfaces/i_cache_service.dart';
import 'package:photo_gallery/services/interfaces/i_photo_cache_manager.dart';
import 'package:photo_gallery/services/interfaces/i_photo_service.dart';
import 'package:photo_gallery/models/domain/photo.dart';
import 'package:photo_gallery/core/errors/cache_error.dart';
import 'package:photo_gallery/core/errors/photo_error.dart';

// Generate mocks for our interfaces
@GenerateNiceMocks([
  MockSpec<IPhotoRepository>(),
  MockSpec<ICacheService>(),
  MockSpec<IPhotoCacheManager>(),
  MockSpec<http.Client>(as: #MockHttpClient),
  MockSpec<IPhotoService>(),
])
void main() {}

// Test data generators
class TestData {
  static const baseUrl = 'http://47.151.18.30:8000';
  static const photosPath = '/photos';
  static const thumbnailPath = '/photos/thumbnail';

  static List<Photo> getMockPhotos({int count = 3}) {
    return List.generate(
      count,
      (index) => Photo(
        id: 'test_photo_$index',
        filename: 'test_photo_$index.jpg',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        thumbnailUrl: '$baseUrl$thumbnailPath/test_photo_$index.jpg',
        fullImageUrl: '$baseUrl$photosPath/test_photo_$index.jpg',
      ),
    );
  }

  static Photo getMockPhoto({String? id}) {
    final photoId = id ?? 'test_photo';
    return Photo(
      id: photoId,
      filename: '$photoId.jpg',
      createdAt: DateTime.now(),
      thumbnailUrl: '$baseUrl$thumbnailPath/$photoId.jpg',
      fullImageUrl: '$baseUrl$photosPath/$photoId.jpg',
    );
  }

  static CacheError getMockCacheError([String? message]) {
    return CacheError(message ?? 'Mock cache error');
  }

  static PhotoLoadError getMockPhotoError([String? message, String? code]) {
    return PhotoLoadError(message: message, code: code);
  }
}

// Custom test matchers
class PhotoMatcher extends Matcher {
  final Photo expected;

  PhotoMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Photo) return false;
    return item.id == expected.id &&
        item.filename == expected.filename &&
        item.thumbnailUrl == expected.thumbnailUrl &&
        item.fullImageUrl == expected.fullImageUrl &&
        ((item.createdAt == null && expected.createdAt == null) ||
            (item.createdAt
                    ?.isAtSameMomentAs(expected.createdAt ?? DateTime(0)) ??
                false));
  }

  @override
  Description describe(Description description) =>
      description.add('matches photo ${expected.id}');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is! Photo) {
      return mismatchDescription.add('is not a Photo');
    }
    if (item.id != expected.id) {
      mismatchDescription.add('has id ${item.id} instead of ${expected.id}');
    }
    // Add other field comparisons as needed
    return mismatchDescription;
  }
}

Matcher matchesPhoto(Photo photo) => PhotoMatcher(photo);
