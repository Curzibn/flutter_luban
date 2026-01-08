import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'luban_method_channel.dart';

abstract class LubanPlatform extends PlatformInterface {
  LubanPlatform() : super(token: _token);

  static final Object _token = Object();

  static LubanPlatform _instance = MethodChannelLuban();

  static LubanPlatform get instance => _instance;

  static set instance(LubanPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
