# pos_universal_printer

**The modern alternative to blue_thermal_printer** - A powerful Flutter plugin for printing POS receipts and labels on thermal printers. Drop-in replacement for blue_thermal_printer with enhanced features, better reliability, and cross-platform support.

**Perfect migration path from blue_thermal_printer** with compatibility API included. Supports ESC/POS (receipts), TSPL and CPCL (labels). Desi---
## 🔄 Blue Thermal Printer Migration Guide

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

### Instant Migration (3 Steps)

**Step 1:** Update pubspec.yaml
```yaml
dependencies:
  # blue_thermal_printer: ^0.3.1  # Remove this
  pos_universal_printer: ^0.2.7   # Add this
```

**Step 2:** Change import only
```dart
// OLD
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';

// NEW (100% compatible API)
import 'package:pos_universal_printer/blue_thermal_compat.dart';
```

**Step 3:** Your existing code works unchanged!
```dart
// All your existing blue_thermal_printer code works exactly the same
BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
await bluetooth.connect(device);
await bluetooth.writeBytes(bytes);
```

### Advanced Features After Migration

Once migrated, you can gradually adopt new features:

```dart
// Keep using blue_thermal_printer API for existing code
await bluetooth.writeBytes(receiptBytes);

// Add new sticker printing capabilities  
await CustomStickerPrinter.printInvoice(
  printer: PosUniversalPrinter.instance,
  role: PosPrinterRole.sticker,
  customer: 'John Doe',
  menu: 'Special Coffee',
  details: 'Extra Hot, No Sugar',
);

// Add logo printing
await BlueThermalCompatPrinter.printLogoAndLines([
  'Your Business Name',
  '123 Main Street',
  'Thank you!',
], role: PosPrinterRole.cashier);
```

---
## 🏪 Restaurant/Kitchen Setup Guideed for multi‑role routing (cashier, kitchen, sticker) with job queue, retries, Bluetooth Classic (Android), and TCP/IP (Android & iOS).

## Features

- **🔄 Blue Thermal Printer Replacement**: Complete drop-in replacement for `blue_thermal_printer` package
- **📱 Better than blue_thermal_printer**: Enhanced reliability, cross-platform support, and modern API design
- ESC/POS: text, alignment, bold, barcode, QR, feed/cut, cash drawer (ESC p).
- TSPL & CPCL: builders for labels (TEXT/BARCODE/QRCODE/BITMAP/PRINT).
- **🆕 Custom Sticker API**: Easy-to-use helper for TSPL sticker printing with advanced text processing
  - **Semantic Font Weights** (v0.2.7): Normal, semiBold, bold with software fallback for enhanced visibility
  - **Smart Text Wrapping** (v0.2.7): Character-based wrapping with configurable line limits and separators
  - **Details Budget System** (v0.2.7): Automatic truncation for variants/additions/notes to prevent overflow
  - **Precision Layout Control** (v0.2.7): Fine-tune margins, alignment, and text positioning for consistent output
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
  pos_universal_printer: ^0.2.7
```

For Git usage in a monorepo, see the repository README for dependency_overrides instructions.

## Quick start

### 🔄 Migrating from blue_thermal_printer? 
**Zero-code migration** - just change the import and you're done!

```dart
// OLD: blue_thermal_printer 
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';

// NEW: pos_universal_printer (blue_thermal_printer compatible API)
import 'package:pos_universal_printer/blue_thermal_compat.dart';

// Your existing blue_thermal_printer code works unchanged!
BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
```

### 🆕 New Project Setup

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

Version 0.2.0 introduces a powerful and easy-to-use custom sticker API for TSPL printers with advanced customization options in 0.2.7:

### 🎯 Setup for Your Package

#### Basic Setup
```dart
// 1. Add to pubspec.yaml
dependencies:
  pos_universal_printer: ^0.2.7

// 2. Import in your Dart files
import 'package:pos_universal_printer/pos_universal_printer.dart';

// 3. Initialize printer instance (typically in main.dart or service)
final PosUniversalPrinter printer = PosUniversalPrinter.instance;

// 4. Register your printer devices by role
await printer.registerDevice(
  PosPrinterRole.sticker,  // or .cashier, .kitchen
  PrinterDevice(
    id: 'sticker_printer_1',
    name: 'Beverage Station',
    type: PrinterType.bluetooth,  // or .tcp
    address: 'AA:BB:CC:DD:EE:FF', // BT MAC or IP
    port: 9100, // for TCP only
  ),
);
```

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
## � Restaurant/Kitchen Setup Guide

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
## 🛠 Troubleshooting

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
| **Text wrapped in wrong places** | Word-based wrapping with spaces | Use character-based wrapping (built-in for v0.2.7) |
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
## Keywords & SEO

**blue_thermal_printer alternative**, **blue_thermal_printer replacement**, **flutter thermal printer**, **pos printer flutter**, **bluetooth printer flutter**, **thermal printer package**, **receipt printer flutter**, **sticker printer flutter**, **blue thermal migration**, **pos_universal_printer**, **thermal printer crossplatform**

---
## Versioning Policy
- Patch (0.2.x) = additive / docs / fixes
- Minor bump to 0.3.0 reserved for breaking API changes

---
## Support & Community

- 🐛 **Issues**: [GitHub Issues](https://github.com/fadhilmuhaimin/pos_universal_printer/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/fadhilmuhaimin/pos_universal_printer/discussions) 
- 📦 **Package**: [pub.dev](https://pub.dev/packages/pos_universal_printer)
- 🔄 **Migration Help**: Tag your issues with `blue_thermal_printer migration` for priority support

**Migrating from blue_thermal_printer?** We're here to help! Open an issue with your migration questions.
- 1.0.0 once core protocols + compat considered stable in production

## License

This package requires a LICENSE file. See the repository root for licensing or add a license file in this package before publishing.
