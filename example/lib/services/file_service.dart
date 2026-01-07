import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileService {
  static const String compressedImagesFolder = 'compressed_images';
  static const String inputImagesFolder = 'images';
  static const String outputCompressedFolder = 'compressed';

  Future<Directory> getApplicationExternalFilesDirectory() async {
    final Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      return externalDir.parent;
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<Directory> getInputImagesDirectory() async {
    final Directory baseDir = await getApplicationExternalFilesDirectory();
    final Directory inputDir = Directory(
      path.join(baseDir.path, inputImagesFolder),
    );
    
    if (!await inputDir.exists()) {
      await inputDir.create(recursive: true);
    }
    
    return inputDir;
  }

  Future<Directory> getOutputCompressedDirectory() async {
    final Directory baseDir = await getApplicationExternalFilesDirectory();
    final Directory outputDir = Directory(
      path.join(baseDir.path, outputCompressedFolder),
    );
    
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    
    return outputDir;
  }

  Future<Directory> getCompressedImagesDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory compressedDir = Directory(
      path.join(appDocDir.path, compressedImagesFolder),
    );
    
    if (!await compressedDir.exists()) {
      await compressedDir.create(recursive: true);
    }
    
    return compressedDir;
  }

  Future<List<File>> getInputImageFiles() async {
    final Directory inputDir = await getInputImagesDirectory();
    if (!await inputDir.exists()) {
      return [];
    }
    
    final List<FileSystemEntity> entities = inputDir.listSync();
    return entities
        .whereType<File>()
        .where((file) {
          final fileName = file.path.toLowerCase();
          return fileName.endsWith('.jpg') ||
                 fileName.endsWith('.jpeg') ||
                 fileName.endsWith('.png');
        })
        .toList();
  }

  Future<String> saveCompressedImage(
    Uint8List imageBytes,
    String fileName,
  ) async {
    final Directory compressedDir = await getCompressedImagesDirectory();
    final String filePath = path.join(compressedDir.path, fileName);
    final File file = File(filePath);
    await file.writeAsBytes(imageBytes);
    return filePath;
  }

  Future<List<String>> saveBatchCompressedImages(
    List<Uint8List> imageBytesList,
  ) async {
    final List<String> savedPaths = [];
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 0; i < imageBytesList.length; i++) {
      final String fileName = 'compressed_${timestamp}_$i.jpg';
      final String filePath = await saveCompressedImage(
        imageBytesList[i],
        fileName,
      );
      savedPaths.add(filePath);
    }

    return savedPaths;
  }

  Future<String> getCompressedImagesDirectoryPath() async {
    final Directory compressedDir = await getCompressedImagesDirectory();
    return compressedDir.path;
  }

  Future<List<File>> getSavedCompressedImages() async {
    final Directory compressedDir = await getCompressedImagesDirectory();
    if (!await compressedDir.exists()) {
      return [];
    }
    
    final List<FileSystemEntity> entities = compressedDir.listSync();
    return entities
        .whereType<File>()
        .where((file) => file.path.endsWith('.jpg') || file.path.endsWith('.jpeg'))
        .toList();
  }

  Future<void> clearCompressedImages() async {
    final Directory compressedDir = await getCompressedImagesDirectory();
    if (await compressedDir.exists()) {
      await compressedDir.delete(recursive: true);
    }
  }

  Future<String> getInputImagesDirectoryPath() async {
    final Directory inputDir = await getInputImagesDirectory();
    return inputDir.path;
  }

  Future<String> getOutputCompressedDirectoryPath() async {
    final Directory outputDir = await getOutputCompressedDirectory();
    return outputDir.path;
  }

  Future<void> copyAssetsToStorage() async {
    try {
      final Directory inputDir = await getInputImagesDirectory();
      final List<String> assetFiles = await _getAssetFiles();
      
      if (assetFiles.isEmpty) {
        print('警告: 未找到 assets 中的图片文件');
        return;
      }

      final Set<String> imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp'};
      int copiedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;

      for (final fileName in assetFiles) {
        final lowerFileName = fileName.toLowerCase();
        
        final bool isImageFile = imageExtensions.any((ext) => lowerFileName.endsWith(ext));
        if (!isImageFile) {
          continue;
        }

        final File targetFile = File(path.join(inputDir.path, fileName));
        
        if (await targetFile.exists()) {
          skippedCount++;
          continue;
        }

        try {
          final ByteData data = await rootBundle.load('assets/test_images/$fileName');
          final Uint8List bytes = data.buffer.asUint8List();
          await targetFile.writeAsBytes(bytes);
          copiedCount++;
        } catch (e) {
          print('复制文件失败: $fileName, 错误: $e');
          errorCount++;
          continue;
        }
      }
      
      print('Assets 复制完成: 复制 $copiedCount 个文件, 跳过 $skippedCount 个文件, 错误 $errorCount 个文件');
      print('输入目录路径: ${inputDir.path}');
    } catch (e) {
      print('复制 assets 到存储失败: $e');
    }
  }

  Future<List<String>> _getAssetFiles() async {
    final List<String> assetFiles = [];
    final List<String> possibleFiles = [
      'A.jpg', 'B.jpg', 'C.jpg', 'D.jpg', 'E.jpg', 'F.jpg', 'G.jpg', 'H.jpg',
      'a.jpg', 'b.jpg', 'c.jpg', 'd.jpg', 'e.jpg', 'f.jpg', 'g.jpg', 'h.jpg',
      '1.jpg', '2.jpg', '3.jpg', '4.jpg', '5.jpg', '6.jpg', '7.jpg', '8.jpg', '9.jpg',
      'test1.jpg', 'test2.jpg', 'test3.jpg', 'image1.jpg', 'image2.jpg',
      'A.jpeg', 'B.jpeg', 'C.jpeg', 'D.jpeg', 'E.jpeg', 'F.jpeg', 'G.jpeg',
      'A.png', 'B.png', 'C.png', 'D.png', 'E.png', 'F.png', 'G.png',
    ];
    
    for (final fileName in possibleFiles) {
      try {
        await rootBundle.load('assets/test_images/$fileName');
        assetFiles.add(fileName);
        print('成功找到 assets 文件: $fileName');
      } catch (e) {
        continue;
      }
    }
    
    print('总共找到 ${assetFiles.length} 个 assets 文件: $assetFiles');
    return assetFiles;
  }
}

