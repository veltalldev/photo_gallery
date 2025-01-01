import 'app_error.dart';

abstract class NetworkError extends AppError {
  NetworkError(String message, String? code) : super(message, code);
}

class ConnectionError extends NetworkError {
  ConnectionError({required String message, String? code})
      : super(message, code ?? 'CONNECTION_ERROR');
}

class TimeoutError extends NetworkError {
  TimeoutError({required String message, String? code})
      : super(message, code ?? 'TIMEOUT_ERROR');
}
