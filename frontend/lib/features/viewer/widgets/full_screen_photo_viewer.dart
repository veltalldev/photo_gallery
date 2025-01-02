import 'package:flutter/material.dart';
import 'package:photo_gallery/widgets/errors/photo_error_boundary.dart';
import 'package:photo_gallery/features/generation/widgets/generation_bottom_sheet.dart';
import 'package:photo_gallery/models/domain/photo.dart';
import 'package:photo_gallery/services/interfaces/i_photo_service.dart';
import 'package:photo_gallery/core/errors/photo_error.dart';
import 'package:photo_gallery/widgets/image_providers/photo_cache_image_provider.dart';

class FullScreenPhotoViewer extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;
  final bool isGenerating;
  final IPhotoService photoService;
  final Function(String, int, int?) onGenerateMore;

  const FullScreenPhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.isGenerating,
    required this.photoService,
    required this.onGenerateMore,
  });

  @override
  State<FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _retryLoadImage() async {
    setState(() {});
  }

  Widget _buildImageView(Photo photo) {
    if (photo.fullImageUrl == null) {
      return const Center(
        child: Text('Image URL not available',
            style: TextStyle(color: Colors.white)),
      );
    }

    return PhotoErrorBoundary(
      onRetry: _retryLoadImage,
      child: InteractiveViewer(
        child: Hero(
          tag: photo.id,
          child: Image(
            image: PhotoCacheImageProvider(
              url: photo.fullImageUrl!,
              cacheService: widget.photoService.getCacheService(),
            ),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              throw PhotoLoadError();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main content
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: widget.photos.length,
              itemBuilder: (context, index) =>
                  _buildImageView(widget.photos[index]),
            ),
            // Controls overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black45,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${widget.photos.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, color: Colors.white),
                      onPressed: widget.isGenerating
                          ? null
                          : () => showGenerationOptions(
                                context,
                                onSubmit: (prompt, count, seed) {
                                  widget.onGenerateMore(prompt, count, seed);
                                },
                                isGenerating: widget.isGenerating,
                              ),
                    ),
                  ],
                ),
              ),
            ),
            // Navigation buttons
            if (widget.photos.length > 1) ...[
              // Previous button
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _currentIndex > 0
                      ? IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              // Next button
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _currentIndex < widget.photos.length - 1
                      ? IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
