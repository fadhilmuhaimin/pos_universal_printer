# pos_universal_printer

The modern alternative to blue_thermal_printer. A Flutter plugin for POS thermal printing with better reliability, cross‑platform support, and a straightforward migration path.
## Blue Thermal Printer Migration Guide

### Why Switch from blue_thermal_printer?

**pos_universal_printer** is a modern, actively maintained replacement for the deprecated `blue_thermal_printer` package with significant improvements:

| blue_thermal_printer (old) | pos_universal_printer (new) |
|----------------------------|------------------------------|
| ❌ Android only | ✅ Android + iOS (TCP) |
| ❌ Bluetooth only | ✅ Bluetooth + LAN/TCP |
| ❌ Limited error handling | ✅ Robust retry & fallback |
| ❌ No sticker support | ✅ Advanced sticker API |
| ❌ Basic text only | ✅ Rich formatting + images |
| ❌ Maintenance issues | ✅ Actively maintained |

### Quick migration from blue_thermal_printer (3 steps)
1) Add the `pos_universal_printer` dependency (remove `blue_thermal_printer`).
2) Change the import to `package:pos_universal_printer/blue_thermal_compat.dart`.
3) Your existing code continues to work; then gradually adopt new features.

For a complete reference (Bluetooth/TCP, auto‑reconnect, state restore, stickers), see the example app:

https://github.com/fadhilmuhaimin/pos_universal_printer/blob/main/example/lib/main.dart

If this package helps you, please star the repository.

---
## Restaurant/Kitchen Setup Guide
Multi‑role routing (cashier, kitchen, sticker) with job queue, retries, Bluetooth Classic (Android), and TCP/IP (Android & iOS).

## Features

- **🔄 Blue Thermal Printer Replacement**: Complete drop-in replacement for `blue_thermal_printer` package
- **📱 Better than blue_thermal_printer**: Enhanced reliability, cross-platform support, and modern API design
- ESC/POS: text, alignment, bold, barcode, QR, feed/cut, cash drawer (ESC p).
- TSPL & CPCL: builders for labels (TEXT/BARCODE/QRCODE/BITMAP/PRINT).
- **🆕 Custom Sticker API**: Easy-to-use helper for TSPL sticker printing with advanced text processing
  - Semantic Font Weights (since 0.2.7): Normal, semiBold, bold with software fallback for enhanced visibility
  - Smart Text Wrapping (since 0.2.7): Character-based wrapping with configurable line limits and separators
  - Details Budget System (since 0.2.7): Automatic truncation for variants/additions/notes to prevent overflow
  - Precision Layout Control (since 0.2.7): Fine-tune margins, alignment, and text positioning for consistent output
- Multi‑role mapping (cashier, kitchen, sticker).
- Connectivity: Bluetooth Classic (Android) and TCP 9100 (Android & iOS).
- Reliability: job queue with retry, TCP auto‑reconnect; BT write reconnect fallback.
- **🔄 Migration Support**: Blue Thermal Compat API for seamless migration from `blue_thermal_printer`
- **🖼️ Logo/Image Printing**: Asset-based logo printing at receipt headers with automatic conversion

## Platform support

**Major advantage over blue_thermal_printer** - true cross-platform support:

- **Android**: Bluetooth Classic (SPP/RFCOMM) and TCP/IP ✅
- **iOS**: TCP/IP support (blue_thermal_printer doesn't support iOS) ✅ 
- **Cross-platform**: Same API works on both platforms ✅

*Note: iOS non-MFi Bluetooth SPP is not supported by iOS itself, but LAN/TCP works perfectly for iOS POS systems.*

## Installation

Add the package from pub.dev:

```yaml
dependencies:
  pos_universal_printer: ^0.2.9
```

If you are working from source or a monorepo, consider these options:

1) Pub.dev (recommended once all platform impls are published)

```yaml
dependencies:
  pos_universal_printer: ^0.2.9
```

2) Git with overrides (keeps all federated packages from the same repo/ref):

```yaml
dependencies:
  pos_universal_printer:
    git:
      url: https://github.com/fadhilmuhaimin/pos_universal_printer.git
      path: packages/pos_universal_printer
      ref: main  # or a tag/commit

dependency_overrides:
  pos_universal_printer_android:
    git:
      url: https://github.com/fadhilmuhaimin/pos_universal_printer.git
      path: packages/pos_universal_printer_android
      ref: main
  pos_universal_printer_ios:
    git:
      url: https://github.com/fadhilmuhaimin/pos_universal_printer.git
      path: packages/pos_universal_printer_ios
      ref: main
```

3) Local path (monorepo development):

```yaml
dependencies:
  pos_universal_printer:
    path: ../pos_universal_printer/packages/pos_universal_printer
  pos_universal_printer_android:
    path: ../pos_universal_printer/packages/pos_universal_printer_android
  pos_universal_printer_ios:
    path: ../pos_universal_printer/packages/pos_universal_printer_ios
```

Troubleshooting:
- Ensure Flutter >= 3.19.0 and Dart >= 3.2.0
- After switching install methods, run: `flutter clean` then `flutter pub get`
- Do not place dependencies under the `flutter:` section; only `assets`, `fonts`, etc. belong there.

## Quick start

See the example app for a full implementation: device selection, connect/disconnect, auto‑scan, auto‑reconnect, connection events, ESC/POS receipts, and TSPL stickers.

Source: https://github.com/fadhilmuhaimin/pos_universal_printer/blob/main/example/lib/main.dart

## Custom Sticker API

The custom sticker API has been available since 0.2.0, with key improvements in 0.2.7 and connection fixes in 0.2.8.

For full guidance (sizes, character limits, margins), refer to the example app and inline comments. The focus is smooth migration from blue_thermal_printer while providing a clean TSPL label API.

#### Advanced Restaurant/Cafe Setup
```dart
// For beverage/kitchen sticker printing with custom layout
import 'package:pos_universal_printer/pos_universal_printer.dart';

class RestaurantPrinterService {
  final PosUniversalPrinter printer = PosUniversalPrinter.instance;
  
  // Setup multiple printer roles
  Future<void> setupPrinters() async {
    // Cashier receipt printer (TCP)
    await printer.registerDevice(PosPrinterRole.cashier, PrinterDevice(
      id: 'cashier_tcp', name: 'Cashier LAN', type: PrinterType.tcp,
      address: '192.168.1.50', port: 9100,
    ));
    
    // Kitchen sticker printer (Bluetooth)  
    await printer.registerDevice(PosPrinterRole.kitchen, PrinterDevice(
      id: 'kitchen_bt', name: 'Kitchen BT', type: PrinterType.bluetooth,
      address: 'AA:BB:CC:DD:EE:FF',
    ));
    
    // Beverage station sticker printer (Bluetooth)
    await printer.registerDevice(PosPrinterRole.sticker, PrinterDevice(
      id: 'beverage_bt', name: 'Beverage BT', type: PrinterType.bluetooth, 
      address: 'FF:EE:DD:CC:BB:AA',
    ));
  }
  
  // Advanced beverage sticker with custom formatting
  Future<void> printBeverageSticker({
    required String customerName,
    required String productName,
    required List<String> variants,
    required List<String> additions,
    required String notes,
  }) async {
    final stickerPrinter = BeverageStickerPrinter(
      customerName: customerName,
      detailsCharBudget: 75,        // Total chars for variants+additions+notes
      detailsWrapWidthChars: 24,    // Characters per line (adjust for your label width)
      detailsMaxLines: 3,           // Max lines for details to prevent overflow
      detailsJoinSeparator: ', ',   // Separator between items
      autoGrowHeight: true,         // Auto-adjust label height
      debugLog: true,               // Enable debug output
    );
    
    // Create transaction line data
    final line = TransactionLineDemo(
      product: ProductModelDemo(id: 1, name: productName, price: 0, totalPrice: 0),
      quantity: 1,
      selectedVariants: variants.map((v) => SelectedVariantDemo(id: 1, name: v, price: 0)).toList(),
      selectedAdditions: additions.map((a) => SelectedAdditionDemo(id: 1, name: a, price: 0)).toList(),
      notes: notes,
    );
    
    await stickerPrinter.printBeverageLines([line], role: PosPrinterRole.sticker);
  }
}
```

For connect/disconnect with loading, scanning, and connection status events, refer to the example file to stay aligned with the latest version.

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

Orientation note: use `DIRECTION 0` to avoid upside‑down text.

If a single label causes two labels to feed:
- Calibrate media from the printer (GAP/BLACK MARK detect).
- Adjust GAP value to your stock (try 2–4 mm).
- Ensure `CLS`, `DIRECTION`, and `REFERENCE` are set before elements.

---
## Blue Thermal Printer Migration (Compat API)
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
    CompatLine.text('123 Sample St'),
    CompatLine.leftRight('Subtotal', '100.000'),
    CompatLine.leftRight('Discount', '-5.000'),
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
## Restaurant/Kitchen Setup Guide

### Reliable Kitchen Printer Connectivity
For kitchens located far from the cashier (tablet Android), **LAN/TCP is the most reliable option**:

```dart
// Kitchen printer setup via LAN (recommended for distant locations)
await printer.registerDevice(
  PosPrinterRole.kitchen,
  PrinterDevice(
    id: 'kitchen_lan',
    name: 'Kitchen Printer',
    type: PrinterType.tcp,       // Use LAN instead of Bluetooth
    address: '192.168.1.100',    // Kitchen printer IP
    port: 9100,                  // Standard port
  ),
);

// Cashier receipt printer (close range - Bluetooth OK)
await printer.registerDevice(
  PosPrinterRole.cashier, 
  PrinterDevice(
    id: 'cashier_bt',
    name: 'Cashier Receipt',
    type: PrinterType.bluetooth,
    address: 'AA:BB:CC:DD:EE:FF',
  ),
);
```

**Why LAN/TCP for Kitchen:**
- **Distance**: Works across entire building regardless of Bluetooth range (10m limit)
- **Reliability**: Network infrastructure more stable than Bluetooth
- **Speed**: Faster data transmission for complex stickers
- **No Interference**: Avoids Bluetooth conflicts with other devices

**Setup Requirements:**
1. Kitchen printer with Ethernet port (or WiFi-to-Ethernet adapter)
2. Network router/switch reaching kitchen location  
3. Static IP for kitchen printer (or DHCP reservation)
4. Tablet connected to same network (WiFi)

### Multi-Station Printing Example
```dart
class RestaurantPrintService {
  final printer = PosUniversalPrinter.instance;
  
  Future<void> processOrder(OrderData order) async {
    // Print cashier receipt (Bluetooth - close range)
    await BlueThermalCompatPrinter.printReceipt(
      order.receiptLines,
      role: PosPrinterRole.cashier,
    );
    
    // Print kitchen stickers for food items (LAN - distant kitchen)
    for (final item in order.foodItems) {
      await CustomStickerPrinter.printInvoice(
        printer: printer,
        role: PosPrinterRole.kitchen,
        customer: order.customerName,
        menu: item.name,
        details: item.specialInstructions,
      );
    }
    
    // Print beverage stickers (Bluetooth - beverage station nearby)
    final beveragePrinter = BeverageStickerPrinter(customerName: order.customerName);
    await beveragePrinter.printBeverageLines(
      order.beverageItems,
      role: PosPrinterRole.sticker,
    );
  }
}
```

### Font Weight & Text Emphasis
```dart
// Use semantic font weights for better readability
await CustomStickerPrinter.printStickerSimple(
  texts: [
    StickerText(
      'Product Name',
      weight: StickerWeight.semiBold,  // Normal, semiBold, bold
      fontSize: 2,
      alignment: StickerAlignment.left,
    ),
  ],
);
```

### Details Text Processing
```dart
final beveragePrinter = BeverageStickerPrinter(
  customerName: 'John Doe',
  detailsCharBudget: 75,           // Total chars for variants+additions+notes
  detailsWrapWidthChars: 24,       // Chars per line (adjust for label width)
  detailsMaxLines: 3,              // Max lines to prevent overflow
  detailsJoinSeparator: ', ',      // Separator between items
  autoGrowHeight: true,            // Auto-adjust label height
  debugLog: true,                  // Enable debug output
);
```

### Layout Fine-Tuning
```dart
await CustomStickerPrinter.printInvoiceSticker(
  // Fine-tune top margin without breaking alignment
  marginTop: 2,      // Label margin (affects all labels)
  currentY: -2,      // Layout offset (consistent across labels)
  
  // Control right margin spacing
  wrapWidthChars: 26, // Reduce by 1-2 for tighter right margin
);
```

---
## Troubleshooting

### Common blue_thermal_printer Migration Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| **"BluetoothDevice not found after migration"** | Different device scanning API | Use `bluetooth.getBondedDevices()` (same as blue_thermal_printer) or new `scanBluetooth()` stream |
| **"Print quality worse than blue_thermal_printer"** | Default chunk size | Adjust `chunkSize` parameter in compat API |
| **"Connection more stable than blue_thermal_printer"** | Better error handling | Expected improvement - enjoy the reliability! |
| **"Want to use new features beyond blue_thermal_printer"** | Exploring advanced API | See sticker printing and logo examples above |

### General Printer Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| **Font weight not visible** | Printer ignores SETBOLD command | Enable software fallback: `weight: StickerWeight.bold` (overstrike enabled automatically) |
| **Details text overflows sticker** | Character budget too high | Reduce `detailsCharBudget` or increase `detailsMaxLines` |
| **Text wrapped in wrong places** | Word-based wrapping with spaces | Use character-based wrapping (available since 0.2.7) |
| **Right margin too tight** | Wrap width too wide | Reduce `detailsWrapWidthChars` by 1-2 characters |
| **Top margin inconsistent between labels** | Using y-position adjustments | Use `currentY` offset instead of modifying `y` parameters |
| Second label starts mid‑way | Printer not fully resetting buffer timing | Add small delay (already built‑in), keep `ensureNewLabel=false` unless required |
| Two labels feed for one print | GAP mismatch or extra FORMFEED | Use correct `GAP`, avoid manual FORMFEED, ensure only one `CLS` |
| Left margin shrinks each sticker | State not reset | We send single `CLS`; avoid custom sequences that add REFERENCE cumulatively |
| Logo = black rectangle | Threshold too aggressive / printer rejects raster | Use `preferBitImage: true` or supply a lighter logo, adjust threshold |
| Bluetooth scan freezes UI | Long synchronous loop | Use provided async scan (stream aggregated) |
| Barcode unreadable | Height or density too low | Increase barcode height / density |
| QR empty | Data too long for size | Shorten data or increase module size (not yet exposed) |

---
## Logging & Debug
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
## Keywords & SEO

**blue_thermal_printer alternative**, **blue_thermal_printer replacement**, **flutter thermal printer**, **pos printer flutter**, **bluetooth printer flutter**, **thermal printer package**, **receipt printer flutter**, **sticker printer flutter**, **blue thermal migration**, **pos_universal_printer**, **thermal printer crossplatform**

---
## Versioning Policy
- Patch (0.2.x) = additive / docs / fixes
- Minor bump to 0.3.0 reserved for breaking API changes

---
## Support & Community

- Issues: [GitHub Issues](https://github.com/fadhilmuhaimin/pos_universal_printer/issues)
- Discussions: [GitHub Discussions](https://github.com/fadhilmuhaimin/pos_universal_printer/discussions)
- Package: [pub.dev](https://pub.dev/packages/pos_universal_printer)
- Migration Help: Tag your issues with `blue_thermal_printer migration` for priority support

**Migrating from blue_thermal_printer?** We're here to help! Open an issue with your migration questions.
- 1.0.0 once core protocols + compat considered stable in production

## License

This package requires a LICENSE file. See the repository root for licensing or add a license file in this package before publishing.
