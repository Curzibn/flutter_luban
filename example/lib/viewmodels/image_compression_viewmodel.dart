import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:luban/luban.dart';
import '../models/image_data.dart';
import '../models/batch_compress_result.dart';
import '../services/image_service.dart';
import '../services/compression_service.dart';
import '../services/file_service.dart';

class ImageCompressionViewModel extends ChangeNotifier {
  final ImageService _imageService = ImageService();
  final CompressionService _compressionService = CompressionService();
  final FileService _fileService = FileService();

  ImageCompressionViewModel() {
    _initStorageDirs();
  }

  Future<void> _initStorageDirs() async {
    await _fileService.copyAssetsToStorage();
  }

  ImageData? _originalImageData;
  ImageData? _compressedImageData;
  Uint8List? _compressedImageBytes;
  LubanTarget? _lubanTarget;
  bool _isCompressing = false;
  bool _isBatchCompressing = false;
  int _batchProgress = 0;
  int _batchTotal = 0;
  BatchCompressResult? _batchResult;
  String? _errorMessage;

  ImageData? get originalImageData => _originalImageData;
  ImageData? get compressedImageData => _compressedImageData;
  Uint8List? get compressedImageBytes => _compressedImageBytes;
  LubanTarget? get lubanTarget => _lubanTarget;
  bool get isCompressing => _isCompressing;
  bool get isBatchCompressing => _isBatchCompressing;
  int get batchProgress => _batchProgress;
  int get batchTotal => _batchTotal;
  BatchCompressResult? get batchResult => _batchResult;
  String? get errorMessage => _errorMessage;

  Future<void> pickImage() async {
    try {
      _errorMessage = null;
      notifyListeners();

      final ImageData? imageData = await _imageService.pickImage();
      if (imageData == null) return;

      final LubanTarget target = _compressionService.calculateTarget(imageData);

      _originalImageData = imageData;
      _compressedImageData = null;
      _compressedImageBytes = null;
      _lubanTarget = target;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = '选择图片失败: $e';
      notifyListeners();
    }
  }

  Future<void> compressImage() async {
    if (_originalImageData == null) {
      _errorMessage = '请先选择图片';
      notifyListeners();
      return;
    }

    if (_lubanTarget == null) {
      _errorMessage = '无法计算压缩参数';
      notifyListeners();
      return;
    }

    _isCompressing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Uint8List compressedBytes = await _compressionService.compressImage(
        _originalImageData!,
        _lubanTarget!,
      );

      if (_lubanTarget!.shouldSkipCompression) {
        final codec = await ui.instantiateImageCodec(_originalImageData!.bytes);
        final frame = await codec.getNextFrame();
        final ui.Image originalImage = frame.image;

        _compressedImageBytes = _originalImageData!.bytes;
        _compressedImageData = ImageData(
          bytes: compressedBytes,
          image: originalImage,
          width: originalImage.width,
          height: originalImage.height,
        );
        _isCompressing = false;
        _errorMessage = '原图已经是最优大小，建议保持原图';
        notifyListeners();
        return;
      }

      final codec = await ui.instantiateImageCodec(compressedBytes);
      final frame = await codec.getNextFrame();
      final ui.Image compressedImage = frame.image;

      _compressedImageBytes = compressedBytes;
      _compressedImageData = ImageData(
        bytes: compressedBytes,
        image: compressedImage,
        width: compressedImage.width,
        height: compressedImage.height,
      );
      _isCompressing = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isCompressing = false;
      _errorMessage = '压缩失败: $e';
      notifyListeners();
    }
  }

  Future<void> compressBatchFromDirectory() async {
    try {
      _errorMessage = null;
      _isBatchCompressing = true;
      _batchProgress = 0;
      _batchTotal = 0;
      _batchResult = null;
      notifyListeners();

      final FileService fileService = FileService();
      List<File> imageFiles = await fileService.getInputImageFiles();
      
      if (imageFiles.isEmpty) {
        await _fileService.copyAssetsToStorage();
        imageFiles = await fileService.getInputImageFiles();
      }
      
      if (imageFiles.isEmpty) {
        final inputDirPath = await fileService.getInputImagesDirectoryPath();
        _isBatchCompressing = false;
        _errorMessage = '输入目录中没有找到图片文件: $inputDirPath\n请确保 assets/test_images/ 目录中有图片文件，并重新运行应用';
        notifyListeners();
        return;
      }

      _batchTotal = imageFiles.length;
      notifyListeners();

      final List<ImageData> imageDataList = [];
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final Uint8List imageBytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(imageBytes);
        final frame = await codec.getNextFrame();
        final ui.Image imageData = frame.image;

        imageDataList.add(ImageData(
          bytes: imageBytes,
          image: imageData,
          width: imageData.width,
          height: imageData.height,
        ));

        _batchProgress = i + 1;
        notifyListeners();
      }

      final BatchCompressResult result = await _compressionService.compressBatchFromDirectory(imageFiles, imageDataList);

      _isBatchCompressing = false;
      _batchResult = result;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isBatchCompressing = false;
      _errorMessage = '批量压缩失败: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _compressionService.dispose();
    super.dispose();
  }
}

