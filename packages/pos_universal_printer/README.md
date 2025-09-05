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
  pos_universal_printer: ^0.2.0
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

### Basic Sticker with Text Alignment

```dart
import 'package:pos_universal_printer/pos_universal_printer.dart';

// Create sticker content with aligned text
final stickerContent = CustomStickerPrinter.createSticker(
  widthMm: 40,
  heightMm: 30,
  gapMm: 3,
  texts: [
    StickerText(
      text: 'Product Name',
      x: 0,
      y: 8,
      font: 3,           // Font size (1-8, where 1 is smallest)
      size: 1,           // Size multiplier (1x, 2x, etc.)
      alignment: 'center' // 'left', 'center', 'right'
    ),
    StickerText(
      text: '\$19.99',
      x: 0,
      y: 20,
      font: 4,
      size: 1,
      alignment: 'right'
    ),
  ],
);

// Print the sticker
await pos.printTspl(PosPrinterRole.sticker, stickerContent);
```

### Invoice Style Sticker

Perfect for restaurant order stickers with customer info, timestamps, and modifications:

```dart
// Sample menu item data
final menuItem = MenuItemModel(
  menuName: 'Nasi Goreng Spesial',
  modifications: ['Extra Pedas', 'Tanpa Bawang'],
  note: 'Jangan terlalu asin',
  customerName: 'John Doe',
);

// Create invoice-style sticker
final invoiceSticker = CustomStickerPrinter.createInvoiceSticker(
  menuItem: menuItem,
  widthMm: 58,        // Sticker width
  gapMm: 3,           // Gap between stickers
  marginLeft: 3,      // Left margin
  marginTop: 3,       // Top margin
  marginRight: 3,     // Right margin
  marginBottom: 3,    // Bottom margin
);

// Print the invoice sticker
await pos.printTspl(PosPrinterRole.sticker, invoiceSticker);
```

This creates a professionally formatted sticker with:
- Customer name at the top
- Current date and time
- Menu item name
- Modifications and notes (comma-separated, smaller font)
- All text left-aligned for easy reading

### Built-in Templates

Quick templates for common use cases:

```dart
// 40x30mm product sticker
final productSticker = CustomStickerPrinter.printProductSticker40x30(
  productName: 'Coffee Beans',
  price: '\$12.99',
  gapMm: 3,
);

// 58x40mm address label
final addressSticker = CustomStickerPrinter.printAddressSticker58x40(
  name: 'John Doe',
  address: '123 Main St\nCity, State 12345',
  phone: '+1 (555) 123-4567',
  gapMm: 3,
);
```

### Advanced Features

#### Four-Side Margins
```dart
StickerText(
  text: 'Centered with margins',
  x: 0,
  y: 10,
  font: 3,
  size: 1,
  alignment: 'center',
  marginLeft: 5,    // 5mm left margin
  marginTop: 2,     // 2mm top margin  
  marginRight: 5,   // 5mm right margin
  marginBottom: 2,  // 2mm bottom margin
)
```

#### Left-Right Same Line
```dart
StickerText(
  text: 'Left Text',
  rightText: 'Right Text',  // Automatically positioned on the right
  x: 0,
  y: 15,
  font: 2,
  size: 1,
  alignment: 'left',
)
```

#### Barcodes and QR Codes
```dart
StickerBarcode(
  x: 10,
  y: 25,
  codeType: 'QR',
  content: 'https://example.com',
  width: 3,
  height: 3,
)
```

### Parameter Reference

#### StickerText Parameters
- **text**: Main text content (required)
- **rightText**: Optional text for right side of same line
- **x, y**: Position coordinates in mm
- **font**: Font size 1-8 (1 = smallest, 8 = largest)
- **size**: Size multiplier (1 = normal, 2 = double size, etc.)
- **alignment**: 'left', 'center', 'right'
- **marginLeft/Top/Right/Bottom**: Margins in mm
- **widthMm**: Available width for positioning calculations

#### Font Size Guide
- **Font 1**: Smallest reliable size (recommended for notes/modifications)
- **Font 2-3**: Small text (good for details)
- **Font 4-5**: Medium text (good for product names)
- **Font 6-8**: Large text (good for titles/prices)

**Note**: `size` parameter is a multiplier, so `size: 2` makes the font 2x larger than normal.

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

More examples and troubleshooting are available in the root README of the repository.

## License

This package requires a LICENSE file. See the repository root for licensing or add a license file in this package before publishing.
