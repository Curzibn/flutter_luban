# Luban Flutter

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![pub package](https://img.shields.io/pub/v/luban.svg)](https://pub.dev/packages/luban)

[English](README_EN.md) | [中文](README.md)

Luban Flutter — An efficient and concise Flutter image compression plugin that closely replicates the compression strategy of WeChat Moments.

## 📑 Table of Contents

- [📖 Project Description](#-project-description)
- [✨ Features](#-features)
- [📊 Effects & Comparison](#-effects--comparison)
  - [🔬 Core Algorithm Features](#-core-algorithm-features)
- [📦 Installation](#-installation)
- [💻 Usage](#-usage)
  - [Compress a Single Image](#compress-a-single-image)
  - [Compress Multiple Images](#compress-multiple-images)
- [📄 License](#-license)

## 📖 Project Description

Images are an essential part of app development. With the increasing resolution of mobile cameras, image compression has become a critical issue. While there are many articles on simple cropping and compression, choosing the right crop and compression levels is tricky—cropping too much results in tiny images, while over-compressing leads to poor display quality.

Naturally, one wonders how the industry giant "WeChat" handles this. `Luban` was derived by reverse-engineering WeChat Moments' behavior: we sent nearly 100 images with different resolutions and compared the originals with WeChat's outputs to infer the compression strategy.

Since this behavior is inferred from observation, the results may not match WeChat exactly, but they are very close. See the comparison below!

This library is the **Flutter version** of `Luban`, using **TurboJPEG** for high-performance image compression, providing a simple API and compression results close to WeChat Moments.

## ✨ Features

- 🚀 **High Performance**: Based on TurboJPEG native library, fast compression speed
- 🎯 **Smart Compression**: Adaptive compression algorithm that dynamically adjusts strategy based on image characteristics
- 📱 **Cross-Platform**: Supports Android and iOS
- 🔧 **Easy to Use**: Simple API design, supports single and batch compression
- 💪 **Robust**: Comprehensive error handling and edge case handling

## 📊 Effects & Comparison

| Image Type | Original | Luban | WeChat |
| :--- | :--- | :--- | :--- |
| **Standard Photo** | 3024×4032, 5.10MB | 1440×1920, 305KB | 1440×1920, 303KB |
| **High-Res Photo** | 4000×6000, 12.10MB | 1440×2160, 318KB | 1440×2160, 305KB |
| **2K Screenshot** | 1440×3200, 2.10MB | 1440×3200, 148KB | 1440×3200, 256KB |
| **Long Screenshot** | 1242×22080, 6.10MB | 758×13490, 290KB | 744×13129, 256KB |
| **Panorama** | 12000×5000, 8.10MB | 1440×600, 126KB | 1440×600, 123KB |
| **Design Draft** | 6000×6000, 6.90MB | 1440×1440, 263KB | 1440×1440, 279KB |

## 🔬 Core Algorithm Features

This library uses an **Adaptive Unified Image Compression** algorithm that dynamically applies differentiated strategies based on the original image's resolution characteristics to achieve optimal balance between quality and file size.

### Intelligent Resolution Decision

- **High-Definition Baseline (1440p)**: Uses 1440px as the default short-side baseline, ensuring visual clarity on modern 2K/4K displays
- **Panorama Wall Strategy**: Automatically identifies ultra-wide panoramas (long side >10800px), locks the long side to 1440px while preserving the full field of view
- **Mega-Pixel Trap**: Automatically applies 1/4 downsampling to images exceeding 41 megapixels (≈40.96 MP)
- **Long Image Memory Protection**: Establishes a 10.24MP pixel cap for ultra-long screenshots, reducing the risk of out-of-memory (OOM) errors through proportional scaling

### Adaptive Bitrate Control

- **Tiny Images (<0.5MP)**: Minimal lossy compression to prevent compression artifacts
- **High-Frequency Images (0.5-1MP)**: Enhanced encoding quality to compensate for resolution loss
- **Standard Images (1-3MP)**: Balanced coefficients matching mainstream social media apps
- **Large/Long Images (>3MP)**: High compression ratios to significantly reduce file size

### Robustness Guarantees

- **Inflation Fallback**: Automatically returns the original image if compressed size exceeds original, avoiding making files larger after compression
- **Input Defense**: Safely handles extreme resolution inputs (0, negative, 1px, etc.), preventing crashes

## 📦 Installation

Add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  luban: ^2.0.0
```

Then run:

```bash
flutter pub get
```

## 💻 Usage

### Compress a Single Image

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
  
  print('Compression completed, size: ${compressedBytes.length / 1024} KB');
}
```

### Compress Multiple Images

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
  
  print('Batch compression completed, ${compressedResults.length} images');
}
```

### Complete Example

See the [example](example) directory for a complete usage example.

## 📄 License

    Copyright 2025 Zibin
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

