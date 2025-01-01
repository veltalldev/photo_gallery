// lib/widgets/error_boundaries/photo_error_boundary.dart
import 'package:flutter/material.dart';
import 'package:photo_gallery/core/errors/app_error.dart';
import 'package:photo_gallery/core/errors/photo_error.dart';
import 'package:photo_gallery/widgets/errors/error_boundary.dart';

class PhotoErrorBoundary extends StatelessWidget {
  final Widget child;
  final VoidCallback? onRetry;

  const PhotoErrorBoundary({
    super.key,
    required this.child,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: child,
      onError: (context, error) => Center(
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
            if (error is PhotoError && onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
