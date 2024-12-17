// test/helpers/mock_helpers.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:photo_gallery/repositories/interfaces/i_photo_repository.dart';
import 'package:photo_gallery/services/interfaces/i_cache_service.dart';
import 'package:photo_gallery/services/interfaces/i_photo_service.dart';
import 'package:photo_gallery/models/domain/photo.dart';

// Generate mocks for our interfaces
@GenerateNiceMocks([
  MockSpec<IPhotoRepository>(),
  MockSpec<ICacheService>(),
  MockSpec<http.Client>(as: #MockHttpClient),
])
void main() {}

// Test data generators
class TestData {
  static List<Photo> getMockPhotos({int count = 3}) {
    return List.generate(
      count,
      (index) => Photo(
        id: 'test_photo_$index',
        filename: 'test_photo_$index.jpg',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        thumbnailUrl:
            'http://localhost:8000/photos/thumbnail/test_photo_$index.jpg',
        fullImageUrl: 'http://localhost:8000/photos/test_photo_$index.jpg',
      ),
    );
  }

  static Photo getMockPhoto({String? id}) {
    final photoId = id ?? 'test_photo';
    return Photo(
      id: photoId,
      filename: '$photoId.jpg',
      createdAt: DateTime.now(),
      thumbnailUrl: 'http://localhost:8000/photos/thumbnail/$photoId.jpg',
      fullImageUrl: 'http://localhost:8000/photos/$photoId.jpg',
    );
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
        item.fullImageUrl == expected.fullImageUrl;
  }

  @override
  Description describe(Description description) =>
      description.add('matches photo ${expected.id}');
}
