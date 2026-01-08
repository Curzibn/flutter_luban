import 'dart:ffi';
import 'dart:io';

const String _libName = 'turbojpeg';

/// TurboJPEG 动态链接库实例
///
/// 根据当前平台自动加载对应的原生库：
/// - Android: libturbojpeg.so
/// - iOS: 静态链接到进程
/// - macOS: libturbojpeg.dylib
/// - Windows: turbojpeg.dll
///
/// 在不支持的平台上抛出 [UnsupportedError]
final DynamicLibrary turboJpegLib = () {
  if (Platform.isAndroid) {
    try {
      return DynamicLibrary.open('lib$_libName.so');
    } catch (e) {
      return DynamicLibrary.open('lib$_libName.so');
    }
  } else if (Platform.isIOS) {
    return DynamicLibrary.process();
  } else if (Platform.isMacOS) {
    return DynamicLibrary.open('lib$_libName.dylib');
  } else if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();
