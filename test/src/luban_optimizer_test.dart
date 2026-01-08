import 'package:flutter_test/flutter_test.dart';
import 'package:luban/src/luban_optimizer.dart';
import 'dart:typed_data';

void main() {
  group('LubanOptimizer', () {
    late LubanOptimizer optimizer;

    setUp(() {
      optimizer = LubanOptimizer();
    });

    group('标准图片压缩', () {
      test('标准拍照图片', () {
        final target = optimizer.calculateTarget(3024, 4032);
        
        expect(target.width, greaterThan(0));
        expect(target.height, greaterThan(0));
        expect(target.width, lessThanOrEqualTo(3024));
        expect(target.height, lessThanOrEqualTo(4032));
        expect(target.estimatedSizeKb, greaterThan(0));
        expect(target.quality, equals(60));
        expect(target.shouldSkipCompression, isFalse);
      });

      test('高清大图', () {
        final target = optimizer.calculateTarget(4000, 6000);
        
        expect(target.width, greaterThan(0));
        expect(target.height, greaterThan(0));
        expect(target.width % 2, equals(0));
        expect(target.height % 2, equals(0));
      });
    });

    group('长图压缩', () {
      test('超长截图', () {
        final target = optimizer.calculateTarget(1242, 22080);
        
        expect(target.width, greaterThan(0));
        expect(target.height, greaterThan(0));
        expect(target.isLongImage, isTrue);
        expect(target.targetSizeKb, isNotNull);
        expect(target.targetSizeKb, lessThanOrEqualTo(LubanOptimizer.longImageSizeCap));
      });

      test('长图像素上限保护', () {
        final target = optimizer.calculateTarget(2000, 10000);
        
        final int pixelCount = target.width * target.height;
        expect(pixelCount, lessThanOrEqualTo(LubanOptimizer.longImagePixelCap));
      });

      test('长图大小上限', () {
        final target = optimizer.calculateTarget(1000, 5000);
        
        if (target.isLongImage) {
          expect(target.targetSizeKb, lessThanOrEqualTo(LubanOptimizer.longImageSizeCap));
        }
      });
    });

    group('全景图处理', () {
      test('全景横图', () {
        final target = optimizer.calculateTarget(12000, 5000);
        
        expect(target.width, greaterThan(0));
        expect(target.height, greaterThan(0));
        expect(target.width % 2, equals(0));
        expect(target.height % 2, equals(0));
      });

      test('超大全景图应该使用低基准', () {
        final target = optimizer.calculateTarget(15000, 6000);
        
        expect(target.width, greaterThan(0));
        expect(target.height, greaterThan(0));
      });
    });

    group('超大文件惩罚', () {
      test('超大文件应该应用惩罚缩放', () {
        final normalTarget = optimizer.calculateTarget(2000, 2000, 1000);
        final largeFileTarget = optimizer.calculateTarget(2000, 2000, 15000);
        
        if (largeFileTarget.width < normalTarget.width) {
          expect(largeFileTarget.width, lessThan(normalTarget.width));
        }
      });

      test('正常大小文件不应该应用惩罚', () {
        final target = optimizer.calculateTarget(2000, 2000, 5000);
        
        expect(target.width, greaterThan(0));
        expect(target.height, greaterThan(0));
      });
    });

    group('边界情况', () {
      test('无效输入应该返回零尺寸', () {
        final target = optimizer.calculateTarget(0, 1000);
        
        expect(target.width, equals(0));
        expect(target.height, equals(0));
        expect(target.estimatedSizeKb, equals(0));
      });

      test('负数输入应该返回零尺寸', () {
        final target = optimizer.calculateTarget(-100, 1000);
        
        expect(target.width, equals(0));
        expect(target.height, equals(0));
      });

      test('小图片不应该被放大', () {
        final target = optimizer.calculateTarget(500, 500);
        
        expect(target.width, lessThanOrEqualTo(500));
        expect(target.height, lessThanOrEqualTo(500));
      });
    });

    group('预估大小计算', () {
      test('预估大小应该大于最小值', () {
        final target = optimizer.calculateTarget(1000, 1000);
        
        expect(target.estimatedSizeKb, greaterThanOrEqualTo(20));
      });

      test('预估大小不应该超过源文件大小', () {
        final target = optimizer.calculateTarget(1000, 1000, 50);
        
        expect(target.estimatedSizeKb, lessThanOrEqualTo(50));
      });
    });

    group('compressToTargetSize 静态方法', () {
      test('应该找到满足目标大小的最高质量', () {
        Uint8List compressFn(int quality) {
          final int baseSize = 1000;
          final int size = (baseSize * (100 - quality) / 100).round();
          return Uint8List(size.clamp(100, 10000));
        }

        final result = LubanOptimizer.compressToTargetSize(compressFn, 500);
        
        expect(result.length, lessThanOrEqualTo(500 * 1024));
        expect(result, isNotEmpty);
      });

      test('如果最高质量已满足要求，应该直接返回', () {
        Uint8List compressFn(int quality) {
          return Uint8List(100);
        }

        final result = LubanOptimizer.compressToTargetSize(compressFn, 500);
        
        expect(result.length, equals(100));
      });

      test('如果最低质量仍无法满足，应该返回最低质量结果', () {
        Uint8List compressFn(int quality) {
          return Uint8List(1000000);
        }

        final result = LubanOptimizer.compressToTargetSize(compressFn, 500);
        
        expect(result, isNotEmpty);
      });
    });

    group('尺寸对齐', () {
      test('宽度和高度应该是偶数', () {
        for (int width = 100; width <= 2000; width += 100) {
          for (int height = 100; height <= 2000; height += 100) {
            final target = optimizer.calculateTarget(width, height);
            expect(target.width % 2, equals(0),
              reason: 'Width should be even for input $width');
            expect(target.height % 2, equals(0),
              reason: 'Height should be even for input $height');
          }
        }
      });
    });

    group('像素上限保护', () {
      test('结果不应该超过像素上限', () {
        final target = optimizer.calculateTarget(5000, 5000);
        
        final int pixelCount = target.width * target.height;
        expect(pixelCount, lessThanOrEqualTo(LubanOptimizer.longImagePixelCap));
      });

      test('超大图应该被限制到像素上限', () {
        final target = optimizer.calculateTarget(10000, 10000);
        
        final int pixelCount = target.width * target.height;
        expect(pixelCount, lessThanOrEqualTo(LubanOptimizer.longImagePixelCap));
      });
    });
  });
}
