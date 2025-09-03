import 'package:flutter/material.dart';
import 'package:pos_universal_printer/pos_universal_printer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('pos_universal_printer example')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
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
              pos.openDrawer(PosPrinterRole.cashier);
            },
            child: const Text('Test Open Drawer'),
          ),
        ),
      ),
    );
  }
}
