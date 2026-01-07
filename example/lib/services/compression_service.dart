import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:luban/luban.dart';
import 'package:path/path.dart' as path;
import '../models/image_data.dart';
import '../models/batch_compress_result.dart';
import 'image_service.dart';
import 'file_service.dart';

class CompressionService {
  final TurboJpeg _turboJpeg = TurboJpeg();
  final LubanOptimizer _lubanOptimizer = LubanOptimizer();
  final ImageService _imageService = ImageService();
  final FileService _fileService = FileService();

  void dispose() {
    _turboJpeg.dispose();
  }

  LubanTarget calculateTarget(ImageData imageData) {
    final double sourceSizeKb = imageData.bytes.length / 1024;
    return _lubanOptimizer.calculateTarget(
      imageData.width,
      imageData.height,
      sourceSizeKb,
    );
  }

  Future<Uint8List> compressImage(
    ImageData originalImageData,
    LubanTarget target,
  ) async {
    if (target.shouldSkipCompression) {
      return originalImageData.bytes;
    }

    ui.Image imageToCompress = originalImageData.image;
    int compressWidth = originalImageData.width;
    int compressHeight = originalImageData.height;

    if (target.width != originalImageData.width ||
        target.height != originalImageData.height) {
      imageToCompress = await _imageService.resizeImage(
        originalImageData.image,
        target.width,
        target.height,
      );
      compressWidth = target.width;
      compressHeight = target.height;
    }

    final Uint8List rgbaData = await _imageService.imageToRgba(imageToCompress);

    final int? targetSizeKb = target.targetSizeKb;
    final Uint8List compressedBytes;

    if (targetSizeKb != null) {
      compressedBytes = LubanOptimizer.compressToTargetSize(
        (quality) => _turboJpeg.compress(
          rgbaData,
          compressWidth,
          compressHeight,
          quality: quality,
        ),
        targetSizeKb,
      );
    } else {
      compressedBytes = _turboJpeg.compress(
        rgbaData,
        compressWidth,
        compressHeight,
        quality: target.quality,
      );
    }

    if (imageToCompress != originalImageData.image) {
      imageToCompress.dispose();
    }

    return compressedBytes;
  }

  Future<BatchCompressResult> compressBatch(
    List<ImageData> imageDataList, {
    bool saveToFile = true,
  }) async {
    final List<Uint8List> imageBytesList = [];
    final List<int> widths = [];
    final List<int> heights = [];

    for (final imageData in imageDataList) {
      imageBytesList.add(imageData.bytes);
      widths.add(imageData.width);
      heights.add(imageData.height);
    }

    final compressedResults = await Luban.compressBatch(
      imageBytesList,
      widths,
      heights,
    );

    int successCount = 0;
    int failedCount = 0;
    final List<Uint8List> successfulCompressedImages = [];

    for (final result in compressedResults) {
      if (result.isNotEmpty) {
        successCount++;
        successfulCompressedImages.add(result);
      } else {
        failedCount++;
      }
    }

    List<String> savedPaths = [];
    String? directoryPath;

    if (saveToFile && successfulCompressedImages.isNotEmpty) {
      savedPaths = await _fileService.saveBatchCompressedImages(
        successfulCompressedImages,
      );
      directoryPath = await _fileService.getCompressedImagesDirectoryPath();
    }

    return BatchCompressResult(
      total: imageDataList.length,
      success: successCount,
      failed: failedCount,
      savedPaths: savedPaths,
      directoryPath: directoryPath,
    );
  }

  Future<BatchCompressResult> compressBatchFromDirectory(
    List<File> imageFiles,
    List<ImageData> imageDataList,
  ) async {

    final List<Uint8List> imageBytesList = [];
    final List<int> widths = [];
    final List<int> heights = [];

    for (final imageData in imageDataList) {
      imageBytesList.add(imageData.bytes);
      widths.add(imageData.width);
      heights.add(imageData.height);
    }

    final compressedResults = await Luban.compressBatch(
      imageBytesList,
      widths,
      heights,
    );

    int successCount = 0;
    int failedCount = 0;
    final List<Uint8List> successfulCompressedImages = [];

    for (final result in compressedResults) {
      if (result.isNotEmpty) {
        successCount++;
        successfulCompressedImages.add(result);
      } else {
        failedCount++;
      }
    }

    final Directory outputDir = await _fileService.getOutputCompressedDirectory();
    final List<String> savedPaths = [];
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 0; i < successfulCompressedImages.length; i++) {
      final String fileName = '${imageFiles[i].uri.pathSegments.last.split('.').first}_compressed_$timestamp.jpg';
      final String filePath = path.join(outputDir.path, fileName);
      final File file = File(filePath);
      await file.writeAsBytes(successfulCompressedImages[i]);
      savedPaths.add(filePath);
    }

    final String outputPath = await _fileService.getOutputCompressedDirectoryPath();

    return BatchCompressResult(
      total: imageFiles.length,
      success: successCount,
      failed: failedCount,
      savedPaths: savedPaths,
      directoryPath: outputPath,
    );
  }
}

