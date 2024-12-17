// test/features/gallery/widgets/photo_grid_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:photo_gallery/features/viewer/widgets/full_screen_photo_viewer.dart';
import 'package:photo_gallery/features/gallery/widgets/photo_grid_view.dart';
import 'package:photo_gallery/models/domain/photo.dart';
import 'package:photo_gallery/core/errors/app_error.dart';
import '../../../helpers/mock_helpers.dart';
import '../../../helpers/mock_helpers.mocks.dart';

void main() {
  late MockIPhotoService mockPhotoService;

  setUp(() {
    mockPhotoService = MockIPhotoService();
  });

  Future<void> pumpPhotoGrid(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoGridView(
          photoService: mockPhotoService,
        ),
      ),
    );
  }

  group('PhotoGridView', () {
    testWidgets('should display loading indicator initially',
        (WidgetTester tester) async {
      // Arrange
      when(mockPhotoService.getPhotos()).thenAnswer(
        (_) async => Future.delayed(
          const Duration(milliseconds: 100),
          () => TestData.getMockPhotos(),
        ),
      );

      // Act
      await pumpPhotoGrid(tester);

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display photos in a grid', (WidgetTester tester) async {
      // Arrange
      final mockPhotos = TestData.getMockPhotos(count: 6);
      when(mockPhotoService.getPhotos()).thenAnswer((_) async => mockPhotos);
      when(mockPhotoService.getThumbnailUrl(any)).thenAnswer((invocation) =>
          'http://localhost:8000/photos/thumbnail/${invocation.positionalArguments[0]}');

      // Act
      await mockNetworkImagesFor(() async {
        await pumpPhotoGrid(tester);
        await tester.pumpAndSettle();
      });

      // Assert
      expect(find.byType(GridView), findsOneWidget);
      // We should find 6 images in the grid
      expect(find.byType(Hero), findsNWidgets(6));
    });

    testWidgets('should handle photo selection mode',
        (WidgetTester tester) async {
      // Arrange
      final mockPhotos = TestData.getMockPhotos(count: 3);
      when(mockPhotoService.getPhotos()).thenAnswer((_) async => mockPhotos);

      // Act
      await mockNetworkImagesFor(() async {
        await pumpPhotoGrid(tester);
        await tester.pumpAndSettle();

        // Long press to enter selection mode
        await tester.longPress(find.byType(Hero).first);
        await tester.pumpAndSettle();
      });

      // Assert
      // Should show selection UI
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('should navigate to full screen viewer on tap',
        (WidgetTester tester) async {
      // Arrange
      final mockPhotos = TestData.getMockPhotos(count: 3);
      when(mockPhotoService.getPhotos()).thenAnswer((_) async => mockPhotos);

      // Act
      await mockNetworkImagesFor(() async {
        await pumpPhotoGrid(tester);
        await tester.pumpAndSettle();

        // Tap the first photo
        await tester.tap(find.byType(Hero).first);
        await tester.pumpAndSettle();
      });

      // Assert
      expect(find.byType(FullScreenPhotoViewer), findsOneWidget);
    });

    testWidgets('should handle photo deletion', (WidgetTester tester) async {
      // Arrange
      final mockPhotos = TestData.getMockPhotos(count: 3);
      when(mockPhotoService.getPhotos()).thenAnswer((_) async => mockPhotos);
      when(mockPhotoService.deletePhoto(any)).thenAnswer((_) async {});

      // Act
      await mockNetworkImagesFor(() async {
        await pumpPhotoGrid(tester);
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.longPress(find.byType(Hero).first);
        await tester.pumpAndSettle();

        // Tap delete
        await tester.tap(find.byIcon(Icons.delete));
        await tester.pumpAndSettle();
      });

      // Assert
      verify(mockPhotoService.deletePhoto(mockPhotos[0].id)).called(1);
    });

    testWidgets('should handle multiple photo selection',
        (WidgetTester tester) async {
      // Arrange
      final mockPhotos = TestData.getMockPhotos(count: 3);
      when(mockPhotoService.getPhotos()).thenAnswer((_) async => mockPhotos);

      // Act
      await mockNetworkImagesFor(() async {
        await pumpPhotoGrid(tester);
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.longPress(find.byType(Hero).first);
        await tester.pumpAndSettle();

        // Select second photo
        await tester.tap(find.byType(Hero).at(1));
        await tester.pumpAndSettle();
      });

      // Assert
      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('should handle refresh action', (WidgetTester tester) async {
      // Arrange
      final mockPhotos = TestData.getMockPhotos(count: 3);
      when(mockPhotoService.getPhotos()).thenAnswer((_) async => mockPhotos);

      // Act
      await mockNetworkImagesFor(() async {
        await pumpPhotoGrid(tester);
        await tester.pumpAndSettle();

        // Trigger refresh
        await tester.drag(find.byType(GridView), const Offset(0, 300));
        await tester.pumpAndSettle();
      });

      // Assert
      // getPhotos should be called twice - once on initial load, once on refresh
      verify(mockPhotoService.getPhotos()).called(2);
    });

    testWidgets('should display error state when photo loading fails',
        (WidgetTester tester) async {
      // Arrange
      when(mockPhotoService.getPhotos())
          .thenThrow(PhotoError('Failed to load photos'));

      // Act
      await pumpPhotoGrid(tester);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Failed to load photos'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should allow retry when in error state',
        (WidgetTester tester) async {
      // Arrange
      var firstCall = true;
      when(mockPhotoService.getPhotos()).thenAnswer((_) async {
        if (firstCall) {
          firstCall = false;
          throw PhotoError('Failed to load photos');
        }
        return TestData.getMockPhotos();
      });

      // Act
      await pumpPhotoGrid(tester);
      await tester.pumpAndSettle();

      // Tap retry button
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      verify(mockPhotoService.getPhotos()).called(2);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should handle generation button press',
        (WidgetTester tester) async {
      // Arrange
      final mockPhotos = TestData.getMockPhotos(count: 3);
      when(mockPhotoService.getPhotos()).thenAnswer((_) async => mockPhotos);

      // Act
      await mockNetworkImagesFor(() async {
        await pumpPhotoGrid(tester);
        await tester.pumpAndSettle();

        // Tap first photo to enter full screen
        await tester.tap(find.byType(Hero).first);
        await tester.pumpAndSettle();

        // Tap generate button
        await tester.tap(find.byIcon(Icons.auto_awesome));
        await tester.pumpAndSettle();
      });

      // Assert
      // Should show generation bottom sheet
      expect(find.text('Generate Similar Images'), findsOneWidget);
    });

    testWidgets('should respect grid layout constraints',
        (WidgetTester tester) async {
      // Arrange
      final mockPhotos = TestData.getMockPhotos(count: 6);
      when(mockPhotoService.getPhotos()).thenAnswer((_) async => mockPhotos);

      // Act
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 300, // Constrained width
              height: 500, // Constrained height
              child: PhotoGridView(
                photoService: mockPhotoService,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      });

      // Assert
      final GridView gridView = tester.widget<GridView>(find.byType(GridView));
      final SliverGridDelegateWithFixedCrossAxisCount delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
      expect(delegate.crossAxisSpacing, 8.0);
      expect(delegate.mainAxisSpacing, 8.0);
    });
  });
}
