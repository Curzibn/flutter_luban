import 'dart:ffi';
import 'dart:io';

const String _libName = 'turbojpeg';

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
