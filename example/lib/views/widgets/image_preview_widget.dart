import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/image_data.dart';

class ImagePreviewWidget extends StatelessWidget {
  final ImageData? imageData;
  final String title;
  final int? bytes;
  final VoidCallback? onTap;

  const ImagePreviewWidget({
    super.key,
    this.imageData,
    required this.title,
    this.bytes,
    this.onTap,
  });

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (imageData == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '暂无图片',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: ImagePainter(imageData!.image),
                  ),
                  if (onTap != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (bytes != null) ...[
          const SizedBox(height: 8),
          Text(
            '大小: ${_formatBytes(bytes!)}',
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            '尺寸: ${imageData!.width} × ${imageData!.height}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ],
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;

  ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = (size.width / image.width).clamp(0.0, size.height / image.height);
    final double scaledWidth = image.width * scale;
    final double scaledHeight = image.height * scale;
    final double offsetX = (size.width - scaledWidth) / 2;
    final double offsetY = (size.height - scaledHeight) / 2;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) => oldDelegate.image != image;
}

