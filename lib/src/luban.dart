import 'dart:io';
import 'dart:typed_data';
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

class Luban {
  final CompressionCalculator _calculator;

  Luban({
    Compressor? compressor,
    CompressionCalculator? calculator,
  })  : _calculator = calculator ?? CompressionCalculator();

  static final Luban _defaultInstance = Luban();

  static Future<Uint8List> compress(File file) async {
    return _defaultInstance.compressFromFile(file);
  }

  static Future<Uint8List> compressPath(String path) async {
    return compress(File(path));
  }

  static Future<List<Uint8List>> compressBatch(List<File> files) async {
    return _defaultInstance.compressBatchFromFiles(files);
  }

  static Future<List<Uint8List>> compressBatchPaths(List<String> paths) async {
    return compressBatch(paths.map((path) => File(path)).toList());
  }

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

  Future<Uint8List> compressFromFile(File file) async {
    if (!await file.exists()) {
      throw ArgumentError('文件不存在: ${file.path}');
    }

    final Uint8List imageBytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    try {
      return await compressInternal(imageBytes, image.width, image.height);
    } finally {
      image.dispose();
    }
  }

  Future<List<Uint8List>> compressBatchFromFiles(List<File> files) async {
    final List<Future<Uint8List>> futures = [];
    for (final file in files) {
      futures.add(compressFromFile(file));
    }
    return Future.wait(futures);
  }

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
