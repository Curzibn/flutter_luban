import 'dart:typed_data';
import '../turbo_jpeg.dart';
import 'compressor.dart';

/// 基于 TurboJPEG 的 JPEG 压缩器实现
///
/// 使用 TurboJPEG 原生库进行高性能 JPEG 编码。
/// 支持固定质量压缩和目标大小自适应压缩两种模式。
class JpegCompressor implements Compressor {
  final TurboJpeg _turboJpeg;

  /// 创建 JPEG 压缩器实例
  JpegCompressor() : _turboJpeg = TurboJpeg();

  /// 压缩 RGBA 格式的图片数据为 JPEG
  ///
  /// 压缩模式优先级：
  /// 1. 如果指定 [fixedQuality]，使用固定质量压缩
  /// 2. 如果指定 [targetSizeKb]，使用二分查找找到最佳质量
  /// 3. 否则使用默认质量 60 压缩
  ///
  /// 对于目标大小压缩，使用二分查找算法在质量 5-95 范围内
  /// 找到满足大小要求的最高质量值。
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

    return bestData ?? _turboJpeg.compress(
      rgbaData,
      width,
      height,
      quality: 5,
    );
  }

  /// 释放压缩器资源
  ///
  /// 调用后压缩器将不可用，需要重新创建实例
  void dispose() {
    _turboJpeg.dispose();
  }
}
