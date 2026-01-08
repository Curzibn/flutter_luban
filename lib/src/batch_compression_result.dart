import 'compression/compression_result.dart';
import 'result.dart';

class BatchCompressionItem {
  final String originalPath;
  final Result<CompressionResult> result;

  BatchCompressionItem({
    required this.originalPath,
    required this.result,
  });

  bool get isSuccess => result.isSuccess;
  bool get isFailure => result.isFailure;
}

class BatchCompressionResult {
  final List<BatchCompressionItem> items;

  BatchCompressionResult(this.items);

  int get total => items.length;

  int get successCount => items.where((item) => item.isSuccess).length;

  int get failureCount => items.where((item) => item.isFailure).length;

  List<CompressionResult> get successfulResults => items
      .where((item) => item.isSuccess)
      .map((item) => item.result.value)
      .toList();

  List<Exception> get failures => items
      .where((item) => item.isFailure)
      .map((item) => item.result.error)
      .toList();
}
