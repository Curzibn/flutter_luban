import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../../services/image_service.dart';

class FullScreenImageViewer extends StatefulWidget {
  final ui.Image image;
  final String title;

  const FullScreenImageViewer({
    super.key,
    required this.image,
    required this.title,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final ImageService _imageService = ImageService();
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final Uint8List imageBytes = await _imageService.imageToPng(widget.image);
    setState(() {
      _imageProvider = MemoryImage(imageBytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _imageProvider == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : PhotoView(
              imageProvider: _imageProvider,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              heroAttributes: PhotoViewHeroAttributes(
                tag: widget.title,
              ),
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),
    );
  }
}

