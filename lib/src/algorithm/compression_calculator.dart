import 'dart:math' as math;

/// 压缩目标参数
///
/// 包含压缩后的目标尺寸、预估大小等信息
class CompressionTarget {
  /// 目标宽度（像素）
  final int width;

  /// 目标高度（像素）
  final int height;

  /// 预估压缩后大小（KB）
  final int estimatedSizeKb;

  /// 是否为长图（宽高比 <= 0.5）
  final bool isLongImage;

  /// 长图的目标文件大小（KB），非长图为 null
  final int? targetSizeKb;

  /// 创建压缩目标参数
  CompressionTarget({
    required this.width,
    required this.height,
    required this.estimatedSizeKb,
    this.isLongImage = false,
    this.targetSizeKb,
  });
}

/// 压缩参数计算器
///
/// 基于微信朋友圈压缩策略的逆向工程实现。
/// 根据原图特征计算最佳的压缩目标参数。
///
/// 核心策略：
/// - 高清基准 (1440p)：默认以 1440px 作为短边基准
/// - 全景墙策略：超大全景图（长边 >10800px）锁定长边为 1440px
/// - 超大像素陷阱：超过 4096 万像素自动执行 1/4 降采样
/// - 长图内存保护：建立 10.24MP 像素上限防止 OOM
class CompressionCalculator {
  /// 短边基准值（像素）
  static const int baseShort = 1440;

  /// 全景图长边阈值（像素）
  static const int wallLong = 10800;

  /// 全景图判定宽高比阈值
  static const double wallRatio = 0.4;

  /// 超大像素陷阱阈值（像素数）约 4096 万像素
  static const int trapPixels = 40960000;

  /// 像素上限（像素数）约 1024 万像素
  static const int capPixels = 10240000;

  /// 计算压缩目标参数
  ///
  /// [width] 原图宽度
  /// [height] 原图高度
  ///
  /// 返回包含目标尺寸和压缩参数的 [CompressionTarget]
  ///
  /// 对于无效输入（宽或高 <= 0），返回零尺寸目标
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
      final double scale =
          (math.sqrt(capPixels / currentPixels) * 1000).floor() / 1000.0;
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
