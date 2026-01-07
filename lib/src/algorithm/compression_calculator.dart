import 'dart:math' as math;

class CompressionTarget {
  final int width;
  final int height;
  final int estimatedSizeKb;
  final bool isLongImage;
  final int? targetSizeKb;

  CompressionTarget({
    required this.width,
    required this.height,
    required this.estimatedSizeKb,
    this.isLongImage = false,
    this.targetSizeKb,
  });
}

class CompressionCalculator {
  static const int baseShort = 1440;
  static const int wallLong = 10800;
  static const double wallRatio = 0.4;
  static const int trapPixels = 40960000;
  static const int capPixels = 10240000;

  CompressionTarget calculateTarget(int width, int height) {
    if (width <= 0 || height <= 0) {
      return CompressionTarget(width: 0, height: 0, estimatedSizeKb: 0);
    }

    final int shortSide = math.min(width, height);
    final int longSide = math.max(width, height);
    final double ratio = shortSide / longSide;
    final int pixelCount = width * height;

    int targetShort = baseShort;
    int targetLong = ((targetShort / ratio)).round();

    if (longSide >= wallLong && ratio > wallRatio) {
      targetLong = baseShort;
      targetShort = ((targetLong * ratio)).round();
    }

    if (pixelCount > trapPixels) {
      final int trapShort = (shortSide * 0.25).round();
      if (trapShort < targetShort) {
        targetShort = trapShort;
        targetLong = ((targetShort / ratio)).round();
      }
    }

    if (targetShort > shortSide) {
      targetShort = shortSide;
      targetLong = longSide;
    }

    final int currentPixels = targetShort * targetLong;
    if (currentPixels > capPixels) {
      final double scale = (math.sqrt(capPixels / currentPixels) * 1000).floor() / 1000.0;
      targetShort = (targetShort * scale).round();
      targetLong = (targetLong * scale).round();
    }

    targetShort = (targetShort ~/ 2) * 2;
    targetLong = (targetLong ~/ 2) * 2;

    targetShort = math.max(2, targetShort);
    targetLong = math.max(2, targetLong);

    final int finalW;
    final int finalH;
    if (width < height) {
      finalW = targetShort;
      finalH = targetLong;
    } else {
      finalW = targetLong;
      finalH = targetShort;
    }

    final int finalPixels = finalW * finalH;

    double factor;
    if (finalPixels < 500000) {
      factor = 0.0005;
    } else if (finalPixels < 1000000) {
      factor = 0.00015;
    } else if (finalPixels < 3000000) {
      factor = 0.00011;
    } else {
      factor = 0.000025;
    }

    int estimatedSize = (finalPixels * factor).round();
    estimatedSize = math.max(20, estimatedSize);

    if (ratio < 0.2 && estimatedSize < 400) {
      estimatedSize = math.max(estimatedSize, 250);
    }

    final bool isLongImage = ratio <= 0.5;
    final int? targetSizeKb = isLongImage ? estimatedSize : null;

    return CompressionTarget(
      width: finalW,
      height: finalH,
      estimatedSizeKb: estimatedSize,
      isLongImage: isLongImage,
      targetSizeKb: targetSizeKb,
    );
  }
}

