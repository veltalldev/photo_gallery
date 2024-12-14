import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_gallery/widgets/errors/photo_error_boundary.dart';
import 'package:photo_gallery/features/generation/widgets/generation_bottom_sheet.dart';

class FullScreenPhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final String baseUrl;
  final bool isGenerating;
  final Function(String, int, int?)? onGenerateMore;

  const FullScreenPhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.baseUrl,
    this.isGenerating = false,
    this.onGenerateMore,
  });

  @override
  State<FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isLoading = false;
  String? _error;

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
    setState(() {
      _error = null;
      _isLoading = true;
    });

    // Add a slight delay to ensure the UI updates
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildImageView(String photo) {
    return PhotoErrorBoundary(
      onRetry: _retryLoadImage,
      child: InteractiveViewer(
        child: Hero(
          tag: photo,
          child: CachedNetworkImage(
            imageUrl: '${widget.baseUrl}/photos/$photo',
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _retryLoadImage,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
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
                    if (widget.onGenerateMore != null)
                      IconButton(
                        icon:
                            const Icon(Icons.auto_awesome, color: Colors.white),
                        onPressed: widget.isGenerating
                            ? null
                            : () => showGenerationOptions(
                                  context,
                                  onSubmit: widget.onGenerateMore!,
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
