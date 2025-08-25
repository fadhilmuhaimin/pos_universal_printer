import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pos_universal_printer/pos_universal_printer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plugin initialization', (tester) async {
    final printer = PosUniversalPrinter.instance;
    expect(printer, isNotNull);
  });
}
