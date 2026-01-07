import 'dart:typed_data';
import '../turbo_jpeg.dart';
import 'compressor.dart';

class JpegCompressor implements Compressor {
  final TurboJpeg _turboJpeg;

  JpegCompressor() : _turboJpeg = TurboJpeg();

  @override
  Uint8List compress(
    Uint8List rgbaData,
    int width,
    int height, {
    int? targetSizeKb,
    int? fixedQuality,
  }) {
    if (fixedQuality != null) {
      return _turboJpeg.compress(
        rgbaData,
        width,
        height,
        quality: fixedQuality,
      );
    }

    if (targetSizeKb == null) {
      return _turboJpeg.compress(
        rgbaData,
        width,
        height,
        quality: 60,
      );
    }

    const int low = 5;
    const int high = 95;
    Uint8List? bestData;

    final testResult = _turboJpeg.compress(
      rgbaData,
      width,
      height,
      quality: 95,
    );
    final double sizeKb = testResult.length / 1024.0;

    if (sizeKb <= targetSizeKb) {
      return testResult;
    }

    int currentLow = low;
    int currentHigh = high;

    while (currentLow <= currentHigh) {
      final int mid = (currentLow + currentHigh) ~/ 2;

      final compressed = _turboJpeg.compress(
        rgbaData,
        width,
        height,
        quality: mid,
      );
      final double currentSizeKb = compressed.length / 1024.0;

      if (currentSizeKb <= targetSizeKb) {
        bestData = compressed;
        currentLow = mid + 1;
      } else {
        currentHigh = mid - 1;
      }
    }

    if (bestData == null) {
      bestData = _turboJpeg.compress(
        rgbaData,
        width,
        height,
        quality: 5,
      );
    }

    return bestData;
  }

  void dispose() {
    _turboJpeg.dispose();
  }
}

