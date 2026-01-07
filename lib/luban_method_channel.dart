import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'luban_platform_interface.dart';

/// An implementation of [LubanPlatform] that uses method channels.
class MethodChannelLuban extends LubanPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('luban');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
