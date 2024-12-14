// lib/core/errors/app_error.dart
abstract class AppError implements Exception {
  final String message;
  final dynamic cause;

  AppError(this.message, [this.cause]);

  @override
  String toString() =>
      'AppError: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

class NetworkError extends AppError {
  NetworkError(String message, [dynamic cause]) : super(message, cause);
}

class PhotoError extends AppError {
  PhotoError(String message, [dynamic cause]) : super(message, cause);
}

class CacheError extends AppError {
  CacheError(String message, [dynamic cause]) : super(message, cause);
}
