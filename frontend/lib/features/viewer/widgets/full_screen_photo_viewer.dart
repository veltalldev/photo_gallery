// lib/widgets/full_screen_viewer.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_gallery/widgets/generation_bottom_sheet.dart';

class FullScreenPhotoViewer extends StatefulWidget {
  // final String currentPhoto;
  final List<String> photos;
  final int initialIndex;
  final String baseUrl;
  final bool isGenerating;
  final Function(String additionalPrompt, int count, int? seed)? onGenerateMore;

  const FullScreenPhotoViewer({
    super.key,
    // required this.currentPhoto,
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

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showGenerationOptions() {
    showGenerationOptions(
      context,
      onSubmit: widget.onGenerateMore!,
      isGenerating: widget.isGenerating,
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
            // Page View for swipeable photos
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.photos.length,
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                return InteractiveViewer(
                  child: Hero(
                    tag: photo,
                    child: CachedNetworkImage(
                      imageUrl: '${widget.baseUrl}/photos/$photo',
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.error,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Navigation controls overlay
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    if (widget.onGenerateMore != null)
                      IconButton(
                        icon:
                            const Icon(Icons.auto_awesome, color: Colors.white),
                        onPressed:
                            widget.isGenerating ? null : _showGenerationOptions,
                      ),
                    // IconButton(
                    //   icon: const Icon(Icons.delete),
                    //   onPressed: () {
                    //     Navigator.of(context).pop();
                    //     _showDeleteDialog(photo);
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
            // Left/Right navigation buttons
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
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
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
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
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
