// lib/screens/gallery_screen.dart

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:photo_gallery/features/gallery/widgets/photo_grid_view.dart';
import 'package:photo_gallery/services/interfaces/i_photo_service.dart';
import 'package:photo_gallery/features/viewer/widgets/full_screen_photo_viewer.dart';
import 'package:photo_gallery/models/domain/photo.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _isGenerating = false;
  final _photoService = GetIt.I<IPhotoService>();

  void _onPhotoTap(BuildContext context, Photo photo, List<Photo> photos) {
    final index = photos.indexOf(photo);
    if (index == -1) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoViewer(
          photos: photos,
          initialIndex: index,
          isGenerating: _isGenerating,
          photoService: GetIt.I<IPhotoService>(),
          onGenerateMore: (additionalPrompt, count, seed) {
            Navigator.pop(context);
            _triggerMoreLikeThis(additionalPrompt, count, seed, photo);
          },
        ),
      ),
    );
  }

  Future<void> _triggerMoreLikeThis(
    String additionalPrompt,
    int count,
    int? seed,
    Photo photo,
  ) async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Start generation
      await _photoService.generateMoreLikeThis(
        sourcePhoto: photo.id,
        additionalPrompt: additionalPrompt,
        count: count,
        seed: seed,
      );

      // Force cache refresh immediately
      await _photoService.getCacheService().remove('photos');
      if (mounted) {
        setState(() {});
      }

      // Poll with cache bypassing
      final waitTime = count * 15;
      for (var i = 0; i < waitTime; i += 2) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          await _photoService.getCacheService().remove('photos');
          setState(() {});
          print('Forcing cache refresh...'); // Debug print
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Photo>>(
      future: _photoService.getPhotos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final photos = snapshot.data!;
        print('Photo count: ${photos.length}');
        return PhotoGridView(
          photos: photos,
          photoService: _photoService,
          onPhotoTap: (photo) => _onPhotoTap(context, photo, photos),
          onRefresh: () async {
            await _photoService.getCacheService().remove('photos');
            setState(() {});
          },
        );
      },
    );
  }
}
