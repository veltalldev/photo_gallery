// lib/screens/gallery_screen.dart

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:photo_gallery/features/gallery/widgets/photo_grid_view.dart';
import 'package:photo_gallery/services/interfaces/i_photo_service.dart';
import 'package:photo_gallery/services/interfaces/i_cache_service.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PhotoGridView(
      photoService: GetIt.I<IPhotoService>(),
      cacheService: GetIt.I<ICacheService>(),
    );
  }
}
