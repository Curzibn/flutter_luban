import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'luban_method_channel.dart';

abstract class LubanPlatform extends PlatformInterface {
  /// Constructs a LubanPlatform.
  LubanPlatform() : super(token: _token);

  static final Object _token = Object();

  static LubanPlatform _instance = MethodChannelLuban();

  /// The default instance of [LubanPlatform] to use.
  ///
  /// Defaults to [MethodChannelLuban].
  static LubanPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LubanPlatform] when
  /// they register themselves.
  static set instance(LubanPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
