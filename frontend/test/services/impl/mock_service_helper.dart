import 'package:mockito/mockito.dart';
import 'package:photo_gallery/models/domain/photo.dart';
import 'package:photo_gallery/services/impl/photo_service.dart';
import '../../helpers/mock_helpers.dart';

class MockPhotoService extends Mock implements PhotoService {
  @override
  Future<Photo?> getPhoto(String? id) => super.noSuchMethod(
        Invocation.method(#getPhoto, [id]),
        returnValue: Future.value(TestData.getMockPhoto()),
      );

  @override
  Future<void> deletePhoto(String? id) => super.noSuchMethod(
        Invocation.method(#deletePhoto, [id]),
        returnValue: Future<void>.value(),
      );

  @override
  String getPhotoUrl(String? filename) => super.noSuchMethod(
        Invocation.method(#getPhotoUrl, [filename]),
        returnValue: '${TestData.baseUrl}${TestData.photosPath}/$filename',
      );

  @override
  String getThumbnailUrl(String? filename) => super.noSuchMethod(
        Invocation.method(#getThumbnailUrl, [filename]),
        returnValue: '${TestData.baseUrl}${TestData.thumbnailPath}/$filename',
      );

  @override
  Future<void> refreshPhotos() => super.noSuchMethod(
        Invocation.method(#refreshPhotos, []),
        returnValue: Future<void>.value(),
      );

  @override
  Future<void> generateMoreLikeThis({
    String? sourcePhoto,
    String? additionalPrompt,
    int? count,
    int? seed,
  }) =>
      super.noSuchMethod(
        Invocation.method(#generateMoreLikeThis, [], {
          #sourcePhoto: sourcePhoto,
          #additionalPrompt: additionalPrompt,
          #count: count,
          #seed: seed,
        }),
        returnValue: Future<void>.value(),
      );

  void setupGetPhotos({
    bool shouldSucceed = true,
    List<Photo>? photos,
    Exception? error,
  }) {
    if (shouldSucceed) {
      when(getPhotos()).thenAnswer(
        (_) async => photos ?? TestData.getMockPhotos(),
      );
    } else {
      when(getPhotos()).thenThrow(error ?? Exception('Mock error'));
    }
  }

  void setupDeletePhoto({
    bool shouldSucceed = true,
    String? photoId,
    Exception? error,
  }) {
    if (shouldSucceed) {
      when(deletePhoto(photoId ?? any)).thenAnswer((_) async {});
    } else {
      when(deletePhoto(photoId ?? any))
          .thenThrow(error ?? Exception('Delete failed'));
    }
  }

  void setupGetPhoto({
    bool shouldSucceed = true,
    String? id,
    Photo? returnedPhoto,
    Exception? error,
  }) {
    if (shouldSucceed) {
      when(getPhoto(id ?? any)).thenAnswer(
        (_) async => returnedPhoto ?? TestData.getMockPhoto(id: id),
      );
    } else {
      when(getPhoto(id ?? any))
          .thenThrow(error ?? Exception('Get photo failed'));
    }
  }

  void verifyGetPhotos({int times = 1}) {
    verify(getPhotos()).called(times);
  }

  void verifyDeletePhoto({required String photoId, int times = 1}) {
    verify(deletePhoto(photoId)).called(times);
  }
}
