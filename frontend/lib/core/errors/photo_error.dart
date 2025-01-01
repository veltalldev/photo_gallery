import 'app_error.dart';

abstract class PhotoError extends AppError {
  PhotoError(String message, String? code) : super(message, code);
}

class PhotoLoadError extends PhotoError {
  PhotoLoadError({String? message, String? code})
      : super(message ?? 'Error loading photos', code ?? 'PHOTO_LOAD_ERROR');
}

class PhotoNotFoundError extends PhotoError {
  PhotoNotFoundError({String? message, String? code})
      : super(message ?? 'Photo not found', code ?? 'PHOTO_NOT_FOUND');
}
