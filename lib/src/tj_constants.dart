// ignore_for_file: constant_identifier_names

/// TurboJPEG 常量定义
///
/// 包含像素格式、色度子采样模式和压缩标志的常量值。
/// 这些常量对应 TurboJPEG C 库中的宏定义。
class TJConstants {
  /// RGB 像素格式（3 字节/像素）
  static const int TJPF_RGB = 0;

  /// BGR 像素格式（3 字节/像素）
  static const int TJPF_BGR = 1;

  /// RGBX 像素格式（4 字节/像素，X 为填充）
  static const int TJPF_RGBX = 2;

  /// BGRX 像素格式（4 字节/像素，X 为填充）
  static const int TJPF_BGRX = 3;

  /// XBGR 像素格式（4 字节/像素，X 为填充）
  static const int TJPF_XBGR = 4;

  /// XRGB 像素格式（4 字节/像素，X 为填充）
  static const int TJPF_XRGB = 5;

  /// 灰度像素格式（1 字节/像素）
  static const int TJPF_GRAY = 6;

  /// RGBA 像素格式（4 字节/像素，含 Alpha 通道）
  static const int TJPF_RGBA = 7;

  /// BGRA 像素格式（4 字节/像素，含 Alpha 通道）
  static const int TJPF_BGRA = 8;

  /// ABGR 像素格式（4 字节/像素，含 Alpha 通道）
  static const int TJPF_ABGR = 9;

  /// ARGB 像素格式（4 字节/像素，含 Alpha 通道）
  static const int TJPF_ARGB = 10;

  /// CMYK 像素格式（4 字节/像素）
  static const int TJPF_CMYK = 11;

  /// 4:4:4 色度子采样（无子采样，最高质量）
  static const int TJSAMP_444 = 0;

  /// 4:2:2 色度子采样（水平减半）
  static const int TJSAMP_422 = 1;

  /// 4:2:0 色度子采样（水平和垂直都减半，最常用）
  static const int TJSAMP_420 = 2;

  /// 灰度模式（无色度信息）
  static const int TJSAMP_GRAY = 3;

  /// 4:4:0 色度子采样（垂直减半）
  static const int TJSAMP_440 = 4;

  /// 4:1:1 色度子采样
  static const int TJSAMP_411 = 5;

  /// 4:4:1 色度子采样
  static const int TJSAMP_441 = 6;

  /// 未知子采样模式
  static const int TJSAMP_UNKNOWN = -1;

  /// 图像数据从底部向上存储
  static const int TJFLAG_BOTTOMUP = 2;

  /// 强制使用 MMX 指令集
  static const int TJFLAG_FORCEMMX = 8;

  /// 强制使用 SSE 指令集
  static const int TJFLAG_FORCESSE = 16;

  /// 强制使用 SSE2 指令集
  static const int TJFLAG_FORCESSE2 = 32;

  /// 强制使用 SSE3 指令集
  static const int TJFLAG_FORCESSE3 = 128;

  /// 使用快速上采样算法
  static const int TJFLAG_FASTUPSAMPLE = 256;

  /// 禁止重新分配输出缓冲区
  static const int TJFLAG_NOREALLOC = 1024;

  /// 使用快速 DCT 算法（牺牲精度换取速度）
  static const int TJFLAG_FASTDCT = 2048;

  /// 使用精确 DCT 算法（牺牲速度换取精度）
  static const int TJFLAG_ACCURATEDCT = 4096;
}
