import 'package:flutter_test/flutter_test.dart';
import 'package:pos_universal_printer/pos_universal_printer.dart';

void main() {
  test('builds ESC/POS bytes for init, aligned bold text, feed and cut', () {
    final b = EscPosBuilder()
      ..init()
      ..text('Hi', align: PosAlign.center, bold: true)
      ..feed(2)
      ..cut();

    expect(b.build(), [
      0x1B, 0x40, // ESC @ init
      0x1B, 0x61, 0x01, // ESC a 1 center
      0x1B, 0x45, 0x01, // ESC E 1 bold on
      0x48, 0x69, 0x0A, // "Hi\n"
      0x1B, 0x45, 0x00, // ESC E 0 bold off
      0x1B, 0x64, 0x02, // ESC d 2 feed
      0x1D, 0x56, 0x42, 0x00, // GS V full cut
    ]);
  });

  test('feed with non-positive lines adds nothing', () {
    final b = EscPosBuilder()..feed(0);
    expect(b.build(), isEmpty);
  });
}
