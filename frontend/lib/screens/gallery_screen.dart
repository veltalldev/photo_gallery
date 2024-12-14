// lib/screens/gallery_screen.dart

import 'package:flutter/material.dart';
import 'package:photo_gallery/features/gallery/widgets/photo_grid_view.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PhotoGridView();
  }
}
