class BatchCompressResult {
  final int total;
  final int success;
  final int failed;
  final List<String> savedPaths;
  final String? directoryPath;

  BatchCompressResult({
    required this.total,
    required this.success,
    required this.failed,
    this.savedPaths = const [],
    this.directoryPath,
  });
}

