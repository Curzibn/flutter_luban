import 'dart:typed_data';
import 'dart:ui' as ui;

class ImageData {
  final Uint8List bytes;
  final ui.Image image;
  final int width;
  final int height;

  ImageData({
    required this.bytes,
    required this.image,
    required this.width,
    required this.height,
  });
}

