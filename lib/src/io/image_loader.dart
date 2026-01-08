import 'dart:typed_data';
import 'dart:ui' as ui;

class ImageData {
  final Uint8List rgbaData;
  final int width;
  final int height;
  final double fileSizeKb;

  ImageData({
    required this.rgbaData,
    required this.width,
    required this.height,
    required this.fileSizeKb,
  });
}

abstract class ImageLoader {
  Future<ImageData> loadFromBytes(Uint8List imageBytes, int targetWidth, int targetHeight);
}

class FlutterImageLoader implements ImageLoader {
  @override
  Future<ImageData> loadFromBytes(
    Uint8List imageBytes,
    int targetWidth,
    int targetHeight,
  ) async {
    final double fileSizeKb = imageBytes.length / 1024.0;
    return _loadFromBytesInternal(imageBytes, targetWidth, targetHeight, fileSizeKb);
  }

  Future<ImageData> _loadFromBytesInternal(
    Uint8List imageBytes,
    int targetWidth,
    int targetHeight,
    double fileSizeKb,
  ) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    try {
      ui.Image imageToProcess = image;
      int processWidth = image.width;
      int processHeight = image.height;

      if (targetWidth > 0 && targetHeight > 0) {
        if (targetWidth != image.width || targetHeight != image.height) {
          imageToProcess = await _resizeImage(image, targetWidth, targetHeight);
          processWidth = targetWidth;
          processHeight = targetHeight;
        }
      }

      final Uint8List rgbaData = await _imageToRgba(imageToProcess);

      if (imageToProcess != image) {
        imageToProcess.dispose();
      }

      return ImageData(
        rgbaData: rgbaData,
        width: processWidth,
        height: processHeight,
        fileSizeKb: fileSizeKb,
      );
    } finally {
      image.dispose();
    }
  }

  Future<Uint8List> _imageToRgba(ui.Image image) async {
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    return byteData!.buffer.asUint8List();
  }

  Future<ui.Image> _resizeImage(
    ui.Image image,
    int targetWidth,
    int targetHeight,
  ) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      ui.Paint(),
    );
    final ui.Picture picture = recorder.endRecording();
    return picture.toImage(targetWidth, targetHeight);
  }
}
