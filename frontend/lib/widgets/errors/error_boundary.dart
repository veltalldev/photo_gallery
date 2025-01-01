// lib/widgets/error_boundaries/error_boundary.dart
import 'package:flutter/material.dart';
import 'package:photo_gallery/core/errors/app_error.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, Object)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
  });

  /// Default error widget builder that can be used by all error boundaries
  static Widget defaultErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            error is AppError ? error.message : error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  Widget _buildErrorWidget(Object error) {
    return widget.onError?.call(context, error) ??
        ErrorBoundary.defaultErrorWidget(context, error);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _error = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget(_error!);
    }

    ErrorWidget.builder = (FlutterErrorDetails details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _error = details.exception;
        });
      });
      return _buildErrorWidget(details.exception);
    };

    return widget.child;
  }
}
