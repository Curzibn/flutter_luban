import 'package:flutter_test/flutter_test.dart';
import 'package:luban/src/algorithm/compression_calculator.dart';

void main() {
  group('CompressionCalculator', () {
    late CompressionCalculator calculator;

    setUp(() {
      calculator = CompressionCalculator();
    });

    group('标准图片压缩', () {
      test('标准拍照图片 (3024×4032)', () {
        final target = calculator.calculateTarget(3024, 4032);
        
        expect(target.width, greaterThan(0));
        expect(target.height, greaterThan(0));
        expect(target.width, lessThanOrEqualTo(3024));
        expect(target.height, lessThanOrEqualTo(4032));
        expect(target.width % 2, equals(0));
        expect(target.height % 2, equals(0));
        expect(target.estimatedSizeKb, greaterThan(0));
        expect(target.isLongImage, isFalse);
        expect(target.targetSizeKb, isNull);
      });

      test('高清大图 (4000×6000)', () {
        final target = calculator.calculateTarget(4000, 6000);
        
        expect(target.width, greaterThan(0));
        expect(target.height, greaterThan(0));
        expect(target.width, lessThanOrEqualTo(4000));
        expect(target.height, lessThanOrEqualTo(6000));
        expect(target.width % 2, equals(0));
        expect(target.height % 2, equals(0));
        expect(target.isLongImage, isFalse);
      });

      test('2K截图 (1440×3200)', () {
        final target = calculator.calculateTarget(1440, 3200);
        
        expect(target.width, equals(1440));
        expect(target.height, lessThanOrEqualTo(3200));
        expect(target.width % 2, equals(0));
        expect(target.height % 2, equals(0));
      });

      test('设计原稿 (6000×6000)', () {
        final target = calculator.calculateTarget(6000, 6000);
        
        expect(target.width, equals(target.height));
        expect(target.width, lessThanOrEqualTo(6000));
        expect(target.width % 2, equals(0));
      });
    });

    group('长图压缩', () {
      test('超长截图 (1242×22080)', () {
        final target = calculator.calculateTarget(1242, 22080);
        
        expect(target.width, greaterThan(0));
        expect(target.height, greaterThan(0));
        expect(target.width, lessThanOrEqualTo(1242));
        expect(target.height, lessThanOrEqualTo(22080));
        expect(target.isLongImage, isTrue);
        expect(target.targetSizeKb, isNotNull);
        expect(target.targetSizeKb, greaterThan(0));
      });

      test('长图宽高比验证', () {
        final target = calculator.calculateTarget(100, 500);
        
        expect(target.isLongImage, isTrue);
        expect(target.targetSizeKb, isNotNull);
      });

      test('非长图宽高比验证', () {
        final target = calculator.calculateTarget(1000, 1500);
        
        expect(target.isLongImage, isFalse);
        expect(target.targetSizeKb, isNull);
      });
    });

    group('全景图压缩', () {
      test('全景横图 (12000×5000)', () {
        final target = calculator.calculateTarget(12000, 5000);
        
        expect(target.width, greaterThan(0));
        expect(target.height, greaterThan(0));
        expect(target.width, lessThanOrEqualTo(12000));
        expect(target.height, lessThanOrEqualTo(5000));
        expect(target.width % 2, equals(0));
        expect(target.height % 2, equals(0));
      });

      test('超大全景图 (15000×6000)', () {
        final target = calculator.calculateTarget(15000, 6000);
        
        expect(target.width, greaterThan(0));
        expect(target.height, greaterThan(0));
        expect(target.width % 2, equals(0));
        expect(target.height % 2, equals(0));
      });
    });

    group('超大像素图处理', () {
      test('超大像素图 (>4096万像素)', () {
        final target = calculator.calculateTarget(8000, 6000);
        
        expect(target.width, greaterThan(0));
        expect(target.height, greaterThan(0));
        final int pixelCount = target.width * target.height;
        expect(pixelCount, lessThanOrEqualTo(CompressionCalculator.capPixels));
      });

      test('超大像素图降采样验证', () {
        final target = calculator.calculateTarget(10000, 8000);
        
        expect(target.width, lessThan(10000));
        expect(target.height, lessThan(8000));
      });
    });

    group('边界情况处理', () {
      test('无效宽度', () {
        final target = calculator.calculateTarget(0, 1000);
        
        expect(target.width, equals(0));
        expect(target.height, equals(0));
        expect(target.estimatedSizeKb, equals(0));
      });

      test('无效高度', () {
        final target = calculator.calculateTarget(1000, 0);
        
        expect(target.width, equals(0));
        expect(target.height, equals(0));
        expect(target.estimatedSizeKb, equals(0));
      });

      test('负数宽度', () {
        final target = calculator.calculateTarget(-100, 1000);
        
        expect(target.width, equals(0));
        expect(target.height, equals(0));
      });

      test('负数高度', () {
        final target = calculator.calculateTarget(1000, -100);
        
        expect(target.width, equals(0));
        expect(target.height, equals(0));
      });

      test('极小图片 (1×1)', () {
        final target = calculator.calculateTarget(1, 1);
        
        expect(target.width, greaterThanOrEqualTo(2));
        expect(target.height, greaterThanOrEqualTo(2));
        expect(target.width % 2, equals(0));
        expect(target.height % 2, equals(0));
      });

      test('极小图片 (2×2)', () {
        final target = calculator.calculateTarget(2, 2);
        
        expect(target.width, equals(2));
        expect(target.height, equals(2));
        expect(target.estimatedSizeKb, greaterThanOrEqualTo(20));
      });

      test('横向图片', () {
        final target = calculator.calculateTarget(2000, 1000);
        
        expect(target.width, greaterThan(target.height));
        expect(target.width % 2, equals(0));
        expect(target.height % 2, equals(0));
      });

      test('纵向图片', () {
        final target = calculator.calculateTarget(1000, 2000);
        
        expect(target.height, greaterThan(target.width));
        expect(target.width % 2, equals(0));
        expect(target.height % 2, equals(0));
      });
    });

    group('像素上限保护', () {
      test('长图像素上限验证', () {
        final target = calculator.calculateTarget(2000, 10000);
        
        final int pixelCount = target.width * target.height;
        expect(pixelCount, lessThanOrEqualTo(CompressionCalculator.capPixels));
      });

      test('超大长图像素限制', () {
        final target = calculator.calculateTarget(3000, 50000);
        
        final int pixelCount = target.width * target.height;
        expect(pixelCount, lessThanOrEqualTo(CompressionCalculator.capPixels));
      });
    });

    group('尺寸对齐验证', () {
      test('宽度必须是偶数', () {
        for (int width = 100; width <= 2000; width += 100) {
          for (int height = 100; height <= 2000; height += 100) {
            final target = calculator.calculateTarget(width, height);
            expect(target.width % 2, equals(0), 
              reason: 'Width $width should be even, got ${target.width}');
            expect(target.height % 2, equals(0),
              reason: 'Height $height should be even, got ${target.height}');
          }
        }
      });
    });

    group('预估大小验证', () {
      test('预估大小应该大于0', () {
        final target = calculator.calculateTarget(1000, 1000);
        
        expect(target.estimatedSizeKb, greaterThan(0));
        expect(target.estimatedSizeKb, greaterThanOrEqualTo(20));
      });

      test('长图预估大小应该合理', () {
        final target = calculator.calculateTarget(1000, 5000);
        
        expect(target.estimatedSizeKb, greaterThan(0));
        if (target.isLongImage) {
          expect(target.targetSizeKb, isNotNull);
        }
      });
    });

    group('不放大原图', () {
      test('小图不应该被放大', () {
        final target = calculator.calculateTarget(500, 500);
        
        expect(target.width, lessThanOrEqualTo(500));
        expect(target.height, lessThanOrEqualTo(500));
      });

      test('极小图保持最小尺寸', () {
        final target = calculator.calculateTarget(100, 100);
        
        expect(target.width, lessThanOrEqualTo(100));
        expect(target.height, lessThanOrEqualTo(100));
      });
    });
  });
}
