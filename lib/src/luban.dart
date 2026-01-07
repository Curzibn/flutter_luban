import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'algorithm/compression_calculator.dart';
import 'compression/compressor.dart';
import 'compression/jpeg_compressor.dart';

class Luban {
  final Compressor _compressor;
  final CompressionCalculator _calculator;

  Luban({
    Compressor? compressor,
    CompressionCalculator? calculator,
  })  : _compressor = compressor ?? JpegCompressor(),
        _calculator = calculator ?? CompressionCalculator();

  static final Luban _defaultInstance = Luban();

  static Future<Uint8List> compress(
    Uint8List imageBytes,
    int width,
    int height,
  ) async {
    return _defaultInstance.compressInternal(imageBytes, width, height);
  }

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

    final Uint8List compressedBytes = _compressor.compress(
      rgbaData,
      compressWidth,
      compressHeight,
      targetSizeKb: targetSizeKb,
      fixedQuality: fixedQuality,
    );

    if (imageToCompress != image) {
      imageToCompress.dispose();
    }

    return compressedBytes;
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
    final Canvas canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      Paint(),
    );
    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(targetWidth, targetHeight);
  }
}

