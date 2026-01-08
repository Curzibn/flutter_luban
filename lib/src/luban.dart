import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'algorithm/compression_calculator.dart';
import 'compression/jpeg_compressor.dart';
import 'compression/compression_exception.dart';
import 'compression/compression_result.dart';
import 'io/image_loader.dart';
import 'result.dart';
import 'batch_compression_result.dart';

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
  } catch (e) {
    throw CompressionFailedException(
      '压缩过程中发生错误 (Error during compression)',
      e is Exception ? e : Exception(e.toString()),
    );
  } finally {
    compressor.dispose();
  }
}

class Luban {
  final ImageLoader _imageLoader;
  final CompressionCalculator _calculator;

  Luban({
    ImageLoader? imageLoader,
    CompressionCalculator? calculator,
  })  : _imageLoader = imageLoader ?? FlutterImageLoader(),
        _calculator = calculator ?? CompressionCalculator();

  static final Luban _defaultInstance = Luban();

  static Future<Result<CompressionResult>> compress(
    File input, {
    Directory? outputDir,
    File? outputFile,
  }) async {
    if (outputDir != null && outputFile != null) {
      return Result.failure(InvalidArgumentException('outputDir 和 outputFile 不能同时提供 (outputDir and outputFile cannot be provided at the same time)'));
    }
    return _defaultInstance.compressFile(input, outputDir: outputDir, outputFile: outputFile);
  }

  static Future<Result<CompressionResult>> compressPath(
    String inputPath, {
    Directory? outputDir,
    File? outputFile,
  }) async {
    if (outputDir != null && outputFile != null) {
      return Result.failure(InvalidArgumentException('outputDir 和 outputFile 不能同时提供 (outputDir and outputFile cannot be provided at the same time)'));
    }
    return compress(File(inputPath), outputDir: outputDir, outputFile: outputFile);
  }

  static Future<Result<CompressionResult>> compressToFile({
    required File input,
    required File output,
  }) async {
    return _defaultInstance.compressFile(input, outputFile: output);
  }

  static Future<Result<BatchCompressionResult>> compressBatch(
    List<File> inputs, {
    Directory? outputDir,
  }) async {
    return _defaultInstance.compressBatchFiles(inputs, outputDir: outputDir);
  }

  static Future<Result<BatchCompressionResult>> compressBatchPaths(
    List<String> inputPaths, {
    Directory? outputDir,
  }) async {
    return compressBatch(
      inputPaths.map((p) => File(p)).toList(),
      outputDir: outputDir,
    );
  }

  Future<Uint8List> _compressInternal(
    Uint8List imageBytes,
    int width,
    int height,
  ) async {
    final target = _calculator.calculateTarget(width, height);

    final imageData = await _imageLoader.loadFromBytes(
      imageBytes,
      target.width,
      target.height,
    );

    final int? targetSizeKb = target.targetSizeKb;
    final int? fixedQuality = target.isLongImage ? null : 60;

    final Uint8List compressedBytes = await compute(
      _compressInIsolate,
      {
        'rgbaData': imageData.rgbaData,
        'width': imageData.width,
        'height': imageData.height,
        'targetSizeKb': targetSizeKb,
        'fixedQuality': fixedQuality,
      },
    );

    return compressedBytes;
  }

  Future<Result<CompressionResult>> compressFile(
    File input, {
    Directory? outputDir,
    File? outputFile,
  }) async {
    if (outputDir != null && outputFile != null) {
      return Result.failure(InvalidArgumentException('outputDir 和 outputFile 不能同时提供 (outputDir and outputFile cannot be provided at the same time)'));
    }
    try {
      if (!await input.exists()) {
        return Result.failure(FileNotFoundException(input.path));
      }

      final Uint8List imageBytes = await input.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final int originalWidth = frame.image.width;
      final int originalHeight = frame.image.height;
      frame.image.dispose();

      final Uint8List compressedBytes = await _compressInternal(
        imageBytes,
        originalWidth,
        originalHeight,
      );

      final int originalSizeBytes = imageBytes.length;
      final int compressedSizeBytes = compressedBytes.length;

      File finalOutputFile;
      bool isOriginalCopied = false;

      if (outputFile != null) {
        finalOutputFile = outputFile;
      } else if (outputDir != null) {
        finalOutputFile = _generateOutputFile(input, outputDir);
      } else {
        final tempDir = await Directory.systemTemp.createTemp('luban_');
        finalOutputFile = _generateOutputFile(input, tempDir);
      }

      await finalOutputFile.parent.create(recursive: true);

      int finalCompressedWidth;
      int finalCompressedHeight;
      int finalCompressedSizeBytes;

      if (compressedSizeBytes >= originalSizeBytes && await input.exists()) {
        await input.copy(finalOutputFile.path);
        isOriginalCopied = true;
        finalCompressedWidth = originalWidth;
        finalCompressedHeight = originalHeight;
        finalCompressedSizeBytes = originalSizeBytes;
      } else {
        await finalOutputFile.writeAsBytes(compressedBytes);
        final codecCompressed = await ui.instantiateImageCodec(compressedBytes);
        final frameCompressed = await codecCompressed.getNextFrame();
        finalCompressedWidth = frameCompressed.image.width;
        finalCompressedHeight = frameCompressed.image.height;
        frameCompressed.image.dispose();
        finalCompressedSizeBytes = compressedSizeBytes;
      }

      final result = CompressionResult(
        file: finalOutputFile,
        originalSizeBytes: originalSizeBytes,
        compressedSizeBytes: finalCompressedSizeBytes,
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        compressedWidth: finalCompressedWidth,
        compressedHeight: finalCompressedHeight,
        isOriginalCopied: isOriginalCopied,
      );

      return Result.success(result);
    } catch (e) {
      if (e is CompressionException) {
        return Result.failure(e);
      }
      if (e is Exception) {
        return Result.failure(CompressionFailedException(
          '压缩失败 (Compression failed)',
          e,
        ));
      }
      return Result.failure(CompressionFailedException(
        '压缩失败 (Compression failed): ${e.toString()}',
      ));
    }
  }

  Future<Result<BatchCompressionResult>> compressBatchFiles(
    List<File> inputs, {
    Directory? outputDir,
  }) async {
    try {
      if (inputs.isEmpty) {
        return Result.failure(InvalidArgumentException('输入文件列表不能为空 (Input file list cannot be empty)'));
      }
      final List<Future<BatchCompressionItem>> futures = [];
      for (final file in inputs) {
        futures.add(
          compressFile(file, outputDir: outputDir).then(
            (result) => BatchCompressionItem(
              originalPath: file.path,
              result: result,
            ),
          ),
        );
      }
      final items = await Future.wait(futures);
      return Result.success(BatchCompressionResult(items));
    } catch (e) {
      if (e is CompressionException) {
        return Result.failure(e);
      }
      if (e is Exception) {
        return Result.failure(CompressionFailedException(
          '批量压缩失败 (Batch compression failed)',
          e,
        ));
      }
      return Result.failure(CompressionFailedException(
        '批量压缩失败 (Batch compression failed): ${e.toString()}',
      ));
    }
  }

  File _generateOutputFile(File inputFile, Directory outputDir) {
    final inputName = path.basenameWithoutExtension(inputFile.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return File(path.join(outputDir.path, '${inputName}_$timestamp.jpg'));
  }
}
