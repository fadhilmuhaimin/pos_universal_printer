# pos_universal_printer

Modern unified printing (Receipts + Stickers/Labels) for Flutter.

Supports ESC/POS (receipts), TSPL & CPCL (labels), multi‑role routing (cashier, kitchen, sticker), Bluetooth Classic (Android) & TCP/IP (Android + iOS), plus a powerful **Custom Sticker API** with 4 levels of complexity.

✅ NEW v0.2.4:
- Logo / image printing added to compat layer via `printLogoAndLines(assetLogoPath: ...)`
- Bit‑image fallback (`preferBitImage: true`) for older printers that reject GS v 0 raster
- Improved left‑right alignment padding (legacy style with smart truncation)
- Threshold tuning guide for clearer logos (avoid all‑black or overly faint output)
- Single‑payload combined job (logo + lines) reduces Bluetooth fragmentation

Previous (v0.2.3): Blue Thermal Printer (kakzaki.dev) compatibility facade (`BlueThermalCompatPrinter`) → migrate with almost no refactor (keep your old calls: `printCustom`, `printLeftRight`, `printNewLine`, `paperCut`) while adding modern multi‑role + Wi‑Fi/TCP + sticker APIs.

---

## Quick Overview

| Use Case | Old blue_thermal_printer | This Package |
|----------|-------------------------|--------------|
| Basic receipt text | `printCustom` | `BlueThermalCompatPrinter.printCustom` or `EscPosBuilder` |
| Left/Right values | `printLeftRight` | Same name (compat) or manual string alignment |
| New line | `printNewLine` | Same name |
| Cut paper | `paperCut` | Same name (compat) or `builder.cut()` |
| Open cash drawer | (custom command) | `pos.openDrawer(role)` |
| Bluetooth Android | Yes | Yes |
| Wi‑Fi/TCP iOS/Android | Manual socket | Built‑in role based routing |
| Stickers / per menu label | Not native | TSPL powered sticker API |
| Multi‑menu restaurant stickers | Manual loops | `printRestaurantOrder()` |
| Invoice style 1 menu = 1 sticker | Hard | Built‑in universal helpers |
| Migration effort | — | LOW (compat facade) |

---

## Key Features

- ESC/POS: text, alignment, bold, barcode, QR, feed/cut, cash drawer (ESC p).
- TSPL & CPCL: simple builders for labels (TEXT/BARCODE/QRCODE/BITMAP/PRINT).
- Multi‑role: map different printers per role (cashier, kitchen, sticker).
- Connectivity: Bluetooth Classic (Android) and TCP 9100 (Android & iOS).
- Reliability: job queue with retry and TCP auto‑reconnect; BT write with reconnect fallback.
 - Logo / Image printing: GS v 0 raster + legacy ESC * bit‑image fallback for high compatibility.

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

## Platform Setup

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

## How To Use

### 0) (Optional) Blue Thermal Printer Style – Minimal Migration

```dart
import 'package:pos_universal_printer/pos_universal_printer.dart';

final compat = BlueThermalCompatPrinter.instance;
compat.defaultRole = PosPrinterRole.cashier; // choose role
compat.setPaper80mm(true); // or false for 58mm

// Register a device first (Bluetooth or TCP)
await PosUniversalPrinter.instance.registerDevice(
  PosPrinterRole.cashier,
  PrinterDevice(
    id: '192.168.1.50:9100',
    name: 'LAN Printer',
    type: PrinterType.tcp,
    address: '192.168.1.50',
    port: 9100,
  ),
);

compat.printCustom('DEMO STORE', Size.boldLarge.val, Align.center.val);
compat.printCustom('123 Sample St', Size.medium.val, Align.center.val);
compat.printLeftRight('Cashier:', 'Alex', Size.bold.val);
compat.printLeftRight('Total', '458.30', Size.boldLarge.val);
compat.printCustom('Thank You :)', Size.bold.val, Align.center.val);
compat.paperCut();
```

#### Printing a Logo (Compat One‑Shot)

```dart
await compat.printLogoAndLines(
  assetLogoPath: 'assets/images/akib.png', // ensure declared in pubspec
  logoThreshold: 170,        // tune 120–210 (higher = darker)
  preferBitImage: true,      // legacy ESC * path first (better for older models)
  lines: [
    CompatLine('DEMO STORE', Size.boldLarge.val, Align.center.val),
    CompatLine('123 Sample St', Size.medium.val, Align.center.val),
    CompatLine('', Size.normal.val, Align.left.val),
    CompatLine('Cashier: Alex', Size.bold.val, Align.left.val),
    CompatLine('Total: $58.30', Size.boldLarge.val, Align.left.val),
    CompatLine('Thank You :)', Size.bold.val, Align.center.val),
  ],
);
compat.paperCut();
```

If the logo appears as a black bar:
1. Raise `logoThreshold` (e.g. 185–200)
2. Keep `preferBitImage: true`
3. Ensure width ≤384 px (58mm) or ≤512 px (80mm)
4. Use a higher contrast source PNG

You can gradually migrate to the richer APIs (builders, renderer, stickers) later.

---

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

### 2) Print Custom Sticker Labels (TSPL)

```dart
// Ready-to-use template - easiest!
CustomStickerPrinter.printProductSticker40x30(
  printer: pos,
  role: PosPrinterRole.sticker,
  productName: 'ARABICA COFFEE',
  productCode: 'KA001',
  price: 'Rp 35.000',
  barcodeData: '1234567890',
);

// Custom layout - full control  
CustomStickerPrinter.printSticker(
  printer: pos,
  role: PosPrinterRole.sticker,
  width: 40,    // mm - match your physical media
  height: 30,   // mm - match your physical media
  texts: [
  StickerText('BIG TITLE', x: 0, y: 0, font: 3),
    StickerText('Detail info', x: 0, y: 8, font: 2),
  ],
  barcode: StickerBarcode('123456', x: 0, y: 16, height: 8),
);
```

**📖 Full custom sticker documentation:** [CUSTOM_STICKER_API.md](CUSTOM_STICKER_API.md)

**🔧 Troubleshooting upside-down text:** [PRINT_ORIENTATION_FIX.md](PRINT_ORIENTATION_FIX.md)

### 3) Print ESC/POS Receipt (Builder)

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

### 4) Open the Cash Drawer

```dart
pos.openDrawer(PosPrinterRole.cashier); // ESC p with default pulse
```

You can tune pulse values: `openDrawer(role, m: 0, t1: 25, t2: 250)`.

### 5) Print TSPL Label (TSC/Argox)

```dart
import 'package:pos_universal_printer/src/protocols/tspl/builder.dart';

final tspl = TsplBuilder();
tspl.size(58, 40);
tspl.gap(2, 0); // adjust to your media's real gap (mm)
tspl.direction(1);
tspl.reference(0, 0);
tspl.density(8);
tspl.cls();
tspl.text(20, 20, 3, 0, 1, 1, 'Label 58x40');
tspl.barcode(20, 60, 'CODE128', 60, 1, '1234567890');
tspl.printLabel(1);

pos.printTspl(PosPrinterRole.sticker, String.fromCharCodes(tspl.build()));
```

**⚠️ Orientation Issue Fix**: If text appears upside down, use `DIRECTION 0` instead of `DIRECTION 1`:

```dart
// For normal text orientation (not upside down)
final sb = StringBuffer();
sb.writeln('SIZE 58 mm, 40 mm');
sb.writeln('GAP 2 mm, 0 mm');
sb.writeln('DIRECTION 0');      // 0 = normal, 1 = reversed
sb.writeln('REFERENCE 0,0');
sb.writeln('DENSITY 8');
sb.writeln('CLS');
sb.writeln('TEXT 20,20,"3",0,1,1,"Normal Text"');
sb.writeln('PRINT 1');
pos.printTspl(PosPrinterRole.sticker, sb.toString());
```

Or send TSPL string samples directly:

```dart
// Simpler with the built‑in helpers:
pos.printTspl(PosPrinterRole.sticker, TsplBuilder.sampleLabel58x40());
// For 40x30 mm labels (common size), tune the gap if needed (default 3 mm):
pos.printTspl(PosPrinterRole.sticker, TsplBuilder.sampleLabel40x30());

// If your printer feeds an extra blank label:
// 1) Calibrate the media from the printer panel (GAP/BLACK MARK detect).
// 2) Adjust GAP in mm to match your real inter‑label gap (e.g. gap 2 or 3).
// 3) Ensure each job starts with CLS and sets DIRECTION/REFERENCE.
```

### 6) Print CPCL Label (Zebra)

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

### 7) Send Raw Bytes

```dart
pos.printRaw(PosPrinterRole.kitchen, [0x1B, 0x40, 0x0A]); // ESC @, LF
```

### 8) Disconnect / Cleanup

---

## Sticker / Invoice Multi‑Level API (Summary)

| Level | Method | Use Case |
|-------|--------|----------|
| 1 | `printInvoice()` | One‑liner quick invoice sticker |
| 2 | `printInvoiceSticker()` | Template with size + font options |
| 3 | `printRestaurantOrder()` | Multi menu (each menu = 1 sticker) |
| 4 | `printSticker()` | Full manual control TSPL (X/Y/fonts/margins) |

Invoice style and POS JSON data both internally call the same universal printing logic (consistent margins, wrapping, per‑sticker reset).

---

## Migration Guide from blue_thermal_printer

1. Remove `blue_thermal_printer` dependency.
2. Add `pos_universal_printer` dependency.
3. Replace import:
  ```dart
  // OLD
  import 'package:blue_thermal_printer/blue_thermal_printer.dart';
  // NEW
  import 'package:pos_universal_printer/pos_universal_printer.dart';
  ```
4. Replace instance:
  ```dart
  // OLD
  final bluetooth = BlueThermalPrinter.instance;
  // NEW
  final compat = BlueThermalCompatPrinter.instance;
  compat.defaultRole = PosPrinterRole.cashier;
  ```
5. Connection:
  - OLD: `bluetooth.connect(device)`
  - NEW: `await PosUniversalPrinter.instance.registerDevice(role, PrinterDevice(...))`
6. Printing method mapping:

| Old Method | New (Compat) | Notes |
|------------|--------------|-------|
| `printCustom(text, size, align)` | Same name | Size mapped to bold if >= bold enum |
| `printLeftRight(a,b,size)` | Same name | Composes single padded line |
| `printNewLine()` | Same name | feed 1 line |
| `printImageBytes(bytes)` | Same name | Provide ESC/POS raster bytes |
| `printLogoAndLines(assetLogoPath:, lines:)` | NEW helper | Logo + text in one payload |
| `printQRcode(data)` | Same name | Model 2 QR |
| `printBarcode(data)` | Same name | Code128 |
| `paperCut()` | Same name | Full cut |
| (open drawer) | `pos.openDrawer(role)` | Use core API |

7. Add advanced features progressively:
  - Switch to `EscPosBuilder` for fine control
  - Adopt sticker APIs for kitchen prep or per‑item labels
  - Use roles: cashier vs kitchen vs sticker printers

### Character Width Approximation
Call `compat.setPaper80mm(true/false)` to switch 48 vs 32 column padding for `printLeftRight` composition.

### Moving to Stickers
Keep receipt code unchanged; add invoice style sticker buttons using:

```dart
CustomStickerPrinter.printInvoice(
  printer: PosUniversalPrinter.instance,
  role: PosPrinterRole.sticker,
  customer: 'John Doe',
  menu: 'Special Fried Rice',
  details: 'Extra Spicy, No Onions',
);
```

For multi menu:

```dart
CustomStickerPrinter.printRestaurantOrder(
  printer: PosUniversalPrinter.instance,
  role: PosPrinterRole.sticker,
  customerName: 'Budi',
  menuItems: [
  MenuItem('Brown Sugar Coffee', ['Less Sugar'], 'Sauce on the side'),
  MenuItem('Iced Sweet Tea', ['Large Cup'], 'Extra Ice'),
  ],
);
```

---

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

### TSPL print issues (sticker labels)

**Text appears upside down/inverted:**
- Change `DIRECTION 1` to `DIRECTION 0` in your TSPL commands
- Test both orientations to see which works with your printer model

**Label positioning problems:**
- Ensure `CLS` is called before drawing elements
- Set `REFERENCE 0,0` for consistent positioning
- Adjust coordinates in TEXT/BARCODE commands

**Extra blank labels printing:**
- Calibrate media detection on printer (GAP/BLACK MARK)
- Adjust GAP value to match your actual label gap (typically 2-3mm)
- Use exactly one `PRINT 1` command per job

**Example fixed orientation code:**
```dart
final sb = StringBuffer();
sb.writeln('SIZE 58 mm, 40 mm');
sb.writeln('GAP 2 mm, 0 mm');
sb.writeln('DIRECTION 0');      // Try 0 first, then 1 if still wrong
sb.writeln('REFERENCE 0,0');
sb.writeln('DENSITY 8');
sb.writeln('CLS');
sb.writeln('TEXT 20,20,"3",0,1,1,"NORMAL TEXT"');
sb.writeln('PRINT 1');
pos.printTspl(PosPrinterRole.sticker, sb.toString());
```

**Testing orientation in the example app:**
- Use "Test TSPL" button for the original implementation (may appear upside down)
- Use "TSPL Fixed" button for the corrected orientation (DIRECTION 0)
- Use "Test Both" button to print both orientations and compare
- iOS cannot use Bluetooth SPP: platform limitation. Use TCP.
- Nothing printed via TCP: verify IP/port (usually 9100) and printer mode (ESC/POS vs TSPL/CPCL).
- Paper cut not working: not all printers support full cut; use tear bar or device‑specific command.

### TSPL Layout Tips (40×30 mm)

- 203 dpi ≈ 8 dots/mm, so 40×30 mm ≈ 320×240 dots.
- Set REFERENCE(x,y) to create top/left margins in dots.
- For right alignment, estimate text width: chars × 24 × xMultiplier (font 3 ~24 dots/char).
- Bottom placement: y ≈ innerHeight − charHeight.
- Always `CLS` before drawing.

### Logo Printing Issues (ESC/POS)

| Symptom | Cause | Fix |
|---------|-------|-----|
| Solid black rectangle | Threshold too low OR printer only supports bit‑image | Raise threshold (180–200) AND set `preferBitImage: true` |
| Very faint logo | Threshold too high | Lower threshold (130–150) |
| Nothing printed (text ok) | Printer rejects GS v 0 raster | Use `preferBitImage: true` |
| Cropped logo | Image wider than head width | Resize or pass `logoMaxWidth` (58mm: 384, 80mm: 512) |

Threshold heuristic: start 160 → if too dark raise by +10; if too light lower by −10. Most logos stabilize at 150–185.

Single‑payload benefit: `printLogoAndLines` reduces Bluetooth chunks so logos start faster and avoid partial rendering on slow modules.

## License

See the `LICENSE` file in this repo.
