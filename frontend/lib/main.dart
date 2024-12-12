// lib/main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_gallery/widgets/generation_dialog.dart';
import 'package:photo_gallery/widgets/full_screen_photo_viewer.dart';
import 'package:photo_gallery/widgets/generation_bottom_sheet.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PhotoGalleryScreen(),
    );
  }
}

class PhotoGalleryScreen extends StatefulWidget {
  final http.Client? client;
  const PhotoGalleryScreen({super.key, this.client});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late final http.Client _client;
  List<String> _photos = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  String _error = '';

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
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await _client.get(Uri.parse('$baseUrl/api/photos'));

      if (response.statusCode == 200) {
        final List<dynamic> photoList = json.decode(response.body);
        setState(() {
          _photos = photoList.cast<String>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load photos: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading photos: $e';
        _isLoading = false;
      });
    }
  }

  // Update the trigger function to accept the photo parameter
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

  Widget _buildGridItem(String photo) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, photo),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: photo,
            child: CachedNetworkImage(
              imageUrl: '$baseUrl/photos/$photo',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Photo Gallery',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPhotos,
          ),
        ],
      ),
      body: _buildBody(),
      // floatingActionButton: _selectedPhoto != null
      //     ? FloatingActionButton(
      //         onPressed: _isGenerating ? null : _showGenerationDialog,
      //         child: _isGenerating
      //             ? const SizedBox(
      //                 width: 24,
      //                 height: 24,
      //                 child: CircularProgressIndicator(
      //                   color: Colors.white,
      //                   strokeWidth: 2,
      //                 ),
      //               )
      //             : const Icon(Icons.auto_awesome),
      //       )
      //     : null,
      floatingActionButton: FloatingActionButton(
          onPressed: () => showGenerationOptions(
                context,
                onSubmit: (prompt, count, seed) {
                  // Handle generation
                },
                isGenerating: false, // Set to true while generating
              )),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPhotos,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_photos.isEmpty) {
      return const Center(
        child: Text('No photos found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPhotos,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) => _buildGridItem(_photos[index]),
      ),
    );
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
}
