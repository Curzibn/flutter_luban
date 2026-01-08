# Luban Flutter

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![pub package](https://img.shields.io/pub/v/luban.svg)](https://pub.dev/packages/luban)

[中文](README.md) | [English](README_EN.md)

Luban Flutter —— 高效简洁的 Flutter 图片压缩插件，像素级还原微信朋友圈压缩策略。

## 📑 目录

- [📖 项目描述](#-项目描述)
- [✨ 特性](#-特性)
- [📊 效果与对比](#-效果与对比)
  - [🔬 核心算法特性](#-核心算法特性)
- [📦 安装](#-安装)
- [💻 使用](#-使用)
  - [压缩单张图片](#压缩单张图片)
  - [批量压缩图片](#批量压缩图片)
- [📄 License](#-license)

## 📖 项目描述

目前做 `App` 开发总绕不开图片这个元素。但是随着手机拍照分辨率的提升，图片的压缩成为一个很重要的问题。单纯对图片进行裁切，压缩已经有很多文章介绍。但是裁切成多少，压缩成多少却很难控制好，裁切过头图片太小，质量压缩过头则显示效果太差。

于是自然想到 `App` 巨头"微信"会是怎么处理，`Luban`（鲁班）就是通过在微信朋友圈发送近100张不同分辨率图片，对比原图与微信压缩后的图片逆向推算出来的压缩算法。

因为是逆向推算，效果还没法跟微信一模一样，但是已经很接近微信朋友圈压缩后的效果，具体看以下对比！

本库是 `Luban` 的 **Flutter 版本**，使用 **TurboJPEG** 进行高性能图片压缩，提供简洁易用的 API 和接近微信朋友圈的压缩效果。

## ✨ 特性

- 🚀 **高性能**：基于 TurboJPEG 原生库，压缩速度快
- 🎯 **智能压缩**：自适应压缩算法，根据图片特征动态调整策略
- 📱 **跨平台**：支持 Android 和 iOS
- 🔧 **易于使用**：简洁的 API 设计，支持单张和批量压缩
- 💪 **健壮性**：完善的错误处理和边界情况处理

## 📊 效果与对比

| 图片类型 | 原图（分辨率, 大小） | Luban（分辨率, 大小） | Wechat（分辨率, 大小） |
| :--- | :--- | :--- | :--- |
| **标准拍照** | 3024×4032, 5.10MB | 1440×1920, 305KB | 1440×1920, 303KB |
| **高清大图** | 4000×6000, 12.10MB | 1440×2160, 318KB | 1440×2160, 305KB |
| **2K 截图** | 1440×3200, 2.10MB | 1440×3200, 148KB | 1440×3200, 256KB |
| **超长记录** | 1242×22080, 6.10MB | 758×13490, 290KB | 744×13129, 256KB |
| **全景横图** | 12000×5000, 8.10MB | 1440×600, 126KB | 1440×600, 123KB |
| **设计原稿** | 6000×6000, 6.90MB | 1440×1440, 263KB | 1440×1440, 279KB |

## 🔬 核心算法特性

本库采用**自适应统一图像压缩算法 (Adaptive Unified Image Compression)**，通过原图的分辨率特征，动态应用差异化策略，实现画质与体积的最优平衡。

### 智能分辨率决策

- **高清基准 (1440p)**：默认以 1440px 作为短边基准，确保在现代 2K/4K 屏幕上的视觉清晰度
- **全景墙策略**：自动识别超大全景图（长边 >10800px），锁定长边为 1440px，保留完整视野
- **超大像素陷阱**：对超过 4096万像素的超高像素图自动执行 1/4 降采样处理
- **长图内存保护**：针对超长截图建立 10.24MP 像素上限，通过等比缩放防止 OOM

### 自适应比特率控制

- **极小图 (<0.5MP)**：几乎不进行有损压缩，防止压缩伪影
- **高频信息图 (0.5-1MP)**：提高编码质量，补偿分辨率损失
- **标准图片 (1-3MP)**：应用平衡系数，对标主流社交软件体验
- **超大图/长图 (>3MP)**：应用高压缩率，显著减少体积

### 健壮性保障

- **膨胀回退**：压缩后体积大于原图时，自动透传原图，确保绝不"负优化"
- **输入防御**：妥善处理极端分辨率输入（0、负数、1px 等），防止崩溃

## 📦 安装

在 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  luban: ^2.0.0
```

然后运行：

```bash
flutter pub get
```

## 💻 使用

### 压缩单张图片

```dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:luban/luban.dart';

Future<void> compressImage() async {
  final ByteData imageData = await rootBundle.load('assets/image.jpg');
  final Uint8List imageBytes = imageData.buffer.asUint8List();
  
  final codec = await ui.instantiateImageCodec(imageBytes);
  final frame = await codec.getNextFrame();
  final ui.Image image = frame.image;
  
  final compressedBytes = await Luban.compress(
    imageBytes,
    image.width,
    image.height,
  );
  
  image.dispose();
  
  print('压缩完成，大小: ${compressedBytes.length / 1024} KB');
}
```

### 批量压缩图片

```dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:luban/luban.dart';

Future<void> compressBatchImages() async {
  final List<Uint8List> imageBytesList = [];
  final List<int> widths = [];
  final List<int> heights = [];
  
  for (final imagePath in imagePaths) {
    final ByteData imageData = await rootBundle.load(imagePath);
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final ui.Image image = frame.image;
    
    imageBytesList.add(imageBytes);
    widths.add(image.width);
    heights.add(image.height);
    
    image.dispose();
  }
  
  final compressedResults = await Luban.compressBatch(
    imageBytesList,
    widths,
    heights,
  );
  
  print('批量压缩完成，共 ${compressedResults.length} 张图片');
}
```

### 完整示例

查看 [example](example) 目录获取完整的使用示例。

## 📄 License

    Copyright 2025 郑梓斌
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
