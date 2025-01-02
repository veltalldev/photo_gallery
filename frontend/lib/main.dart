// lib/main.dart
import 'package:flutter/material.dart';
import 'package:photo_gallery/core/di/service_locator.dart';
import 'package:photo_gallery/screens/landing_page_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Gallery',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          // Optional: customize brightness
          brightness: Brightness.light,
        ),
      ),
      home: const LandingPageScreen(),
    );
  }
}
