// lib/core/errors/app_error.dart
abstract class AppError implements Exception {
  final String message;
  final String? code;

  AppError(this.message, this.code);

  @override
  String toString() => '$code: $message';
}

// class NetworkError extends AppError {...}
// class PhotoError extends AppError {...}
// class CacheError extends AppError {...}
