import 'package:pos_universal_printer/pos_universal_printer.dart';
import 'package:pos_universal_printer/src/renderer/receipt_renderer.dart';

void main() async {
  final pos = PosUniversalPrinter.instance;
  await pos.registerDevice(
    PosPrinterRole.cashier,
    PrinterDevice(
      id: '192.168.1.50:9100',
      name: 'Cashier LAN',
      type: PrinterType.tcp,
      address: '192.168.1.50',
      port: 9100,
    ),
  );
  pos.printReceipt(
    PosPrinterRole.cashier,
    [ReceiptItem(name: 'Item A', qty: 1, price: 10000)],
    is80mm: false,
  );
}
