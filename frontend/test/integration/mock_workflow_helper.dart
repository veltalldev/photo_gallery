import 'package:mockito/mockito.dart';
import 'package:photo_gallery/models/domain/photo.dart';
import '../helpers/mock_helpers.mocks.dart';

extension MockPhotoServiceX on MockIPhotoService {
  void setupGetPhotos({
    List<Photo>? photos,
    bool shouldSucceed = true,
    Object? error,
  }) {
    if (shouldSucceed) {
      when(getPhotos()).thenAnswer((_) async => photos ?? []);
    } else {
      when(getPhotos()).thenThrow(error ?? Exception('Mock error'));
    }
  }

  void setupDeletePhoto({bool shouldSucceed = true}) {
    if (shouldSucceed) {
      when(deletePhoto(any)).thenAnswer((_) async {});
    } else {
      when(deletePhoto(any)).thenThrow(Exception('Mock delete error'));
    }
  }
}
