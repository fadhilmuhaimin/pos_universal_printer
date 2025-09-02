# pos_universal_printer

A Flutter plugin for printing POS receipts and labels on various thermal printers. Supports ESC/POS (receipts), TSPL and CPCL (labels). Designed for multi‑role routing (cashier, kitchen, sticker) with job queue, retries, Bluetooth Classic (Android), and TCP/IP (Android & iOS).

## Key features

- ESC/POS: text, alignment, bold, barcode, QR, feed/cut, cash drawer (ESC p).
- TSPL & CPCL: simple builders for labels (TEXT/BARCODE/QRCODE/BITMAP/PRINT).
- Multi‑role: map different printers per role (cashier, kitchen, sticker).
- Connectivity: Bluetooth Classic (Android) and TCP 9100 (Android & iOS).
- Reliability: job queue with retry and TCP auto‑reconnect; BT write with reconnect fallback.

## Platform & device support

- Android: Bluetooth Classic (SPP/RFCOMM) and TCP.
- iOS: TCP only (non‑MFi Bluetooth SPP is not supported by iOS).
- Common brands like Blue Print that are ESC/POS/TSPL/CPCL compatible should work.

## Requirements

- Flutter 3.19+ (Dart 3.2+).
- Android: targetSdk 31+ recommended (Android 12) due to new Bluetooth permissions.
- iOS: 12.0+ (uses Network.framework for TCP).

## Installation

Option A — from Git (this monorepo):

Add these dependencies and overrides to your app `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  pos_universal_printer:
    git:
      url: https://github.com/fadhilmuhaimin/pos_universal_printer.git
      path: packages/pos_universal_printer

dependency_overrides:
  pos_universal_printer_android:
    git:
      url: https://github.com/fadhilmuhaimin/pos_universal_printer.git
      path: packages/pos_universal_printer_android
  pos_universal_printer_ios:
    git:
      url: https://github.com/fadhilmuhaimin/pos_universal_printer.git
      path: packages/pos_universal_printer_ios
```

Note: this is a federated plugin in a single repo; `dependency_overrides` ensures the platform packages are pulled when using the Git source.

Then:

```sh
flutter pub get
```

Option B — from pub.dev:

- If published:

```yaml
dependencies:
  pos_universal_printer: ^X.Y.Z
```

## Platform setup

### Android

- Bluetooth permissions (Android 12+): the plugin declares them, but you still need to request runtime permissions before scan/connect.
- Make sure the printer is paired in Android Settings for Bluetooth Classic. The plugin’s "scan" lists bonded (paired) devices, not full discovery.
- TCP requires only INTERNET (declared by the plugin).

Optional runtime permission snippet using `permission_handler`:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> ensureBtPermissions() async {
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
  ].request();
}
```

Call `ensureBtPermissions()` before `scanBluetooth()`/`registerDevice()` when using Bluetooth.

### iOS

- TCP/IP (LAN/Wi‑Fi) only. Non‑MFi Bluetooth SPP is not supported.
- Set the deployment target to 12.0+ in `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

Usually no ATS exceptions are required for raw TCP to LAN IPs.

## How to use (quick examples)

### 1) Register per‑role printers (Android Bluetooth or TCP)

```dart
import 'package:pos_universal_printer/pos_universal_printer.dart';

final pos = PosUniversalPrinter.instance;

// TCP (Android & iOS)
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

// Bluetooth (Android only) — from scan
final btDevices = await pos.scanBluetooth().toList();
final selected = btDevices.first; // choose via your UI
await pos.registerDevice(PosPrinterRole.kitchen, selected);
```

### 2) Print ESC/POS receipt (Builder)

```dart
import 'package:pos_universal_printer/src/protocols/escpos/builder.dart';

final b = EscPosBuilder();
b.text('SAMPLE STORE', bold: true, align: PosAlign.center);
b.text('123 Sample St');
b.feed(1);
b.text('Item A           1   $10.00');
b.text('Item B           2   $20.00');
b.feed(1);
b.text('TOTAL                $30.00', bold: true);
b.feed(2);
b.cut();

pos.printEscPos(PosPrinterRole.cashier, b);
```

Or use the built‑in quick renderer for a list of items (58mm/80mm):

```dart
import 'package:pos_universal_printer/src/renderer/receipt_renderer.dart';

final items = [
  ReceiptItem(name: 'Iced Tea', qty: 1, price: 5000),
  ReceiptItem(name: 'Fried Chicken Lvl 3', qty: 1, price: 25000),
];

pos.printReceipt(PosPrinterRole.cashier, items, is80mm: false);
```

### 3) Open the cash drawer

```dart
pos.openDrawer(PosPrinterRole.cashier); // ESC p with default pulse
```

You can tune pulse values: `openDrawer(role, m: 0, t1: 25, t2: 250)`.

### 4) Print TSPL label (TSC/Argox)

```dart
import 'package:pos_universal_printer/src/protocols/tspl/builder.dart';

final tspl = TsplBuilder();
tspl.size(58, 40);
tspl.gap(2, 0);
tspl.density(8);
tspl.text(20, 20, 3, 0, 1, 1, 'Label 58x40');
tspl.barcode(20, 60, 'CODE128', 60, 1, '1234567890');
tspl.printLabel(1);

pos.printTspl(PosPrinterRole.sticker, String.fromCharCodes(tspl.build()));
```

Or send TSPL string samples directly:

```dart
// Simpler with the built‑in helper:
pos.printTspl(PosPrinterRole.sticker, TsplBuilder.sampleLabel58x40());
```

### 5) Print CPCL label (Zebra)

```dart
import 'package:pos_universal_printer/src/protocols/cpcl/builder.dart';

final cpcl = CpclBuilder();
cpcl.page(600, 600, 1);
cpcl.text(0, 50, 50, 'Sample CPCL');
cpcl.barcode('CODE128', 2, 2, 80, 50, 150, '123456789012');
cpcl.qrCode(2, 4, 50, 300, 'https://example.com');
cpcl.printLabel();

pos.printCpcl(PosPrinterRole.sticker, String.fromCharCodes(cpcl.build()));

// Or use the built‑in sample:
pos.printCpcl(PosPrinterRole.sticker, CpclBuilder.sampleLabel());
```

### 6) Send raw bytes

```dart
pos.printRaw(PosPrinterRole.kitchen, [0x1B, 0x40, 0x0A]); // ESC @, LF
```

### 7) Disconnect / cleanup

```dart
await pos.unregisterDevice(PosPrinterRole.kitchen);
await pos.dispose();
```

## Example app

See `example/` for a demo UI that:
- Selects connection type per role (Bluetooth/TCP)
- Scans Bluetooth (Android)
- Tests ESC/POS, TSPL, CPCL, Open Drawer, and a stress test

## Best practices

- Prefer TCP/IP when possible (more stable, works on Android & iOS).
- For Android Bluetooth: ensure the device is paired and grant `bluetoothScan`/`bluetoothConnect` runtime permissions.
- Cash drawer must be connected to the printer’s RJ‑11 port and the printer must support ESC/POS `ESC p`.
- Choose the correct protocol: ESC/POS for receipts, TSPL/CPCL for labels (many label printers won’t accept ESC/POS for labels).

### Paper width and character columns (Blueprint 80/57 mm)

- 80 mm paper with ~72 mm printable width ≈ 48 columns.
- 64 mm printable mode (some models) ≈ ~42 columns.
- 57/58 mm ≈ 32 columns.

You can set columns manually with `ReceiptRenderer.render()`:

```dart
// 72 mm (≈48 columns)
pos.printReceipt(role, items, columns: 48);

// 64 mm (≈42 columns)
pos.printReceipt(role, items, columns: 42);

// 57/58 mm (≈32 columns)
pos.printReceipt(role, items, columns: 32);
```

## Troubleshooting

- Bluetooth scan fails (Android 12+): request runtime permissions before scanning. Some devices also require Location enabled.
- iOS cannot use Bluetooth SPP: platform limitation. Use TCP.
- Nothing printed via TCP: verify IP/port (usually 9100) and printer mode (ESC/POS vs TSPL/CPCL).
- Paper cut not working: not all printers support full cut; use tear bar or device‑specific command.

## License

See the `LICENSE` file in this repo.
