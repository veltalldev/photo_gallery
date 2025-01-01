import 'app_error.dart';

abstract class ValidationError extends AppError {
  final Map<String, List<String>> errors;

  ValidationError(String message, String? code, this.errors)
      : super(message, code);
}
