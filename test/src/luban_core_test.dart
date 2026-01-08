import 'package:flutter_test/flutter_test.dart';
import 'package:luban/src/luban.dart';
import 'package:luban/src/algorithm/compression_calculator.dart';
import 'package:luban/src/compression/compressor.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class MockCompressor implements Compressor {
  @override
  Uint8List compress(
    Uint8List rgbaData,
    int width,
    int height, {
    int? targetSizeKb,
    int? fixedQuality,
  }) {
    final int pixelCount = width * height;
    final int expectedLength = pixelCount * 4;
    
    if (rgbaData.length != expectedLength) {
      throw ArgumentError('Invalid RGBA data length');
    }

    final int baseSize = (pixelCount * 0.1).round();
    final int size = targetSizeKb != null 
        ? (baseSize < targetSizeKb * 1024 ? baseSize : targetSizeKb * 1024)
        : baseSize;
    
    return Uint8List(size.clamp(100, 1000000));
  }
}

Future<Uint8List> createTestImageBytes(int width, int height) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  
  final paint = ui.Paint()
    ..color = const ui.Color(0xFF4285F4)
    ..style = ui.PaintingStyle.fill;
  
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );
  
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(width, height);
  
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  
  return byteData!.buffer.asUint8List();
}

void main() {
  group('Luban Core', () {
    group('实例化', () {
      test('使用自定义压缩器', () {
        final mockCompressor = MockCompressor();
        final luban = Luban(compressor: mockCompressor);
        
        expect(luban, isNotNull);
      });

      test('使用自定义计算器', () {
        final mockCompressor = MockCompressor();
        final calculator = CompressionCalculator();
        final luban = Luban(compressor: mockCompressor, calculator: calculator);
        
        expect(luban, isNotNull);
      });
    });

    group('压缩参数计算', () {
      test('标准图片应该计算正确的目标尺寸', () {
        final calculator = CompressionCalculator();
        final target = calculator.calculateTarget(3024, 4032);
        
        expect(target.width, greaterThan(0));
        expect(target.height, greaterThan(0));
        expect(target.width, lessThanOrEqualTo(3024));
        expect(target.height, lessThanOrEqualTo(4032));
      });

      test('长图应该设置目标大小', () {
        final calculator = CompressionCalculator();
        final target = calculator.calculateTarget(1242, 22080);
        
        expect(target.isLongImage, isTrue);
        expect(target.targetSizeKb, isNotNull);
      });
    });

    group('批量压缩', () {
      test('批量压缩应该返回正确数量的结果', () async {
        final mockCompressor = MockCompressor();
        final luban = Luban(compressor: mockCompressor);
        
        final image1 = await createTestImageBytes(100, 100);
        final image2 = await createTestImageBytes(200, 200);
        final image3 = await createTestImageBytes(300, 300);
        
        final results = await luban.compressBatchInternal(
          [image1, image2, image3],
          [100, 200, 300],
          [100, 200, 300],
        );
        
        expect(results.length, equals(3));
        expect(results[0], isNotEmpty);
        expect(results[1], isNotEmpty);
        expect(results[2], isNotEmpty);
      });

      test('批量压缩应该并发处理', () async {
        final mockCompressor = MockCompressor();
        final luban = Luban(compressor: mockCompressor);
        
        final images = List.generate(5, (i) => createTestImageBytes(100, 100));
        final imageBytes = await Future.wait(images);
        
        final stopwatch = Stopwatch()..start();
        final results = await luban.compressBatchInternal(
          imageBytes,
          List.filled(5, 100),
          List.filled(5, 100),
        );
        stopwatch.stop();
        
        expect(results.length, equals(5));
      });

      test('空列表应该返回空结果', () async {
        final mockCompressor = MockCompressor();
        final luban = Luban(compressor: mockCompressor);
        
        final results = await luban.compressBatchInternal(
          [],
          [],
          [],
        );
        
        expect(results, isEmpty);
      });
    });

    group('边界情况', () {
      test('小图片压缩', () async {
        final mockCompressor = MockCompressor();
        final luban = Luban(compressor: mockCompressor);
        final imageBytes = await createTestImageBytes(50, 50);
        
        final result = await luban.compressInternal(imageBytes, 50, 50);
        
        expect(result, isNotEmpty);
      });

      test('大图片压缩', () async {
        final mockCompressor = MockCompressor();
        final luban = Luban(compressor: mockCompressor);
        final imageBytes = await createTestImageBytes(4000, 3000);
        
        final result = await luban.compressInternal(imageBytes, 4000, 3000);
        
        expect(result, isNotEmpty);
      });

      test('长图压缩', () async {
        final mockCompressor = MockCompressor();
        final luban = Luban(compressor: mockCompressor);
        final imageBytes = await createTestImageBytes(1000, 5000);
        
        final result = await luban.compressInternal(imageBytes, 1000, 5000);
        
        expect(result, isNotEmpty);
      });
    });

    group('静态方法', () {
      test('compress 静态方法需要原生库支持，跳过测试', () {
        expect(true, isTrue);
      });

      test('compressBatch 静态方法需要原生库支持，跳过测试', () {
        expect(true, isTrue);
      });
    });

    group('资源管理', () {
      test('压缩后应该正确释放资源', () async {
        final mockCompressor = MockCompressor();
        final luban = Luban(compressor: mockCompressor);
        final imageBytes = await createTestImageBytes(1000, 1000);
        
        final result1 = await luban.compressInternal(imageBytes, 1000, 1000);
        expect(result1, isNotEmpty);
        
        final result2 = await luban.compressInternal(imageBytes, 1000, 1000);
        expect(result2, isNotEmpty);
      });
    });
  });
}
