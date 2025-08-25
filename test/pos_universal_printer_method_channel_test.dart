import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_universal_printer/pos_universal_printer_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelPosUniversalPrinter platform = MethodChannelPosUniversalPrinter();
  const MethodChannel channel = MethodChannel('pos_universal_printer');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
