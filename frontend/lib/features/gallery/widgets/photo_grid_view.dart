import 'package:flutter/material.dart';
import 'package:photo_gallery/models/domain/photo.dart';
import 'package:photo_gallery/services/interfaces/i_photo_service.dart';
import 'package:photo_gallery/widgets/common/gradient_scaffold.dart';
import 'package:photo_gallery/widgets/image_providers/photo_cache_image_provider.dart';

class PhotoGridView extends StatelessWidget {
  final List<Photo> photos;
  final IPhotoService photoService;
  final Function(Photo) onPhotoTap;
  final Future<void> Function() onRefresh;

  // Breakpoints for responsive design
  static const double _narrowScreenWidth = 600;
  static const double _wideScreenWidth = 900;

  const PhotoGridView({
    super.key,
    required this.photos,
    required this.photoService,
    required this.onPhotoTap,
    required this.onRefresh,
  });

  int _calculateColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < _narrowScreenWidth) {
      return 2; // Phone
    } else if (width < _wideScreenWidth) {
      return 3; // Tablet/Small Desktop
    } else {
      return 4; // Large Desktop
    }
  }

  @override
  Widget build(BuildContext context) {
    final columnCount = _calculateColumnCount(context);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top +
                  kToolbarHeight, // Space for AppBar
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return RefreshIndicator(
                  onRefresh: onRefresh,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return _buildPhotoCard(context, photo, index);
                    },
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: ScrollController(keepScrollOffset: false),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false, // Don't add padding at top
                left: false, // Don't add padding at left
                right: false, // Don't add padding at right
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.add_photo_alternate_outlined,
                        label: 'Add',
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.favorite_border,
                        label: 'Favorites',
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.collections_outlined,
                        label: 'Albums',
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, Photo photo, int index) {
    final isNarrow = MediaQuery.of(context).size.width < _narrowScreenWidth;

    return Card(
      elevation: isNarrow ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isNarrow ? 8 : 12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with Hero animation
            Hero(
              tag: photo.id,
              child: Image(
                image: PhotoCacheImageProvider(
                  url: photo.thumbnailUrl ?? photo.fullImageUrl!,
                  cacheService: photoService.getCacheService(),
                ),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 32,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
            // Ripple effect and touch feedback
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onPhotoTap(photo),
                splashColor: Colors.white24,
                highlightColor: Colors.white10,
              ),
            ),
            // Optional: Add a gradient overlay at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Text(
                  index.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: () {
        // Show a snackbar for now
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label action not implemented'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
