import 'dart:math' as math;
import 'dart:typed_data';

/// Luban 压缩优化器
///
/// 提供更精细的压缩参数计算和目标大小压缩功能。
/// 实现了自适应统一图像压缩算法 (Adaptive Unified Image Compression)。
class LubanOptimizer {
  /// 高清基准短边（像素）
  static const int baseHigh = 1440;

  /// 标准基准短边（像素）
  static const int baseLow = 1080;

  /// 全景图长边阈值（像素）
  static const int wallLongSide = 10800;

  /// 超大像素陷阱阈值（像素数）约 4096 万像素
  static const int trapPixelCount = 40960000;

  /// 长图像素上限（像素数）约 1024 万像素
  static const int longImagePixelCap = 10240000;

  /// 文件大小惩罚阈值（KB）
  static const double fileSizePenaltyThreshold = 10 * 1024;

  /// 文件大小惩罚缩放系数
  static const double fileSizePenaltyScale = 0.75;

  /// 长图大小上限（KB）
  static const int longImageSizeCap = 180;

  /// 基础压缩因子
  static const double baseFactor = 0.000025;

  /// 计算压缩目标参数
  ///
  /// [width] 原图宽度
  /// [height] 原图高度
  /// [sourceSizeKb] 可选的原图文件大小（KB），用于惩罚超大文件
  ///
  /// 返回包含目标尺寸和压缩参数的 [LubanTarget]
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

  /// 使用二分查找压缩到目标大小
  ///
  /// [compress] 压缩函数，接收质量参数返回压缩后的字节数据
  /// [targetSizeKb] 目标文件大小（KB）
  ///
  /// 返回满足大小要求的最高质量压缩结果
  ///
  /// 在质量 5-95 范围内进行二分查找，找到满足目标大小的最高质量值。
  /// 如果最高质量已满足要求，直接返回；如果最低质量仍无法满足，返回最低质量结果。
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

/// Luban 压缩目标参数
///
/// 包含压缩后的目标尺寸、预估大小、压缩质量等完整信息
class LubanTarget {
  /// 目标宽度（像素）
  final int width;

  /// 目标高度（像素）
  final int height;

  /// 预估压缩后大小（KB）
  final int estimatedSizeKb;

  /// 压缩质量（1-100）
  final int quality;

  /// 是否应跳过压缩（原图已足够小）
  final bool shouldSkipCompression;

  /// 是否为长图（宽高比 <= 0.5）
  final bool isLongImage;

  /// 长图的目标文件大小（KB），非长图为 null
  final int? targetSizeKb;

  /// 创建压缩目标参数
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
