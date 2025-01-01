import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_gallery/widgets/errors/photo_error_boundary.dart';
import 'mock_error_helper.dart';

void main() {
  testWidgets('PhotoErrorBoundary shows child when no error occurs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PhotoErrorBoundary(
          child: Text('Test Child'),
        ),
      ),
    );

    expect(find.text('Test Child'), findsOneWidget);
  });

  testWidgets(
      'PhotoErrorBoundary shows error UI with retry button for PhotoError',
      (WidgetTester tester) async {
    bool retryPressed = false;
    final mockError = MockErrorHelper.getMockPhotoError(
      message: 'Photo load failed',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PhotoErrorBoundary(
          onRetry: () => retryPressed = true,
          child: Builder(
            builder: (context) => throw mockError,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify error UI elements
    expect(find.text('Photo load failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Test retry button
    await tester.tap(find.text('Retry'));
    expect(retryPressed, isTrue);
  });

  testWidgets(
      'PhotoErrorBoundary shows error UI without retry for non-PhotoError',
      (WidgetTester tester) async {
    final mockError = MockErrorHelper.getMockAppError(
      message: 'Generic error',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PhotoErrorBoundary(
          onRetry: () {},
          child: Builder(
            builder: (context) => throw mockError,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Generic error'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });
}
