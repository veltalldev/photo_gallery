import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:photo_gallery/main.dart'; // Update with your actual app name

import 'photo_gallery_test.mocks.dart';

// Generate mock HTTP client
@GenerateMocks([http.Client])
void main() {
  late MockClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockClient();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: PhotoGalleryScreen(client: mockHttpClient),
    );
  }

  group('PhotoGalleryScreen Widget Tests', () {
    testWidgets('Shows loading state initially', (WidgetTester tester) async {
      // Set up a Completer to control when the API response returns
      final completer = Completer<http.Response>();
      when(mockHttpClient.get(any)).thenAnswer((_) => completer.future);

      // Build our widget
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify loading state immediately after building
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the API call
      completer.complete(http.Response('[]', 200));

      // Pump all remaining microtasks
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Shows error state when API fails',
        (WidgetTester tester) async {
      // Mock API failure with immediate response
      when(mockHttpClient.get(any))
          .thenAnswer((_) async => http.Response('Server error', 500));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify error state
      expect(find.text('Failed to load photos: 500'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget); // Retry button
    });

    testWidgets('Shows empty state when no photos',
        (WidgetTester tester) async {
      // Mock empty response
      when(mockHttpClient.get(any))
          .thenAnswer((_) async => http.Response('[]', 200));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify empty state
      expect(find.text('No photos found'), findsOneWidget);
    });

    testWidgets('Shows grid of photos when loaded successfully',
        (WidgetTester tester) async {
      // Mock successful photos response
      const mockPhotos = '["photo1.jpg", "photo2.jpg", "photo3.jpg"]';
      when(mockHttpClient.get(any))
          .thenAnswer((_) async => http.Response(mockPhotos, 200));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest());

        // Wait for the initial frame
        await tester.pump();

        // Wait for the loading state
        await tester.pump(const Duration(milliseconds: 100));

        // Wait for the grid to be built
        await tester.pump(const Duration(milliseconds: 100));

        // Verify grid view is shown
        expect(find.byType(GridView), findsOneWidget);

        // Verify the number of grid items
        final gridView = tester.widget<GridView>(find.byType(GridView));
        expect(
          (gridView.childrenDelegate as SliverChildBuilderDelegate).childCount,
          3,
        );
      });
    });

    testWidgets('Pull to refresh triggers reload', (WidgetTester tester) async {
      // Mock responses with some photos so we get a GridView
      final List<http.Response> responses = [
        http.Response('["photo1.jpg", "photo2.jpg"]', 200),
        http.Response('["photo1.jpg", "photo2.jpg"]', 200),
      ];
      var callCount = 0;

      when(mockHttpClient.get(any)).thenAnswer((_) async {
        final response = responses[callCount];
        callCount++;
        return response;
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify first call happened
      expect(callCount, 1);

      // Find the scroll view within RefreshIndicator
      final scrollable = find.byType(Scrollable);
      expect(scrollable, findsOneWidget);

      // Perform the pull to refresh gesture
      await tester.drag(scrollable, const Offset(0, 300));
      await tester.pump(); // Start the refresh indicator animation
      await tester.pump(const Duration(seconds: 1)); // Complete the gesture
      await tester.pump(const Duration(seconds: 1)); // Complete the refresh

      // Verify second call happened
      expect(callCount, 2,
          reason: 'Expected two API calls after pull-to-refresh');
    });
  });
}
