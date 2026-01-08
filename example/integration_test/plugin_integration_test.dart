import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:luban/luban.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Luban compression test', (WidgetTester tester) async {
    final testImageBytes = await _createTestImage(100, 100);
    final tempDir = await getTemporaryDirectory();
    final testFile = File('${tempDir.path}/test_image.png');
    await testFile.writeAsBytes(testImageBytes);
    
    final result = await Luban.compress(testFile);
    
    expect(result.isSuccess, true);
    final compressionResult = result.value;
    expect(compressionResult.compressedSizeBytes, greaterThan(0));
    expect(compressionResult.compressedSizeBytes, lessThanOrEqualTo(testImageBytes.length));
    expect(await compressionResult.file.exists(), true);
    
    await testFile.delete();
    await compressionResult.file.delete();
  });

  testWidgets('Luban batch compression test', (WidgetTester tester) async {
    final testImageBytes1 = await _createTestImage(100, 100);
    final testImageBytes2 = await _createTestImage(200, 200);
    final tempDir = await getTemporaryDirectory();
    final testFile1 = File('${tempDir.path}/test_image1.png');
    final testFile2 = File('${tempDir.path}/test_image2.png');
    await testFile1.writeAsBytes(testImageBytes1);
    await testFile2.writeAsBytes(testImageBytes2);
    
    final batchResult = await Luban.compressBatch([testFile1, testFile2]);
    
    expect(batchResult.isSuccess, true);
    final batchCompressionResult = batchResult.value;
    expect(batchCompressionResult.total, equals(2));
    expect(batchCompressionResult.successCount, equals(2));
    expect(batchCompressionResult.failureCount, equals(0));
    expect(batchCompressionResult.successfulResults.length, equals(2));
    
    for (final item in batchCompressionResult.items) {
      expect(item.isSuccess, true);
      final compressionResult = item.result.value;
      expect(await compressionResult.file.exists(), true);
      await compressionResult.file.delete();
    }
    
    await testFile1.delete();
    await testFile2.delete();
  });
}

Future<Uint8List> _createTestImage(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..color = const ui.Color(0xFF0000FF);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return byteData!.buffer.asUint8List();
}
