import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'algorithm/compression_calculator.dart';
import 'compression/compressor.dart';
import 'compression/jpeg_compressor.dart';

Future<Uint8List> _compressInIsolate(Map<String, dynamic> params) async {
  final rgbaData = params['rgbaData'] as Uint8List;
  final width = params['width'] as int;
  final height = params['height'] as int;
  final targetSizeKb = params['targetSizeKb'] as int?;
  final fixedQuality = params['fixedQuality'] as int?;

  final compressor = JpegCompressor();
  try {
    return compressor.compress(
      rgbaData,
      width,
      height,
      targetSizeKb: targetSizeKb,
      fixedQuality: fixedQuality,
    );
  } finally {
    compressor.dispose();
  }
}

/// Luban 图片压缩器
///
/// 高效的图片压缩工具，像素级还原微信朋友圈压缩策略。
/// 基于 TurboJPEG 原生库实现高性能 JPEG 压缩。
///
/// 使用示例:
/// ```dart
/// final compressedBytes = await Luban.compress(
///   imageBytes,
///   image.width,
///   image.height,
/// );
/// ```
///
/// 批量压缩:
/// ```dart
/// final results = await Luban.compressBatch(
///   imageBytesList,
///   widths,
///   heights,
/// );
/// ```
class Luban {
  final CompressionCalculator _calculator;

  /// 创建 Luban 实例
  ///
  /// [compressor] 已废弃，压缩操作现在在 Isolate 中执行，此参数将被忽略
  /// [calculator] 可选的自定义压缩参数计算器，默认使用 [CompressionCalculator]
  Luban({
    Compressor? compressor,
    CompressionCalculator? calculator,
  })  : _calculator = calculator ?? CompressionCalculator();

  static final Luban _defaultInstance = Luban();

  /// 压缩单张图片
  ///
  /// [imageBytes] 原始图片的字节数据
  /// [width] 图片宽度（像素）
  /// [height] 图片高度（像素）
  ///
  /// 返回压缩后的 JPEG 图片字节数据
  ///
  /// 压缩策略会根据图片特征自动调整：
  /// - 标准图片：以 1440px 为短边基准进行缩放
  /// - 长图：建立像素上限防止 OOM
  /// - 全景图：锁定长边为 1440px
  /// - 超大像素图：自动执行降采样
  static Future<Uint8List> compress(
    Uint8List imageBytes,
    int width,
    int height,
  ) async {
    return _defaultInstance.compressInternal(imageBytes, width, height);
  }

  /// 批量压缩多张图片
  ///
  /// [imageBytesList] 原始图片字节数据列表
  /// [widths] 对应图片的宽度列表
  /// [heights] 对应图片的高度列表
  ///
  /// 返回压缩后的图片字节数据列表，顺序与输入一致
  ///
  /// 所有图片将并发处理以提高效率
  static Future<List<Uint8List>> compressBatch(
    List<Uint8List> imageBytesList,
    List<int> widths,
    List<int> heights,
  ) async {
    return _defaultInstance.compressBatchInternal(
      imageBytesList,
      widths,
      heights,
    );
  }

  /// 内部压缩实现
  ///
  /// 用于非静态方法调用，允许使用自定义的压缩器和计算器
  Future<Uint8List> compressInternal(
    Uint8List imageBytes,
    int width,
    int height,
  ) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    final target = _calculator.calculateTarget(width, height);

    ui.Image imageToCompress = image;
    int compressWidth = width;
    int compressHeight = height;

    if (target.width != width || target.height != height) {
      imageToCompress = await _resizeImage(image, target.width, target.height);
      compressWidth = target.width;
      compressHeight = target.height;
    }

    final Uint8List rgbaData = await _imageToRgba(imageToCompress);

    final int? targetSizeKb = target.targetSizeKb;
    final int? fixedQuality = target.isLongImage ? null : 60;

    final Uint8List compressedBytes = await compute(
      _compressInIsolate,
      {
        'rgbaData': rgbaData,
        'width': compressWidth,
        'height': compressHeight,
        'targetSizeKb': targetSizeKb,
        'fixedQuality': fixedQuality,
      },
    );

    if (imageToCompress != image) {
      imageToCompress.dispose();
    }

    return compressedBytes;
  }

  /// 内部批量压缩实现
  Future<List<Uint8List>> compressBatchInternal(
    List<Uint8List> imageBytesList,
    List<int> widths,
    List<int> heights,
  ) async {
    final List<Future<Uint8List>> futures = [];
    for (int i = 0; i < imageBytesList.length; i++) {
      futures.add(compressInternal(imageBytesList[i], widths[i], heights[i]));
    }
    return Future.wait(futures);
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
