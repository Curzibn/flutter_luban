## 2.0.2
- 修复 iOS 端安装时找不到 TurboJPEG 依赖导致 pod install 失败的问题（#2）：改为随插件直接内嵌 TurboJPEG.xcframework，不再依赖独立本地 pod

## 2.0.1
- 发布优化重构的核心架构

## 2.0.0
- 首次发布 Flutter 版本
- 支持单张/批量图片压缩
- 基于 TurboJPEG 高性能压缩引擎
- 智能分辨率决策和自适应比特率控制