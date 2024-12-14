// lib/widgets/error_boundaries/error_boundary.dart
import 'package:flutter/material.dart';
import 'package:photo_gallery/core/errors/app_error.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, Object) onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _error = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.onError(context, _error!);
    }

    ErrorWidget.builder = (FlutterErrorDetails details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _error = details.exception;
        });
      });
      return widget.onError(context, details.exception);
    };

    return widget.child;
  }

  static Widget defaultErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          error is AppError ? error.message : 'An unexpected error occurred',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
