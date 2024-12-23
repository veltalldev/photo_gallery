// lib/main.dart
import 'package:flutter/material.dart';
import 'package:photo_gallery/core/di/service_locator.dart';
import 'package:photo_gallery/screens/gallery_screen.dart';

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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GalleryScreen(),
    );
  }
}
