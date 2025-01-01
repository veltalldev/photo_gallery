import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_gallery/widgets/errors/error_boundary.dart';
import 'mock_error_helper.dart';

void main() {
  testWidgets('ErrorBoundary shows child when no error occurs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ErrorBoundary(
          onError: (_, __) => const SizedBox(),
          child: const Text('Test Child'),
        ),
      ),
    );

    expect(find.text('Test Child'), findsOneWidget);
  });

  testWidgets('ErrorBoundary shows error widget when error occurs',
      (WidgetTester tester) async {
    final mockError = MockErrorHelper.getMockAppError(
      message: 'Test error message',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ErrorBoundary(
          onError: (context, error) => Text(error.toString()),
          child: Builder(
            builder: (context) => throw mockError,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text(mockError.toString()), findsOneWidget);
  });

  testWidgets('ErrorBoundary resets error state when dependencies change',
      (WidgetTester tester) async {
    final mockError = MockErrorHelper.getMockAppError();

    await tester.pumpWidget(
      MaterialApp(
        home: ErrorBoundary(
          onError: (context, error) => const Text('Error State'),
          child: Builder(
            builder: (context) => throw mockError,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Error State'), findsOneWidget);

    // Change dependencies by updating the widget
    await tester.pumpWidget(
      MaterialApp(
        home: ErrorBoundary(
          onError: (context, error) => const Text('Error State'),
          child: const Text('Recovered'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Recovered'), findsOneWidget);
    expect(find.text('Error State'), findsNothing);
  });

  testWidgets('defaultErrorWidget shows correct message for AppError',
      (WidgetTester tester) async {
    final mockError = MockErrorHelper.getMockAppError(
      message: 'Custom error message',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ErrorBoundary.defaultErrorWidget(
          tester.element(find.byType(MaterialApp)),
          mockError,
        ),
      ),
    );

    expect(find.text('Custom error message'), findsOneWidget);
  });
}
