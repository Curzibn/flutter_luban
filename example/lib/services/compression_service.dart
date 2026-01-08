import 'dart:io';
import 'dart:typed_data';
import 'package:luban/luban.dart';
import 'package:path/path.dart' as path;
import '../models/batch_compress_result.dart';
import 'file_service.dart';

class CompressionService {
  final FileService _fileService = FileService();

  Future<Uint8List> compressImage(File file) async {
    return await Luban.compress(file);
  }

  Future<BatchCompressResult> compressBatch(
    List<File> imageFiles, {
    bool saveToFile = true,
  }) async {
    final compressedResults = await Luban.compressBatch(imageFiles);

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
      total: imageFiles.length,
      success: successCount,
      failed: failedCount,
      savedPaths: savedPaths,
      directoryPath: directoryPath,
    );
  }

  Future<BatchCompressResult> compressBatchFromDirectory(
    List<File> imageFiles,
  ) async {
    final compressedResults = await Luban.compressBatch(imageFiles);

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

