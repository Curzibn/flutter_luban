import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'native_library.dart';
import 'generated_bindings.dart';
import 'tj_constants.dart';

class TurboJpeg {
  late LibJpegTurboBindings _bindings;
  late ffi.Pointer<ffi.Void> _handle;

  static final Finalizer<ffi.Pointer<ffi.Void>> _finalizer = Finalizer(
    (handle) {
      final bindings = LibJpegTurboBindings(turboJpegLib);
      bindings.tjDestroy(handle);
    },
  );

  bool _isInitialized = false;

  TurboJpeg() {
    _bindings = LibJpegTurboBindings(turboJpegLib);
    _init();
  }

  void _init() {
    _handle = _bindings.tjInitCompress();
    if (_handle == ffi.nullptr) {
      throw Exception('Failed to initialize TurboJPEG compressor instance');
    }
    _isInitialized = true;
    _finalizer.attach(this, _handle);
  }

  void dispose() {
    if (_isInitialized) {
      _finalizer.detach(this);
      _bindings.tjDestroy(_handle);
      _isInitialized = false;
    }
  }

  Uint8List compress(
    Uint8List sourceData,
    int width,
    int height, {
    int quality = 80,
    int pixelFormat = TJConstants.TJPF_RGBA,
    int subsample = TJConstants.TJSAMP_444,
    int flags = TJConstants.TJFLAG_FASTDCT,
  }) {
    if (!_isInitialized) _init();

    final int srcSize = width * height * 4;
    if (sourceData.length != srcSize) {
      throw ArgumentError(
        'Source data length mismatch. Expected $srcSize, got ${sourceData.length}',
      );
    }

    return using((Arena arena) {
      final ffi.Pointer<ffi.Uint8> srcBuf = arena<ffi.Uint8>(srcSize);
      final Uint8List srcList = srcBuf.asTypedList(srcSize);
      srcList.setAll(0, sourceData);

      final ffi.Pointer<ffi.Pointer<ffi.Uint8>> jpegBufPtr =
          arena<ffi.Pointer<ffi.Uint8>>();
      jpegBufPtr.value = ffi.nullptr;

      final ffi.Pointer<ffi.UnsignedLong> jpegSizePtr =
          arena<ffi.UnsignedLong>();
      jpegSizePtr.value = 0;

      final int result = _bindings.tjCompress2(
        _handle,
        srcBuf.cast<ffi.UnsignedChar>(),
        width,
        0,
        height,
        pixelFormat,
        jpegBufPtr.cast<ffi.Pointer<ffi.UnsignedChar>>(),
        jpegSizePtr,
        subsample,
        quality,
        flags,
      );

      if (result != 0) {
        final ffi.Pointer<ffi.Char> err = _bindings.tjGetErrorStr();
        final String errorStr = err.cast<Utf8>().toDartString();
        throw Exception('TurboJPEG compression failed: $errorStr');
      }

      final int compressedSize = jpegSizePtr.value.toInt();
      final ffi.Pointer<ffi.Uint8> resultBuf =
          jpegBufPtr.value.cast<ffi.Uint8>();

      final Uint8List dartResult =
          Uint8List.fromList(resultBuf.asTypedList(compressedSize));

      _bindings.tjFree(resultBuf.cast<ffi.UnsignedChar>());

      return dartResult;
    });
  }
}
