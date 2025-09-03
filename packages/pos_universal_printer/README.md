# pos_universal_printer

A Flutter plugin for printing POS receipts and labels on various thermal printers. Supports ESC/POS (receipts), TSPL and CPCL (labels). Designed for multi‑role routing (cashier, kitchen, sticker) with job queue, retries, Bluetooth Classic (Android), and TCP/IP (Android & iOS).

## Features

- ESC/POS: text, alignment, bold, barcode, QR, feed/cut, cash drawer (ESC p).
- TSPL & CPCL: builders for labels (TEXT/BARCODE/QRCODE/BITMAP/PRINT).
- Multi‑role mapping (cashier, kitchen, sticker).
- Connectivity: Bluetooth Classic (Android) and TCP 9100 (Android & iOS).
- Reliability: job queue with retry, TCP auto‑reconnect; BT write reconnect fallback.

## Platform support

- Android: Bluetooth Classic (SPP/RFCOMM) and TCP.
- iOS: TCP only (non‑MFi Bluetooth SPP is not supported by iOS).

## Installation

Add the package from pub.dev:

```yaml
dependencies:
  pos_universal_printer: ^0.1.2
```

For Git usage in a monorepo, see the repository README for dependency_overrides instructions.

## Quick start

```dart
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
```

More examples and troubleshooting are available in the root README of the repository.

## License

This package requires a LICENSE file. See the repository root for licensing or add a license file in this package before publishing.
