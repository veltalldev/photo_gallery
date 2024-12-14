import 'dart:collection';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_gallery/services/photo_cache_manager.dart';
import 'package:photo_gallery/features/viewer/widgets/full_screen_photo_viewer.dart';
import 'package:photo_gallery/widgets/errors/photo_error_boundary.dart';
import 'package:photo_gallery/core/errors/app_error.dart';

class PhotoGridView extends StatefulWidget {
  final http.Client? client;

  const PhotoGridView({
    super.key,
    this.client,
  });

  @override
  State<PhotoGridView> createState() => _PhotoGridViewState();
}

class _PhotoGridViewState extends State<PhotoGridView>
    with AutomaticKeepAliveClientMixin {
  late final http.Client _client;
  List<String> _photos = [];
  // bool _isLoading = true;
  bool _isGenerating = false;

  // Replace with your PC's local IP address when testing on physical device
  //final String baseUrl = 'http://localhost:8000';
  final String baseUrl = 'http://192.168.4.26:8000';

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? http.Client();
    _loadPhotos();
  }

  @override
  void dispose() {
    if (widget.client == null) {
      _client.close();
    }
    _imageCache.clear();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  final int maxCachedImages = 100; // Cache limit (~36MB for WebP thumbnails)
  final LinkedHashMap<String, ImageProvider> _imageCache = LinkedHashMap();
  final Set<String> _selectedPhotos = {};
  bool _isSelectionMode = false;

  String _getThumbnailUrl(String photo) {
    // final baseName = photo.replaceAll('.png', '');
    // return '$baseUrl/photos/thumbnail/$baseName.webp';
    return '$baseUrl/photos/thumbnail/$photo';
  }

  ImageProvider _getImageProvider(String photo) {
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
    String photo, // Add this parameter
  ) async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // First, get the metadata for the selected image
      final metadataResponse = await _client.get(
        Uri.parse('$baseUrl/api/metadata/$photo'), // Use the passed photo
      );

      if (metadataResponse.statusCode != 200) {
        throw Exception(
            'Failed to get image metadata: ${metadataResponse.statusCode}');
      }

      final metadata = json.decode(metadataResponse.body);

      // Update seed if specified
      if (seed != null) {
        metadata['seed'] = seed;
      }

      // Trigger new generation with modified metadata
      final generationResponse = await _client.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image_name': photo, // Use the passed photo
          'metadata': metadata,
          'use_random_seed': seed == null,
          'seed': seed,
          'quantity': count,
          ...additionalPrompt.isNotEmpty
              ? {'additional_prompt': additionalPrompt}
              : {}
        }),
      );

      if (generationResponse.statusCode == 200 ||
          generationResponse.statusCode == 201) {
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
      } else {
        throw Exception(
            'Failed to start generation: ${generationResponse.statusCode}');
      }
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
      final response = await _client.get(Uri.parse('$baseUrl/api/photos'));

      if (response.statusCode == 200) {
        final List<dynamic> photoList = json.decode(response.body);
        setState(() {
          _photos = photoList.cast<String>();
        });
      } else {
        throw PhotoError(
          'Failed to load photos: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw PhotoError(
        'Error loading photos',
        e,
      );
    }
  }

  Future<void> _deleteSelectedPhotos() async {
    for (String photo in _selectedPhotos) {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/photos/$photo'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _photos.remove(photo);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete $photo')),
        );
      }
    }
    setState(() {
      _selectedPhotos.clear();
      _isSelectionMode = false;
    });
  }

  void _showFullScreenImage(BuildContext context, String photo) {
    final currentIndex = _photos.indexOf(photo);
    if (currentIndex == -1) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoViewer(
          photos: _photos,
          initialIndex: currentIndex,
          baseUrl: baseUrl,
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

  Widget _buildGridItem(String photo) {
    final isSelected = _selectedPhotos.contains(photo);

    return PhotoErrorBoundary(
      onRetry: () => _loadPhotos, // Force rebuild to retry loading
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
              tag: photo,
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
              // Let the error boundary handle the error
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
