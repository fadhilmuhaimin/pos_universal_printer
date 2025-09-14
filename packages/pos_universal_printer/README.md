# pos_universal_printer

A Flutter plugin for printing POS receipts and labels on various thermal printers. Supports ESC/POS (receipts), TSPL and CPCL (labels). Designed for multi‑role routing (cashier, kitchen, sticker) with job queue, retries, Bluetooth Classic (Android), and TCP/IP (Android & iOS).

## Features

- ESC/POS: text, alignment, bold, barcode, QR, feed/cut, cash drawer (ESC p).
- TSPL & CPCL: builders for labels (TEXT/BARCODE/QRCODE/BITMAP/PRINT).
- **🆕 Custom Sticker API**: Easy-to-use helper for TSPL sticker printing with text alignment, margins, and templates
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
  pos_universal_printer: ^0.2.6
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

## 🆕 Custom Sticker API

Version 0.2.0 introduces a powerful and easy-to-use custom sticker API for TSPL printers:

### Bluetooth Connect/Disconnect with Loading

```dart
import 'package:pos_universal_printer/pos_universal_printer.dart';

class PrinterManager {
  final PosUniversalPrinter printer = PosUniversalPrinter.instance;
  bool _isConnecting = false;
  bool _isDisconnecting = false;
  bool _isConnected = false;

  // Connect printer with loading state
  Future<void> connectPrinter(PosPrinterRole role, PrinterDevice device) async {
    _isConnecting = true;
    // Update UI to show loading...

    try {
      await printer.registerDevice(role, device);
      _isConnected = true;
      // Show success message
    } catch (e) {
      // Show error message
      print('Connection failed: $e');
    } finally {
      _isConnecting = false;
      // Update UI to hide loading
    }
  }

  // Disconnect printer with loading state
  Future<void> disconnectPrinter(PosPrinterRole role) async {
    _isDisconnecting = true;
    // Update UI to show loading...

    try {
      await printer.unregisterDevice(role);
      _isConnected = false;
      // Show disconnect message
    } catch (e) {
      // Show error message
      print('Disconnect failed: $e');
    } finally {
      _isDisconnecting = false;
      // Update UI to hide loading
    }
  }

  // Scan Bluetooth devices
  Future<List<PrinterDevice>> scanBluetooth() async {
    List<PrinterDevice> devices = [];
    await for (PrinterDevice device in printer.scanBluetooth()) {
      devices.add(device);
    }
    return devices;
  }
}
```

## Sticker Printing

### Level 1: Super Simple (ONE-LINER) 

The easiest method to print restaurant invoice stickers. Perfect for beginners who want to get started quickly:

```dart
import 'package:pos_universal_printer/pos_universal_printer.dart';

// Print invoice super simple - only 4 parameters needed!
await CustomStickerPrinter.printInvoice(
  printer: printer,
  role: PosPrinterRole.sticker,
  customer: 'John Doe',
  menu: 'Special Fried Rice',
  details: 'Extra Spicy, No Onions, Low Salt',
);
```

### Level 2: Template with Options (CUSTOMIZABLE) 

Invoice template with customization options for intermediate users. Configure sticker size, fonts, and spacing:

```dart
await CustomStickerPrinter.printInvoiceSticker(
  printer: printer,
  role: PosPrinterRole.sticker,
  customerName: 'John Doe',
  menuName: 'Special Fried Rice',
  modifications: ['Extra Spicy', 'No Onions'],
  note: 'Low Salt',
  stickerSize: StickerSize.mm58x40,
  fontSize: FontSize.large,
);
```

**Available Options:**
- **StickerSize**: `mm40x30`, `mm58x40`, `mm40x25`, `mm32x20`
- **FontSize**: `small`, `medium`, `large`

### Level 3: Multi-Menu Restaurant Style (PROFESSIONAL) 

Print multiple menu items at once, each menu = 1 separate sticker. Perfect for restaurants:

```dart
// Menu items data
List<MenuItem> menuItems = [
  MenuItem('Special Fried Rice', ['Extra Spicy', 'No Onions'], 'Low Salt'),
  MenuItem('Iced Sweet Tea', ['Large Cup'], 'Extra Ice'),
];

// Print all menu items at once
await CustomStickerPrinter.printRestaurantOrder(
  printer: printer,
  role: PosPrinterRole.sticker,
  customerName: 'John Doe',
  menuItems: menuItems,
);
```

### Level 4: Full Custom (ADVANCED) 

For developers who need full control over layout and positioning:

```dart
await CustomStickerPrinter.printSticker(
  printer: printer,
  role: PosPrinterRole.sticker,
  width: 40,
  height: 30,
  gap: 3,
  marginLeft: 1,
  marginTop: 1,
  marginRight: 1,
  marginBottom: 1,
  texts: [
    StickerText('Custom Text', x: 10, y: 5, font: 4, size: 1, alignment: 'left'),
    StickerText('Right Align', x: 10, y: 10, font: 2, size: 1, alignment: 'right'),
  ],
  barcodes: [
    StickerBarcode('123456789', x: 10, y: 15, type: 'CODE128', height: 50),
  ],
);
```

**Available Parameters:**
- **Margins**: `marginLeft`, `marginTop`, `marginRight`, `marginBottom` (in mm)
- **Alignment**: `'left'`, `'center'`, `'right'`
- **Font**: 1-8 (1=smallest, 8=largest)
- **Size**: 1-8 (scale multiplier)
- **Barcode Types**: `CODE128`, `EAN13`, `EAN8`, `CODE39`, `CODE93`

### TSPL quick note (labels)

When printing labels with TSPL, set media size and gap correctly and clear the buffer before printing to avoid extra blank labels:

```dart
final tspl = TsplBuilder();
tspl.size(40, 30); // width x height in mm
tspl.gap(3, 0);    // real gap in mm (2–3 typical)
tspl.direction(0); // Use 0 for normal orientation, 1 if text appears upside down
tspl.reference(0, 0);
tspl.density(8);
tspl.cls();
tspl.text(20, 20, 3, 0, 1, 1, '40x30');
tspl.printLabel(1);
pos.printTspl(PosPrinterRole.sticker, String.fromCharCodes(tspl.build()));

// Or use helper for 40x30 mm:
pos.printTspl(PosPrinterRole.sticker, TsplBuilder.sampleLabel40x30());
```

**Fix for upside down text:** Use `DIRECTION 0` instead of `DIRECTION 1`.

If a single label causes two labels to feed:
- Calibrate media from the printer (GAP/BLACK MARK detect).
- Adjust GAP value to your stock (try 2–4 mm).
- Ensure `CLS`, `DIRECTION`, and `REFERENCE` are set before elements.

---
## 🔄 Blue Thermal Printer Migration (Compat API)
Seamlessly reuse almost all of your existing `blue_thermal_printer` logic.

```dart
import 'package:pos_universal_printer/blue_thermal_compat.dart';

final bt = BlueThermalCompatPrinter();
await bt.connectBluetooth('AA:BB:CC:DD:EE:FF');
await bt.printCustom('HEADER', Size.large, Align.center, bold: true);
await bt.printLeftRight('TOTAL', '125.000', Size.medium);
await bt.printBarcode('123456789012');
await bt.printQRcode('https://example.com');
await bt.printImageAsset('assets/images/akib.png');
await bt.paperCut();
```

Method mapping summary:
- `printCustom` → bold + alignment + size
- `printLeftRight` → padded columns with truncation & tail preservation
- `printNewLine` → feed 1 line
- `printImageAsset` / `printImageBytes` → ESC/POS raster with bit‑image fallback
- `printBarcode` / `printQRcode` → 1D / 2D codes
- `paperCut` → full cut

No global singleton required; you may keep one instance per UI flow.

### Image / Logo Printing (Compat)

Single payload (logo + lines) for maximum Bluetooth stability:
```dart
await bt.printLogoAndLines(
  assetLogoPath: 'assets/images/akib.png',
  lines: [
    CompatLine.text('My Shop', bold: true, align: Align.center),
    CompatLine.text('Jl. Contoh 123'),
    CompatLine.leftRight('Subtotal', '100.000'),
    CompatLine.leftRight('Diskon', '-5.000'),
    CompatLine.leftRight('TOTAL', '95.000', bold: true),
  ],
  preferBitImage: true, // fallback to ESC * if raster unsupported
);
```

Tips:
- If logo prints as a black block → lower threshold or set `preferBitImage: true`.
- If only partial logo prints → reduce asset width (<380px for 58mm usually) or scale down.

### Asset Setup
```yaml
flutter:
  assets:
    - assets/images/akib.png
```
Make sure the asset path matches exactly (case sensitive on some systems).

---
## 🛠 Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Second label starts mid‑way | Printer not fully resetting buffer timing | Add small delay (already built‑in), keep `ensureNewLabel=false` unless required |
| Two labels feed for one print | GAP mismatch or extra FORMFEED | Use correct `GAP`, avoid manual FORMFEED, ensure only one `CLS` |
| Left margin shrinks each sticker | State not reset | We send single `CLS`; avoid custom sequences that add REFERENCE cumulatively |
| Logo = black rectangle | Threshold too aggressive / printer rejects raster | Use `preferBitImage: true` or supply a lighter logo, adjust threshold |
| Bluetooth scan freezes UI | Long synchronous loop | Use provided async scan (stream aggregated) |
| Barcode unreadable | Height or density too low | Increase barcode height / density |
| QR empty | Data too long for size | Shorten data or increase module size (not yet exposed) |

---
## 🔍 Logging & Debug
Use in‑memory logger exposed by `PosUniversalPrinter.instance.logs`.

```dart
final pos = PosUniversalPrinter.instance;
pos.debugLog(LogLevel.debug, 'Manual note before print');
for (final entry in pos.logs) {
  debugPrint('[${entry.level}] ${entry.message}');
}
```

The example app includes a live log viewer to inspect raw TSPL / ESC/POS sequences.

---
## Versioning Policy
- Patch (0.2.x) = additive / docs / fixes
- Minor bump to 0.3.0 reserved for breaking API changes
- 1.0.0 once core protocols + compat considered stable in production

## License

This package requires a LICENSE file. See the repository root for licensing or add a license file in this package before publishing.
