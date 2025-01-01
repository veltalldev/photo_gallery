import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:photo_gallery/screens/gallery_screen.dart';
import '../helpers/mock_helpers.dart';
import '../helpers/mock_helpers.mocks.dart';
import '../widgets/errors/mock_error_helper.dart';
import 'mock_workflow_helper.dart';

void main() {
  late MockIPhotoService mockPhotoService;

  setUp(() {
    mockPhotoService = MockIPhotoService();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GalleryScreen(),
      ),
    );
  }

  group('Photo Gallery Workflow', () {
    testWidgets('shows loading, then photos, handles refresh',
        (WidgetTester tester) async {
      // Setup mock responses
      final mockPhotos = TestData.getMockPhotos(count: 4);
      mockPhotoService.setupGetPhotos(photos: mockPhotos);

      // Initial load
      await pumpApp(tester);

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for photos to load
      await tester.pumpAndSettle();

      // Verify photos are displayed
      expect(find.byType(GridTile), findsNWidgets(4));

      // Test pull-to-refresh
      await tester.drag(find.byType(GridView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Verify refresh was called
      verify(mockPhotoService.refreshPhotos()).called(1);
    });

    testWidgets('handles error states and retry', (WidgetTester tester) async {
      // Setup mock to fail first time, succeed second time
      mockPhotoService.setupGetPhotos(
        shouldSucceed: false,
        error: MockErrorHelper.getMockPhotoError(),
      );

      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Verify error state
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Setup success for retry
      mockPhotoService.setupGetPhotos(
        shouldSucceed: true,
        photos: TestData.getMockPhotos(),
      );

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify photos loaded
      expect(find.byType(GridTile), findsWidgets);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('photo selection and deletion workflow',
        (WidgetTester tester) async {
      final mockPhotos = TestData.getMockPhotos(count: 3);
      mockPhotoService.setupGetPhotos(photos: mockPhotos);

      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Long press to start selection mode
      await tester.longPress(find.byType(GridTile).first);
      await tester.pumpAndSettle();

      // Verify selection mode UI
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);

      // Select another photo
      await tester.tap(find.byType(GridTile).at(1));
      await tester.pumpAndSettle();

      // Verify multiple selection
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));

      // Setup delete success
      mockPhotoService.setupDeletePhoto(shouldSucceed: true);

      // Delete selected photos
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Verify deletion dialog
      expect(find.text('Delete Photos?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify photos were deleted
      verify(mockPhotoService.deletePhoto(any)).called(2);
      verify(mockPhotoService.refreshPhotos()).called(1);
    });

    testWidgets('photo generation workflow', (WidgetTester tester) async {
      final mockPhotos = TestData.getMockPhotos();
      mockPhotoService.setupGetPhotos(photos: mockPhotos);

      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Tap generate on first photo
      await tester.tap(find.byIcon(Icons.auto_awesome).first);
      await tester.pumpAndSettle();

      // Verify generation sheet appears
      expect(find.text('Generate Similar Photos'), findsOneWidget);

      // Fill in generation form
      await tester.enterText(find.byType(TextField), 'Make it more colorful');
      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();

      // Verify generation was called
      verify(mockPhotoService.generateMoreLikeThis(
        sourcePhoto: mockPhotos[0].id,
        additionalPrompt: 'Make it more colorful',
        count: any,
      )).called(1);
    });
  });
}
