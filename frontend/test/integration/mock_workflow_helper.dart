import 'package:mockito/mockito.dart';
import 'package:photo_gallery/core/errors/network_error.dart';
import 'package:photo_gallery/core/errors/photo_error.dart';
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

  void setupGeneratePhotos({bool shouldSucceed = true}) {
    if (shouldSucceed) {
      when(generateMoreLikeThis(
        sourcePhoto: any,
        additionalPrompt: any,
        count: any,
        seed: any,
      )).thenAnswer((_) async {});
    } else {
      when(generateMoreLikeThis(
        sourcePhoto: any,
        additionalPrompt: any,
        count: any,
        seed: any,
      )).thenThrow(PhotoLoadError());
    }
  }

  void setupNetworkError() {
    when(getPhotos()).thenThrow(
      ConnectionError(
        message: 'Connection reset by peer',
        code: 'CONNECTION_RESET',
      ),
    );
  }

  void setupTimeout() {
    when(getPhotos()).thenAnswer(
      (_) => Future.delayed(
        const Duration(seconds: 30),
        () => throw TimeoutError(message: 'Request timed out'),
      ),
    );
  }
}
