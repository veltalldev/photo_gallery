import 'app_error.dart';

class ServerError extends AppError {
  final int statusCode;

  ServerError({
    required String message,
    required this.statusCode,
    String? code,
  }) : super(message, code ?? 'SERVER_ERROR');
}
