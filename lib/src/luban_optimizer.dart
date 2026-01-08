import 'dart:math' as math;
import 'dart:typed_data';

class LubanOptimizer {
  static const int baseHigh = 1440;

  static const int baseLow = 1080;

  static const int wallLongSide = 10800;

  static const int trapPixelCount = 40960000;

  static const int longImagePixelCap = 10240000;

  static const double fileSizePenaltyThreshold = 10 * 1024;

  static const double fileSizePenaltyScale = 0.75;

  static const int longImageSizeCap = 180;

  static const double baseFactor = 0.000025;

  LubanTarget calculateTarget(
    int width,
    int height, [
    double sourceSizeKb = double.infinity,
  ]) {
    if (width <= 0 || height <= 0) {
      return LubanTarget(width: 0, height: 0, estimatedSizeKb: 0);
    }

    final int shortSide = width < height ? width : height;
    final int longSide = width < height ? height : width;
    final double ratio = shortSide / longSide;
    final int pixelCount = width * height;

    int targetShort = shortSide;
    int targetLong = longSide;
    final bool isLongImage = ratio <= 0.5;

    if (isLongImage) {
      if (pixelCount > longImagePixelCap) {
        final double rawScale = math.sqrt(longImagePixelCap / pixelCount);
        final double scale = (rawScale * 1000).floor() / 1000.0;
        targetShort = (shortSide * scale).round();
        targetLong = (longSide * scale).round();
      }
    } else {
      int baseTarget;
      if (longSide >= wallLongSide) {
        baseTarget = baseLow;
      } else {
        baseTarget = baseHigh;
      }

      int proposedShort = baseTarget;

      if (pixelCount >= trapPixelCount) {
        const double scaleSubsample = 0.25;
        final int subsampledShort = (shortSide * scaleSubsample).round();
        proposedShort = math.min(proposedShort, subsampledShort);
      }

      if (proposedShort < shortSide) {
        final double scale = proposedShort / shortSide;
        targetShort = (shortSide * scale).round();
        targetLong = (longSide * scale).round();
      }

      if (sourceSizeKb > fileSizePenaltyThreshold) {
        targetShort = (targetShort * fileSizePenaltyScale).round();
        targetLong = (targetLong * fileSizePenaltyScale).round();
      }
    }

    targetShort = (targetShort ~/ 2) * 2;
    targetLong = (targetLong ~/ 2) * 2;

    while ((targetShort * targetLong) > longImagePixelCap) {
      if (targetLong > targetShort) {
        targetLong -= 2;
      } else {
        targetShort -= 2;
      }
    }

    int finalW;
    int finalH;
    if (width < height) {
      finalW = targetShort;
      finalH = targetLong;
    } else {
      finalW = targetLong;
      finalH = targetShort;
    }

    if ((finalW * finalH) > (width * height)) {
      finalW = width;
      finalH = height;
    }

    final int finalPixels = finalW * finalH;
    double estimatedSize = finalPixels * baseFactor;

    if (isLongImage) {
      if (estimatedSize > longImageSizeCap) {
        estimatedSize = longImageSizeCap.toDouble();
      }
    }

    if (sourceSizeKb > 0 && estimatedSize > sourceSizeKb) {
      estimatedSize = sourceSizeKb;
    }

    estimatedSize = math.max(estimatedSize.round(), 20).toDouble();

    return LubanTarget(
      width: finalW,
      height: finalH,
      estimatedSizeKb: estimatedSize.round(),
      quality: 60,
      isLongImage: isLongImage,
      targetSizeKb: isLongImage ? longImageSizeCap : null,
    );
  }

  static Uint8List compressToTargetSize(
    Uint8List Function(int quality) compress,
    int targetSizeKb,
  ) {
    const int low = 5;
    const int high = 95;
    Uint8List? bestData;

    Uint8List testBytes = compress(95);

    if (testBytes.length <= targetSizeKb * 1024) {
      return testBytes;
    }

    int left = low;
    int right = high;

    while (left <= right) {
      final int mid = (left + right) ~/ 2;
      testBytes = compress(mid);

      if (testBytes.length <= targetSizeKb * 1024) {
        bestData = testBytes;
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }

    if (bestData != null) {
      return bestData;
    }

    return compress(5);
  }
}

class LubanTarget {
  final int width;

  final int height;

  final int estimatedSizeKb;

  final int quality;

  final bool shouldSkipCompression;

  final bool isLongImage;

  final int? targetSizeKb;

  LubanTarget({
    required this.width,
    required this.height,
    required this.estimatedSizeKb,
    this.quality = 60,
    this.shouldSkipCompression = false,
    this.isLongImage = false,
    this.targetSizeKb,
  });

  @override
  String toString() {
    return 'LubanTarget(width: $width, height: $height, '
        'estimatedSizeKb: $estimatedSizeKb, quality: $quality, '
        'shouldSkipCompression: $shouldSkipCompression, '
        'isLongImage: $isLongImage, targetSizeKb: $targetSizeKb)';
  }
}
