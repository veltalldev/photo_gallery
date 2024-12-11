// lib/main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

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
  // bool _isGenerating = false;
  String _error = '';

  // Replace with your PC's local IP address when testing on physical device
  //final String baseUrl = 'http://localhost:8000';
  final String baseUrl = 'http://192.168.4.26:8000';
  // final String invokeAiUrl = 'http://192.168.4.26:9090';

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

  // Future<void> _triggerGeneration() async {
  //   try {
  //     setState(() {
  //       _isGenerating = true;
  //     });

  //     final response = await http.post(
  //       Uri.parse('$invokeAiUrl/api/v1/queue/default/enqueue_batch'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Accept': 'application/json',
  //       },
  //       body: json.encode({
  //         "batch": {
  //           "batch_id": "flutter_batch_001",
  //           "origin": "flutter_app",
  //           "destination": "default",
  //           "data": [
  //             [
  //               {
  //                 "node_path": "main",
  //                 "field_name": "prompt",
  //                 "items": ["a photograph of a cat"]
  //               }
  //             ]
  //           ],
  //           "graph": {
  //             "id": "default",
  //             "nodes": {
  //               "main": {
  //                 "id": "main",
  //                 "type": "sdxl_img2img", // Using a type from the valid list
  //                 "is_intermediate": false,
  //                 "use_cache": true,
  //                 "width": 1024,
  //                 "height": 1024,
  //                 "seed": 12345,
  //                 "cfg_scale": 7.5,
  //                 "steps": 30
  //               }
  //             },
  //             "edges": []
  //           },
  //           "runs": 1
  //         },
  //         "prepend": false
  //       }),
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Generation started!')),
  //       );

  //       // Refresh the gallery after a delay to show new images
  //       Future.delayed(const Duration(seconds: 5), () {
  //         _loadPhotos();
  //       });
  //     } else {
  //       throw Exception(
  //           'Failed to start generation: ${response.statusCode}\nResponse: ${response.body}');
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e')),
  //     );
  //   } finally {
  //     setState(() {
  //       _isGenerating = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        actions: [
          // IconButton(
          //   icon: _isGenerating
          //       ? const SizedBox(
          //           width: 20,
          //           height: 20,
          //           child: CircularProgressIndicator(
          //             strokeWidth: 2,
          //             color: Colors.white,
          //           ),
          //         )
          //       : const Icon(
          //           Icons.auto_awesome), // or any other icon you prefer
          //   onPressed: _isGenerating ? null : _triggerGeneration,
          //   tooltip: 'Generate new images',
          // ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPhotos,
          ),
        ],
      ),
      body: _buildBody(),
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
        itemBuilder: (context, index) {
          final photo = _photos[index];
          return GestureDetector(
            onTap: () => _showFullScreenImage(context, photo),
            child: Hero(
              tag: photo,
              child: CachedNetworkImage(
                imageUrl: '$baseUrl/photos/$photo',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                InteractiveViewer(
                  child: Hero(
                    tag: photo,
                    child: CachedNetworkImage(
                      imageUrl: '$baseUrl/photos/$photo',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
