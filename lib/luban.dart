/// Luban Flutter - 高效简洁的图片压缩库
///
/// 像素级还原微信朋友圈压缩策略，基于 TurboJPEG 原生库实现高性能 JPEG 压缩。
///
/// ## 快速开始
///
/// ```dart
/// import 'package:luban/luban.dart';
///
/// final compressedBytes = await Luban.compress(imageBytes, width, height);
/// ```
///
/// ## 主要特性
///
/// - 🚀 高性能：基于 TurboJPEG 原生库
/// - 🎯 智能压缩：自适应压缩算法
/// - 📱 跨平台：支持 Android 和 iOS
/// - 🔧 易于使用：简洁的 API 设计
///
/// ## 核心类
///
/// - [Luban] - 主压缩入口类
/// - [CompressionCalculator] - 压缩参数计算器
/// - [Compressor] - 压缩器抽象接口
/// - [JpegCompressor] - JPEG 压缩器实现
/// - [TurboJpeg] - TurboJPEG 原生库封装
library luban;

export 'src/turbo_jpeg.dart';
export 'src/tj_constants.dart';
export 'src/luban_optimizer.dart';
export 'src/luban.dart';
export 'src/algorithm/compression_calculator.dart';
export 'src/compression/compressor.dart';
export 'src/compression/jpeg_compressor.dart';
