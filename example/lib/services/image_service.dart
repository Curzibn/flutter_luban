import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/image_data.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<ImageData?> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return null;

    final Uint8List imageBytes = await image.readAsBytes();
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final ui.Image imageData = frame.image;

    return ImageData(
      bytes: imageBytes,
      image: imageData,
      width: imageData.width,
      height: imageData.height,
    );
  }

  Future<List<ImageData>> pickMultipleImages() async {
    final List<XFile> images = await _picker.pickMultiImage();

    if (images.isEmpty) return [];

    final List<ImageData> imageDataList = [];

    for (final image in images) {
      final Uint8List imageBytes = await image.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final ui.Image imageData = frame.image;

      imageDataList.add(ImageData(
        bytes: imageBytes,
        image: imageData,
        width: imageData.width,
        height: imageData.height,
      ));
    }

    return imageDataList;
  }

  Future<Uint8List> imageToRgba(ui.Image image) async {
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    return byteData!.buffer.asUint8List();
  }

  Future<ui.Image> resizeImage(ui.Image image, int targetWidth, int targetHeight) async {
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

  Future<Uint8List> imageToPng(ui.Image image) async {
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }
}

