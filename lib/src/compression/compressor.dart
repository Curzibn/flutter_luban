import 'dart:typed_data';

abstract class Compressor {
  Uint8List compress(
    Uint8List rgbaData,
    int width,
    int height, {
    int? targetSizeKb,
    int? fixedQuality,
  });
}
