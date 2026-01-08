import 'package:flutter_test/flutter_test.dart';
import 'package:luban/src/compression/compressor.dart';
import 'dart:typed_data';

class MockCompressor implements Compressor {
  final Map<String, dynamic> _callLog = {};
  int _compressCallCount = 0;

  @override
  Uint8List compress(
    Uint8List rgbaData,
    int width,
    int height, {
    int? targetSizeKb,
    int? fixedQuality,
  }) {
    _compressCallCount++;
    _callLog['lastCall'] = {
      'width': width,
      'height': height,
      'targetSizeKb': targetSizeKb,
      'fixedQuality': fixedQuality,
      'dataLength': rgbaData.length,
    };

    final int pixelCount = width * height;
    final int expectedDataLength = pixelCount * 4;
    
    if (rgbaData.length != expectedDataLength) {
      throw ArgumentError(
        'Expected RGBA data length $expectedDataLength, got ${rgbaData.length}',
      );
    }

    if (fixedQuality != null) {
      return _createMockJpeg(width, height, fixedQuality);
    }

    if (targetSizeKb != null) {
      return _createMockJpegWithTargetSize(width, height, targetSizeKb);
    }

    return _createMockJpeg(width, height, 60);
  }

  Uint8List _createMockJpeg(int width, int height, int quality) {
    final int baseSize = (width * height * quality / 100).round();
    return Uint8List(baseSize.clamp(100, 1000000));
  }

  Uint8List _createMockJpegWithTargetSize(int width, int height, int targetSizeKb) {
    final int targetSizeBytes = targetSizeKb * 1024;
    final int baseSize = (width * height * 0.1).round();
    final int size = (baseSize < targetSizeBytes) ? baseSize : targetSizeBytes;
    return Uint8List(size.clamp(100, targetSizeBytes));
  }

  int get compressCallCount => _compressCallCount;
  Map<String, dynamic> get callLog => Map.unmodifiable(_callLog);
  void reset() {
    _compressCallCount = 0;
    _callLog.clear();
  }
}

void main() {
  group('Compressor Interface', () {
    late MockCompressor compressor;

    setUp(() {
      compressor = MockCompressor();
    });

    group('固定质量压缩', () {
      test('使用固定质量压缩', () {
        final rgbaData = Uint8List(1000 * 1000 * 4);
        final result = compressor.compress(
          rgbaData,
          1000,
          1000,
          fixedQuality: 80,
        );

        expect(result, isNotEmpty);
        expect(compressor.compressCallCount, equals(1));
        expect(compressor.callLog['lastCall']?['fixedQuality'], equals(80));
        expect(compressor.callLog['lastCall']?['targetSizeKb'], isNull);
      });

      test('固定质量优先级高于目标大小', () {
        final rgbaData = Uint8List(1000 * 1000 * 4);
        final result = compressor.compress(
          rgbaData,
          1000,
          1000,
          fixedQuality: 70,
          targetSizeKb: 100,
        );

        expect(result, isNotEmpty);
        expect(compressor.callLog['lastCall']?['fixedQuality'], equals(70));
      });
    });

    group('目标大小压缩', () {
      test('使用目标大小压缩', () {
        final rgbaData = Uint8List(1000 * 1000 * 4);
        final result = compressor.compress(
          rgbaData,
          1000,
          1000,
          targetSizeKb: 200,
        );

        expect(result, isNotEmpty);
        expect(compressor.callLog['lastCall']?['targetSizeKb'], equals(200));
        expect(compressor.callLog['lastCall']?['fixedQuality'], isNull);
      });

      test('目标大小压缩结果应该接近目标', () {
        final rgbaData = Uint8List(2000 * 2000 * 4);
        final result = compressor.compress(
          rgbaData,
          2000,
          2000,
          targetSizeKb: 300,
        );

        expect(result.length, lessThanOrEqualTo(300 * 1024 * 1.1));
      });
    });

    group('默认质量压缩', () {
      test('无参数时使用默认质量', () {
        final rgbaData = Uint8List(1000 * 1000 * 4);
        final result = compressor.compress(rgbaData, 1000, 1000);

        expect(result, isNotEmpty);
        expect(compressor.callLog['lastCall']?['fixedQuality'], isNull);
        expect(compressor.callLog['lastCall']?['targetSizeKb'], isNull);
      });
    });

    group('数据验证', () {
      test('RGBA数据长度必须匹配', () {
        final invalidData = Uint8List(1000 * 1000 * 3);

        expect(
          () => compressor.compress(invalidData, 1000, 1000),
          throwsArgumentError,
        );
      });

      test('正确长度的RGBA数据应该通过', () {
        final validData = Uint8List(1000 * 1000 * 4);
        final result = compressor.compress(validData, 1000, 1000);

        expect(result, isNotEmpty);
      });
    });

    group('不同尺寸测试', () {
      test('小尺寸图片', () {
        final rgbaData = Uint8List(100 * 100 * 4);
        final result = compressor.compress(rgbaData, 100, 100);

        expect(result, isNotEmpty);
        expect(compressor.callLog['lastCall']?['width'], equals(100));
        expect(compressor.callLog['lastCall']?['height'], equals(100));
      });

      test('大尺寸图片', () {
        final rgbaData = Uint8List(4000 * 3000 * 4);
        final result = compressor.compress(rgbaData, 4000, 3000);

        expect(result, isNotEmpty);
        expect(compressor.callLog['lastCall']?['width'], equals(4000));
        expect(compressor.callLog['lastCall']?['height'], equals(3000));
      });

      test('长图', () {
        final rgbaData = Uint8List(1000 * 5000 * 4);
        final result = compressor.compress(rgbaData, 1000, 5000);

        expect(result, isNotEmpty);
        expect(compressor.callLog['lastCall']?['width'], equals(1000));
        expect(compressor.callLog['lastCall']?['height'], equals(5000));
      });
    });

    group('调用计数', () {
      test('多次调用应该正确计数', () {
        final rgbaData = Uint8List(1000 * 1000 * 4);

        compressor.compress(rgbaData, 1000, 1000);
        compressor.compress(rgbaData, 1000, 1000);
        compressor.compress(rgbaData, 1000, 1000);

        expect(compressor.compressCallCount, equals(3));
      });

      test('重置后计数应该归零', () {
        final rgbaData = Uint8List(1000 * 1000 * 4);

        compressor.compress(rgbaData, 1000, 1000);
        compressor.reset();

        expect(compressor.compressCallCount, equals(0));
      });
    });
  });
}
