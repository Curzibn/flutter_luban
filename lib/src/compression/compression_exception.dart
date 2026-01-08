class CompressionException implements Exception {
  final String message;
  final dynamic cause;

  CompressionException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'CompressionException: $message\nCaused by: $cause';
    }
    return 'CompressionException: $message';
  }
}

class FileNotFoundException extends CompressionException {
  FileNotFoundException(String path) : super('文件不存在 (File does not exist): $path');
}

class ImageDecodeException extends CompressionException {
  ImageDecodeException(String message) : super('无法解码图片 (Cannot decode image): $message');
}

class CompressionFailedException extends CompressionException {
  CompressionFailedException(String message, [dynamic cause]) : super('压缩失败 (Compression failed): $message', cause);
}

class InvalidArgumentException extends CompressionException {
  InvalidArgumentException(String message) : super('参数错误 (Invalid argument): $message');
}