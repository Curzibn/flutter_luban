import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:luban/luban.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Luban compression test', (WidgetTester tester) async {
    final testImageBytes = await _createTestImage(100, 100);
    
    final compressedBytes = await Luban.compress(
      testImageBytes,
      100,
      100,
    );
    
    expect(compressedBytes.isNotEmpty, true);
    expect(compressedBytes.length, lessThanOrEqualTo(testImageBytes.length));
  });

  testWidgets('Luban batch compression test', (WidgetTester tester) async {
    final testImageBytes1 = await _createTestImage(100, 100);
    final testImageBytes2 = await _createTestImage(200, 200);
    
    final compressedResults = await Luban.compressBatch(
      [testImageBytes1, testImageBytes2],
      [100, 200],
      [100, 200],
    );
    
    expect(compressedResults.length, equals(2));
    expect(compressedResults[0].isNotEmpty, true);
    expect(compressedResults[1].isNotEmpty, true);
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
