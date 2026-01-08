import 'dart:typed_data';

/// 图片压缩器抽象接口
///
/// 定义了图片压缩的标准接口，允许不同的压缩实现。
/// 默认实现为 [JpegCompressor]，基于 TurboJPEG 库。
abstract class Compressor {
  /// 压缩 RGBA 格式的图片数据
  ///
  /// [rgbaData] RGBA 格式的原始像素数据，每像素 4 字节
  /// [width] 图片宽度（像素）
  /// [height] 图片高度（像素）
  /// [targetSizeKb] 可选的目标文件大小（KB），用于长图的自适应压缩
  /// [fixedQuality] 可选的固定压缩质量（1-100），设置后忽略 targetSizeKb
  ///
  /// 返回压缩后的 JPEG 图片字节数据
  Uint8List compress(
    Uint8List rgbaData,
    int width,
    int height, {
    int? targetSizeKb,
    int? fixedQuality,
  });
}
