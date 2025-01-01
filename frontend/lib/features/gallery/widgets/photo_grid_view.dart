import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:photo_gallery/core/errors/app_error.dart';
import 'package:photo_gallery/features/viewer/widgets/full_screen_photo_viewer.dart';
import 'package:photo_gallery/models/domain/photo.dart';
import 'package:photo_gallery/services/interfaces/i_photo_service.dart';
import 'package:photo_gallery/services/photo_cache_manager.dart';
import 'package:photo_gallery/widgets/errors/photo_error_boundary.dart';

class PhotoGridView extends StatefulWidget {
  final IPhotoService photoService;

  const PhotoGridView({
    super.key,
    required this.photoService,
  });

  @override
  State<PhotoGridView> createState() => _PhotoGridViewState();
}

class _PhotoGridViewState extends State<PhotoGridView>
    with AutomaticKeepAliveClientMixin {
  List<Photo> _photos = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  @override
  void dispose() {
    _imageCache.clear();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  final int maxCachedImages = 100; // Cache limit (~36MB for WebP thumbnails)
  final LinkedHashMap<Photo, ImageProvider> _imageCache = LinkedHashMap();
  final Set<Photo> _selectedPhotos = {};
  bool _isSelectionMode = false;

  String _getThumbnailUrl(Photo photo) {
    return widget.photoService.getThumbnailUrl(photo.filename);
  }

  ImageProvider _getImageProvider(Photo photo) {
    if (_imageCache.containsKey(photo)) {
      final provider = _imageCache.remove(photo)!;
      _imageCache[photo] = provider;
      return provider;
    }

    final provider = CachedNetworkImageProvider(
      _getThumbnailUrl(photo),
      cacheManager: PhotoCacheManager(),
    );

    if (_imageCache.length >= maxCachedImages) {
      _imageCache.remove(_imageCache.keys.first);
    }
    _imageCache[photo] = provider;
    return provider;
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
      await widget.photoService.generateMoreLikeThis(
        sourcePhoto: photo.id,
        additionalPrompt: additionalPrompt,
        count: count,
        seed: seed,
      );

      // Estimate completion time (30 seconds per image)
      final waitTime = count * 15;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Generation started! Estimated time: $waitTime seconds'),
          duration: const Duration(seconds: 5),
        ),
      );

      // Optional: Refresh after estimated completion
      Future.delayed(Duration(seconds: waitTime), () {
        _loadPhotos();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _loadPhotos() async {
    try {
      final photos = await widget.photoService.getPhotos();
      setState(() {
        _photos = photos;
      });
    } catch (e) {
      throw PhotoError('Error loading photos', e);
    }
  }

  Future<void> _deleteSelectedPhotos() async {
    for (Photo photo in _selectedPhotos) {
      try {
        await widget.photoService.deletePhoto(photo.id);
        setState(() {
          _photos.remove(photo);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete ${photo.filename}')),
        );
      }
    }
    setState(() {
      _selectedPhotos.clear();
      _isSelectionMode = false;
    });
  }

  void _showFullScreenImage(BuildContext context, Photo photo) {
    final currentIndex = _photos.indexOf(photo);
    if (currentIndex == -1) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoViewer(
          photos: _photos,
          initialIndex: currentIndex,
          isGenerating: _isGenerating,
          onGenerateMore: (additionalPrompt, count, seed) {
            // Close the bottom sheet
            Navigator.pop(context);
            // Trigger generation
            _triggerMoreLikeThis(additionalPrompt, count, seed, photo);
          },
        ),
      ),
    );
  }

  Widget _buildGridItem(Photo photo) {
    final isSelected = _selectedPhotos.contains(photo);

    return PhotoErrorBoundary(
      onRetry: () => _loadPhotos,
      child: GestureDetector(
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedPhotos.remove(photo);
                if (_selectedPhotos.isEmpty) {
                  _isSelectionMode = false;
                }
              } else {
                _selectedPhotos.add(photo);
              }
            });
          } else {
            _showFullScreenImage(context, photo);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedPhotos.add(photo);
            });
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: photo.id,
              child: CachedNetworkImage(
                imageUrl: _getThumbnailUrl(photo),
                cacheManager: PhotoCacheManager(),
                imageBuilder: (context, imageProvider) {
                  final provider = _getImageProvider(photo);
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: provider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
                placeholder: (context, url) {
                  if (_imageCache.containsKey(photo)) {
                    return Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: _imageCache[photo]!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }

                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorWidget: (context, url, error) {
                  throw PhotoError('Failed to load image', error);
                },
              ),
            ),
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  color: Colors.black26,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return PhotoErrorBoundary(
      onRetry: _loadPhotos,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurpleAccent,
          title: _isSelectionMode
              ? Text('${_selectedPhotos.length} selected')
              : const Text('Photo Gallery'),
          actions: [
            if (_isSelectionMode) ...[
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelectedPhotos,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedPhotos.clear();
                    _isSelectionMode = false;
                  });
                },
              ),
            ],
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            try {
              await _loadPhotos();
            } catch (e) {
              throw PhotoError(
                'Failed to refresh photos',
                e,
              );
            }
          },
          child: GridView.builder(
            cacheExtent: MediaQuery.of(context).size.height * 2,
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) => _buildGridItem(_photos[index]),
          ),
        ),
      ),
    );
  }
}
