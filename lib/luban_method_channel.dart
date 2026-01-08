import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'luban_platform_interface.dart';

class MethodChannelLuban extends LubanPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('luban');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
