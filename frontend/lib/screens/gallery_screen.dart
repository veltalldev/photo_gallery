// lib/screens/gallery_screen.dart

import 'package:flutter/material.dart';
import 'package:photo_gallery/widgets/photo_grid_view.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: const PhotoGridView(),
    );
  }
}
