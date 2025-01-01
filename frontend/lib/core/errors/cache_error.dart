import 'app_error.dart';

class CacheError extends AppError {
  CacheError(String message) : super(message, 'CACHE_ERROR');
}
