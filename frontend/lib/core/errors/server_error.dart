import 'app_error.dart';

abstract class ServerError extends AppError {
  final int statusCode;

  ServerError(String message, String? code, this.statusCode)
      : super(message, code);
}
