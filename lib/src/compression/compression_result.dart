import 'dart:io';

class CompressionResult {
  final File file;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final int originalWidth;
  final int originalHeight;
  final int compressedWidth;
  final int compressedHeight;
  final bool isOriginalCopied;

  CompressionResult({
    required this.file,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.originalWidth,
    required this.originalHeight,
    required this.compressedWidth,
    required this.compressedHeight,
    this.isOriginalCopied = false,
  });

  double get compressionRatio => originalSizeBytes > 0
      ? compressedSizeBytes / originalSizeBytes
      : 1.0;

  int get sizeReductionBytes => originalSizeBytes - compressedSizeBytes;

  double get sizeReductionPercent => originalSizeBytes > 0
      ? (sizeReductionBytes / originalSizeBytes) * 100
      : 0.0;

  int get originalSizeKb => (originalSizeBytes / 1024).round();
  int get compressedSizeKb => (compressedSizeBytes / 1024).round();
}
