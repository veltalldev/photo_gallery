import 'package:photo_gallery/core/errors/app_error.dart';
import 'package:photo_gallery/core/errors/photo_error.dart';
import 'package:photo_gallery/core/errors/network_error.dart';
import 'package:photo_gallery/core/errors/server_error.dart';
import 'package:photo_gallery/core/errors/validation_error.dart';

class MockAppError extends AppError {
  MockAppError({required String message, String? code}) : super(message, code);
}

class MockPhotoError extends PhotoError {
  MockPhotoError({required String message, String? code})
      : super(message, code);
}

class MockNetworkError extends NetworkError {
  MockNetworkError({required String message, String? code})
      : super(message, code);
}

class MockServerError extends ServerError {
  MockServerError({
    required String message,
    String? code,
    required int statusCode,
  }) : super(message: message, code: code, statusCode: statusCode);
}

class MockValidationError extends ValidationError {
  MockValidationError({
    required String message,
    String? code,
    required Map<String, List<String>> errors,
  }) : super(message, code, errors);
}

/// Helper class for creating mock errors in tests
class MockErrorHelper {
  /// Creates a generic app error
  static AppError getMockAppError({
    String message = 'Mock error message',
    String? code,
  }) =>
      MockAppError(message: message, code: code);

  /// Creates a mock photo error
  static PhotoError getMockPhotoError({
    String message = 'Failed to load photo',
    String? code = 'PHOTO_ERROR',
  }) =>
      MockPhotoError(message: message, code: code);

  /// Creates a mock network error
  static NetworkError getMockNetworkError({
    String message = 'Network connection failed',
    String? code = 'NETWORK_ERROR',
  }) =>
      MockNetworkError(message: message, code: code);

  /// Creates a mock server error
  static ServerError getMockServerError({
    String message = 'Server error occurred',
    String? code = 'SERVER_ERROR',
    int statusCode = 500,
  }) =>
      MockServerError(message: message, code: code, statusCode: statusCode);

  /// Creates a mock validation error
  static ValidationError getMockValidationError({
    String message = 'Validation failed',
    String? code = 'VALIDATION_ERROR',
    Map<String, List<String>> errors = const {},
  }) =>
      MockValidationError(message: message, code: code, errors: errors);
}
