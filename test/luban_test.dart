import 'package:flutter_test/flutter_test.dart';
import 'package:luban/luban_platform_interface.dart';
import 'package:luban/luban_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLubanPlatform
    with MockPlatformInterfaceMixin
    implements LubanPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final LubanPlatform initialPlatform = LubanPlatform.instance;

  test('$MethodChannelLuban is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLuban>());
  });

  test('getPlatformVersion', () async {
    MockLubanPlatform fakePlatform = MockLubanPlatform();
    LubanPlatform.instance = fakePlatform;

    expect(await LubanPlatform.instance.getPlatformVersion(), '42');
  });
}
