import 'app_error.dart';

abstract class NetworkError extends AppError {
  NetworkError(String message, String? code) : super(message, code);
}
