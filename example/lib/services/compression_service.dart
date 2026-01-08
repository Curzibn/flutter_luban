import 'dart:io';
import 'dart:typed_data';
import 'package:luban/luban.dart';
import '../models/batch_compress_result.dart';
import 'file_service.dart';

class CompressionService {
  final FileService _fileService = FileService();

  Future<Uint8List> compressImage(File file) async {
    final result = await Luban.compress(file);
    
    if (result.isSuccess) {
      final compressionResult = result.value;
      return await compressionResult.file.readAsBytes();
    } else {
      throw result.error;
    }
  }

  Future<BatchCompressResult> compressBatch(
    List<File> imageFiles, {
    bool saveToFile = true,
  }) async {
    final Directory outputDir = await _fileService.getOutputCompressedDirectory();
    final result = await Luban.compressBatch(imageFiles, outputDir: outputDir);

    if (result.isFailure) {
      throw result.error;
    }

    final batchResult = result.value;
    int successCount = batchResult.successCount;
    int failedCount = batchResult.failureCount;
    final List<String> savedPaths = [];

    if (saveToFile) {
      for (final item in batchResult.items) {
        if (item.isSuccess) {
          final compressionResult = item.result.value;
          savedPaths.add(compressionResult.file.path);
        }
      }
    }

    final String? directoryPath = saveToFile && savedPaths.isNotEmpty
        ? await _fileService.getOutputCompressedDirectoryPath()
        : null;

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
    final Directory outputDir = await _fileService.getOutputCompressedDirectory();
    final result = await Luban.compressBatch(imageFiles, outputDir: outputDir);

    if (result.isFailure) {
      throw result.error;
    }

    final batchResult = result.value;
    final List<String> savedPaths = [];
    for (final item in batchResult.items) {
      if (item.isSuccess) {
        final compressionResult = item.result.value;
        savedPaths.add(compressionResult.file.path);
      }
    }

    final String outputPath = await _fileService.getOutputCompressedDirectoryPath();

    return BatchCompressResult(
      total: imageFiles.length,
      success: batchResult.successCount,
      failed: batchResult.failureCount,
      savedPaths: savedPaths,
      directoryPath: outputPath,
    );
  }
}

