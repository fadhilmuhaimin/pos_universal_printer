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
  pos_universal_printer: ^0.2.1
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

### Basic Sticker with Text Alignment

```dart
import 'package:pos_universal_printer/pos_universal_printer.dart';

// Create sticker content with aligned text - SESUAI MAIN.DART
await CustomStickerPrinter.printSticker(
  printer: printer,
  role: PosPrinterRole.sticker,
  width: 40,           // mm - sesuaikan dengan media Anda
  height: 30,          // mm - sesuaikan dengan media Anda  
  gap: 3,              // mm - gap antar label
  marginLeft: 8,       // mm - margin kiri
  marginTop: 2,        // mm - margin atas
  texts: [
    StickerText(
      'Product Name',
      x: 0, y: 0, 
      font: 3, size: 1,
      alignment: 'center' // 'left', 'center', 'right'
    ),
    StickerText(
      '\$19.99',
      x: 0, y: 15,
      font: 4, size: 1,
      alignment: 'right'
    ),
  ],
);
```

### Invoice Style Sticker

Perfect for restaurant order stickers - **PERSIS SEPERTI MAIN.DART**:

```dart
// 🧾 INVOICE STYLE - Print per menu dengan format yang diminta
void _testInvoiceStyle(PosPrinterRole role) {
  // Contoh data pesanan dengan 2 menu - SEPERTI MAIN.DART
  final order = Order(
    dateTime: DateTime.now(),
    customerName: 'John Does', // 🆕 Nama customer
    items: [
      OrderItem(
        name: 'Kopi Gula Aren',
        modifications: ['Less Sugar', 'Extra Topping Oreo'], // 🆕 Pisahkan dari note
        note: 'Saus Terpisah', // 🆕 Note terpisah lagi
      ),
      OrderItem(
        name: 'Es Teh Manis',
        modifications: ['Extra Manis', 'Tambah Es', 'Gelas Besar'], // 🆕 Pisahkan dari note
        note: 'Minum langsung', // 🆕 Note terpisah lagi
      ),
    ],
  );

  // Print sticker untuk setiap menu (1 menu = 1 sticker) - SEPERTI MAIN.DART
  for (int i = 0; i < order.items.length; i++) {
    final item = order.items[i];
    _printSingleMenuStickerOnly(role, order.dateTime, item, order.customerName);
  }
}

// 🧾 Helper untuk print 1 menu sticker dengan format yang diminta - PERSIS MAIN.DART
void _printSingleMenuStickerOnly(PosPrinterRole role, DateTime dateTime, OrderItem item, String customerName) {
  List<StickerText> texts = [];
  double currentY = 0;
  
  // 0. Nama customer (rata kiri, font 1 ukuran 1) - 🆕 PALING ATAS
  texts.add(StickerText(customerName, x: 12, y: currentY, font: 1, size: 1, alignment: 'left'));
  currentY += 4; // Spacing kecil
  
  // 1. Tanggal dan jam (rata kiri, font 1 ukuran 1)
  final dateStr = '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year} : ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  texts.add(StickerText(dateStr, x: 12, y: currentY, font: 1, size: 1, alignment: 'left'));
  currentY += 4; // Spacing lebih kecil
  
  // 2. Nama menu (rata kiri, font 8 ukuran 1 - BESAR!)
  texts.add(StickerText(item.name, x: 12, y: currentY, font: 8, size: 1, alignment: 'left'));
  currentY += 4; // Spacing kecil antara nama dan modification
  
  // 3. Gabung modifications dan note, font LEBIH KECIL (TSPL font 2 = terkecil yang reliable)
  List<String> allModsAndNotes = [];
  if (item.modifications.isNotEmpty) {
    allModsAndNotes.addAll(item.modifications);
  }
  if (item.note != null && item.note!.isNotEmpty) {
    allModsAndNotes.add(item.note!); // 🆕 Tambah note ke list
  }
  
  if (allModsAndNotes.isNotEmpty) {
    final allText = allModsAndNotes.join(', '); // Gabung semua dengan koma
    final wrappedMods = _wrapText(allText, 30); // max 30 char per line untuk font kecil

    for (String line in wrappedMods) {
      texts.add(StickerText(line, x: 12, y: currentY, font: 2, size: 1, alignment: 'left'));
      currentY += 3; // 🆕 Spacing lebih kecil untuk font kecil
    }
  }

  // Hitung tinggi dinamis berdasarkan content yang ada - PENTING!
  final calculatedHeight = (currentY + 6).clamp(15.0, 30.0); // min 15mm, max 30mm
  
  CustomStickerPrinter.printSticker(
    printer: printer,
    role: role,
    width: 40,  // lebar 40mm sesuai request
    height: calculatedHeight, // tinggi dinamis, bukan fixed 30mm
    gap: 3,
    marginLeft: 1,
    marginTop: 1,
    marginRight: 1,
    marginBottom: 1,
    texts: texts,
  );
}

// Helper untuk wrap text otomatis - DARI MAIN.DART
List<String> _wrapText(String text, int maxLength) {
  if (text.length <= maxLength) return [text];
  
  List<String> lines = [];
  String currentLine = '';
  List<String> words = text.split(' ');
  
  for (String word in words) {
    if ((currentLine + word).length <= maxLength) {
      currentLine += (currentLine.isEmpty ? '' : ' ') + word;
    } else {
      if (currentLine.isNotEmpty) {
        lines.add(currentLine);
        currentLine = word;
      } else {
        // Word terlalu panjang, potong paksa
        lines.add(word.substring(0, maxLength));
        currentLine = word.substring(maxLength);
      }
    }
  }
  
  if (currentLine.isNotEmpty) {
    lines.add(currentLine);
  }
  
  return lines;
}

// Helper untuk nama bulan - DARI MAIN.DART
String _getMonthName(int month) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month];
}
```

**🎯 FITUR INVOICE STYLE INI:**
- ✅ **2 Menu = 2 Sticker**: Setiap menu dicetak terpisah
- ✅ **Customer name paling atas**: Font 1 (kecil)
- ✅ **Timestamp**: Format DD MMM YYYY : HH:MM
- ✅ **Menu name**: Font 8 (besar banget!)
- ✅ **Modifications + Note**: Digabung dengan koma, font 2, wrap otomatis
- ✅ **Tinggi dinamis**: Otomatis menyesuaikan content
- ✅ **Spacing presisi**: 4mm antara elemen utama, 3mm untuk detail

### Built-in Templates

Quick templates for common use cases - **LANGSUNG PAKAI**:

```dart
// 40x30mm product sticker - SIAP PAKAI
await CustomStickerPrinter.printProductSticker40x30(
  printer: printer,
  role: PosPrinterRole.sticker,
  productName: 'Coffee Beans',
  productCode: 'KB001',
  price: 'Rp 25.000',
  barcodeData: '1234567890',
);

// 58x40mm address label - SIAP PAKAI  
await CustomStickerPrinter.printAddressSticker58x40(
  printer: printer,
  role: PosPrinterRole.sticker,
  receiverName: 'John Doe',
  address: 'Jl. Merdeka No. 123, Jakarta',
  phone: '081234567890',
  orderCode: 'ORD-2024-001',
);
```

### Template Kustom Mudah - **COPY & MODIFY**

```dart
// Template dasar yang bisa dimodifikasi sesuka hati
await CustomStickerPrinter.printSticker(
  printer: printer,
  role: PosPrinterRole.sticker,
  width: 40,          // mm - ubah sesuai media
  height: 30,         // mm - ubah sesuai media
  gap: 3,             // mm - gap antar label
  marginLeft: 8,      // mm - margin kiri (bisa diubah)
  marginTop: 2,       // mm - margin atas (bisa diubah)
  texts: [
    // Baris 1: Judul (bisa ganti font/size/posisi)
    StickerText('CUSTOM STICKER', x: 0, y: 0, font: 3, size: 1),
    
    // Baris 2: Detail (bisa ganti semua parameter)
    StickerText('Teks Anda', x: 0, y: 8, font: 2, size: 1),
    
    // Baris 3: Info tambahan (bisa dihapus/ditambah)
    StickerText('Info detail', x: 0, y: 16, font: 1, size: 1),
  ],
  
  // Barcode opsional (bisa dihapus jika tidak perlu)
  barcode: StickerBarcode('1234567890', x: 0, y: 20, height: 8),
);
```

### Advanced Features - **SEMUA BISA DICUSTOM**

#### Four-Side Margins - **ATUR SESUKA HATI**
```dart
await CustomStickerPrinter.printSticker(
  printer: printer,
  role: PosPrinterRole.sticker,
  width: 40,
  height: 30,
  gap: 3,
  marginLeft: 5,      // 5mm left margin - BISA DIUBAH
  marginTop: 2,       // 2mm top margin - BISA DIUBAH  
  marginRight: 5,     // 5mm right margin - BISA DIUBAH
  marginBottom: 2,    // 2mm bottom margin - BISA DIUBAH
  texts: [
    StickerText(
      'Centered with margins',
      x: 0, y: 10,
      font: 3, size: 1,
      alignment: 'center',
    ),
  ],
);
```

#### Left-Right Same Line - **KIRI KANAN BEDA TEXT**
```dart
await CustomStickerPrinter.printSticker(
  printer: printer,
  role: PosPrinterRole.sticker,
  width: 40,
  height: 30,
  gap: 3,
  marginLeft: 2,
  marginTop: 1,
  marginRight: 2,
  texts: [
    // SAME Y = SAME LINE! - BISA DICUSTOM POSISI
    StickerText('SKU: ABC123', x: 0, y: 0, font: 2, alignment: 'left'),
    StickerText('Rp 25K', x: 0, y: 0, font: 2, alignment: 'right'), // Same Y!
    
    // Line 2 - BISA TAMBAH SEBANYAK YANG DIINGINKAN
    StickerText('Made in', x: 0, y: 8, font: 1, alignment: 'left'),
    StickerText('Indonesia', x: 0, y: 8, font: 1, alignment: 'right'), // Same Y!
  ],
);
```

#### Barcodes and QR Codes - **MUDAH DITAMBAHKAN**
```dart
await CustomStickerPrinter.printSticker(
  printer: printer,
  role: PosPrinterRole.sticker,
  width: 40,
  height: 30,
  gap: 3,
  texts: [
    StickerText('Product Name', x: 0, y: 0, font: 3, size: 1),
  ],
  // Barcode mudah ditambah - POSISI & SIZE BISA DIUBAH
  barcode: StickerBarcode(
    '1234567890',
    x: 0, y: 20,        // Posisi bisa diubah
    height: 8,          // Tinggi bisa diubah
    type: 'CODE128',    // Type bisa diganti (CODE128, EAN13, dll)
  ),
);
```

### Parameter Reference - **PANDUAN LENGKAP CUSTOMIZATION**

#### CustomStickerPrinter.printSticker() Parameters
- **printer**: PosUniversalPrinter.instance (wajib)
- **role**: PosPrinterRole.sticker (atau cashier/kitchen)
- **width**: Lebar sticker dalam mm (40, 58, 80, dll - sesuai media fisik)
- **height**: Tinggi sticker dalam mm (30, 40, 50, dll - sesuai media fisik)
- **gap**: Jarak antar sticker dalam mm (2-4mm biasanya)
- **marginLeft/Top/Right/Bottom**: Margin dalam mm (bisa 0 jika tidak perlu)
- **texts**: List StickerText (bisa sebanyak yang diinginkan)
- **barcode**: StickerBarcode opsional (bisa null jika tidak perlu)

#### StickerText Parameters - **SEMUA BISA DICUSTOM**
- **text**: Isi text (wajib)
- **x, y**: Posisi dalam mm (0,0 = kiri atas setelah margin)
- **font**: Ukuran font 1-8 (1 = terkecil, 8 = terbesar)
- **size**: Multiplier ukuran (1 = normal, 2 = 2x besar, dll)
- **alignment**: 'left', 'center', 'right' (otomatis hitung posisi)

#### Font Size Guide - **PILIH SESUAI KEBUTUHAN**
- **Font 1**: Terkecil (untuk catatan/detail)
- **Font 2-3**: Kecil (untuk info tambahan)
- **Font 4-5**: Sedang (untuk nama produk)
- **Font 6-8**: Besar (untuk judul/harga)

**💡 Tips**: `size: 2` = 2x lebih besar dari normal. Jadi font 1 + size 2 = font 2 normal.

#### StickerBarcode Parameters
- **data**: Isi barcode (wajib)
- **x, y**: Posisi dalam mm
- **height**: Tinggi barcode dalam mm (5-20mm biasanya)
- **type**: 'CODE128', 'EAN13', 'CODE39', dll

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
