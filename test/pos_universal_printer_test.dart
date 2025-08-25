import 'package:flutter_test/flutter_test.dart';
import 'package:pos_universal_printer/pos_universal_printer.dart';
import 'package:pos_universal_printer/pos_universal_printer_platform_interface.dart';
import 'package:pos_universal_printer/pos_universal_printer_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPosUniversalPrinterPlatform
    with MockPlatformInterfaceMixin
    implements PosUniversalPrinterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PosUniversalPrinterPlatform initialPlatform = PosUniversalPrinterPlatform.instance;

  test('$MethodChannelPosUniversalPrinter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPosUniversalPrinter>());
  });

  test('getPlatformVersion', () async {
    PosUniversalPrinter posUniversalPrinterPlugin = PosUniversalPrinter();
    MockPosUniversalPrinterPlatform fakePlatform = MockPosUniversalPrinterPlatform();
    PosUniversalPrinterPlatform.instance = fakePlatform;

    expect(await posUniversalPrinterPlugin.getPlatformVersion(), '42');
  });
}
