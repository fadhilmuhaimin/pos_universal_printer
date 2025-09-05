# 🏷️ Custom Sticker Printing API - Documentation

## Quick Start

Sekarang Anda bisa menggunakan **helper level package** untuk print sticker custom dengan mudah!

### Import Package

```dart
import 'package:pos_universal_printer/pos_universal_printer.dart';
```

## 🎯 1. Template Siap Pakai (Recommended)

### Product Sticker 40x30mm

```dart
// Template untuk sticker produk siap pakai
CustomStickerPrinter.printProductSticker40x30(
  printer: PosUniversalPrinter.instance,
  role: PosPrinterRole.sticker,
  productName: 'KOPI ARABICA',
  productCode: 'KA001', 
  price: 'Rp 35.000',
  barcodeData: '1234567890',  // opsional
);
```

### Address Sticker 58x40mm

```dart
// Template untuk sticker alamat siap pakai
CustomStickerPrinter.printAddressSticker58x40(
  printer: PosUniversalPrinter.instance,
  role: PosPrinterRole.sticker,
  receiverName: 'John Doe',
  address: 'Jl. Merdeka No. 123, Jakarta Pusat',
  phone: '081234567890',
  orderCode: 'ORD-2024-001',
);
```

## 🛠️ 2. Custom Layout (Full Control)

```dart
// Untuk kebutuhan custom layout
CustomStickerPrinter.printSticker(
  printer: PosUniversalPrinter.instance,
  role: PosPrinterRole.sticker,
  
  // 📐 UKURAN (wajib sesuai media fisik!)
  width: 40,          // mm
  height: 30,         // mm
  gap: 3,             // mm - jarak antar sticker
  
  // 📏 MARGIN (4 sisi - NEW!)
  marginLeft: 8,      // mm - dari kiri
  marginTop: 2,       // mm - dari atas
  marginRight: 2,     // mm - dari kanan (NEW!)
  marginBottom: 2,    // mm - dari bawah (NEW!)
  
  // 📝 TEXT ELEMENTS dengan ALIGNMENT (NEW!)
  texts: [
    StickerText('JUDUL BESAR', x: 0, y: 0, font: 3, alignment: 'center'),  // tengah
    StickerText('Kiri', x: 0, y: 8, font: 2, alignment: 'left'),          // kiri
    StickerText('Kanan', x: 0, y: 16, font: 2, alignment: 'right'),       // kanan (NEW!)
  ],
  
  // 📊 BARCODE (opsional)
  barcode: StickerBarcode('1234567890', x: 0, y: 20, height: 8),
  
  // ⚙️ FINE TUNING (opsional)
  direction: 0,       // 0=normal, 1=terbalik
  density: 8,         // 1-15 (gelap)
  speed: 2,           // 1-6 (kualitas)
);
```

## 📋 Parameter Reference

### StickerText

| Parameter | Type | Default | Keterangan |
|-----------|------|---------|------------|
| `text` | String | - | **Wajib.** Text yang akan di-print |
| `x` | double | - | **Wajib.** Posisi horizontal (mm dari marginLeft) |
| `y` | double | - | **Wajib.** Posisi vertikal (mm dari marginTop) |
| `font` | int | 3 | Font size: 1=kecil, 2=sedang, 3=besar, 4=extra |
| `size` | int | 1 | Scaling: 1=normal, 2=2x, 3=3x |
| `alignment` | String | 'left' | **NEW!** Perataan: 'left'/'center'/'right' |

### StickerBarcode

| Parameter | Type | Default | Keterangan |
|-----------|------|---------|------------|
| `data` | String | - | **Wajib.** Data barcode |
| `x` | double | - | **Wajib.** Posisi horizontal (mm dari marginLeft) |
| `y` | double | - | **Wajib.** Posisi vertikal (mm dari marginTop) |
| `height` | double | 8 | Tinggi barcode (mm) |
| `type` | String | '128' | Jenis barcode (128, CODE39, EAN13, dll) |

### printSticker Main Parameters

| Parameter | Type | Default | Keterangan |
|-----------|------|---------|------------|
| `width` | double | - | **Wajib.** Lebar sticker (mm) - harus sesuai media! |
| `height` | double | - | **Wajib.** Tinggi sticker (mm) - harus sesuai media! |
| `gap` | double | 3 | Jarak antar sticker (mm), biasanya 2-4mm |
| `marginLeft` | double | 2 | Margin kiri mulai print (mm) |
| `marginTop` | double | 2 | Margin atas mulai print (mm) |
| `marginRight` | double | 2 | **NEW!** Margin kanan (mm) |
| `marginBottom` | double | 2 | **NEW!** Margin bawah (mm) |
| `direction` | int | 0 | 0=normal, 1=180° jika terbalik |
| `density` | int | 8 | Ketebalan print 1-15 (makin tinggi makin gelap) |
| `speed` | int | 2 | Kecepatan 1-6 (makin rendah makin bagus kualitas) |

## 🚀 Tips Praktis

### 1. Setup Printer Dulu

```dart
final printer = PosUniversalPrinter.instance;

// Untuk bluetooth
final device = PrinterDevice(
  id: 'XX:XX:XX:XX:XX:XX',
  name: 'TSC Printer', 
  type: PrinterType.bluetooth,
  address: 'XX:XX:XX:XX:XX:XX',
);
await printer.registerDevice(PosPrinterRole.sticker, device);

// Untuk TCP/WiFi  
final device = PrinterDevice(
  id: '192.168.1.100:9100',
  name: 'Network Printer',
  type: PrinterType.tcp,
  address: '192.168.1.100',
  port: 9100,
);
await printer.registerDevice(PosPrinterRole.sticker, device);
```

### 2. Ukuran Media yang Umum

| Ukuran | width | height | Penggunaan |
|--------|-------|--------|------------|
| 40x30mm | 40 | 30 | Label produk, price tag |
| 50x30mm | 50 | 30 | Label produk besar |
| 58x40mm | 58 | 40 | Alamat, shipping label |
| 100x50mm | 100 | 50 | Multi-line label |

### 3. Font Size Guide

- **Font 1**: Text kecil untuk detail/info tambahan
- **Font 2**: Text normal untuk content utama  
- **Font 3**: Text besar untuk judul/header
- **Font 4**: Text extra besar untuk highlight

### 4. Positioning Tips

```dart
// Contoh layout 40x30mm dengan alignment baru:
texts: [
  StickerText('HEADER', x: 0, y: 0, font: 3, alignment: 'center'),    // Tengah
  StickerText('Kiri', x: 0, y: 8, font: 2, alignment: 'left'),       // Kiri
  StickerText('Kanan', x: 0, y: 8, font: 2, alignment: 'right'),     // Kanan (same line!)
  StickerText('Footer', x: 0, y: 16, font: 1, alignment: 'center'),   // Tengah
],
barcode: StickerBarcode('123', x: 0, y: 22, height: 6), // 22mm dari atas
```

### 5. Alignment Examples (NEW!)

```dart
// Left aligned (default)
StickerText('Kiri', x: 0, y: 0, alignment: 'left')

// Center aligned  
StickerText('Tengah', x: 0, y: 0, alignment: 'center')

// Right aligned
StickerText('Kanan', x: 0, y: 0, alignment: 'right')

// Right aligned + 5mm offset dari kanan
StickerText('Kanan+5', x: 5, y: 0, alignment: 'right')
```

## 🔧 Troubleshooting

### Problem: Text Terbalik/Upside Down
```dart
// Solusi: Ubah direction
direction: 1,  // coba 1 jika direction 0 terbalik
```

### Problem: Sticker Double/Kosong
```dart
// Pastikan ukuran sesuai media fisik
width: 40,     // HARUS sama dengan label fisik! 
height: 30,    // HARUS sama dengan label fisik!
gap: 3,        // Sesuaikan dengan gap fisik antar label
```

### Problem: Text Terpotong
```dart
// Terpotong kiri: perbesar marginLeft
marginLeft: 5,   // dari 2 ke 5

// Terpotong kanan: perkecil x atau gunakan font lebih kecil
StickerText('text', x: 0, y: 0, font: 2), // dari font 3 ke 2

// Terpotong atas: perbesar marginTop  
marginTop: 3,    // dari 2 ke 3

// Terpotong bawah: perkecil y atau gunakan font lebih kecil
StickerText('text', x: 0, y: 15, font: 1), // pindah y ke atas
```

### Problem: Print Pucat
```dart
// Naikkan density
density: 12,     // dari 8 ke 12 (max 15)
```

### Problem: Kualitas Buruk
```dart
// Turunkan speed
speed: 1,        // dari 2 ke 1 (min 1)
```

## 📦 Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:pos_universal_printer/pos_universal_printer.dart';

class MyStickerPrinter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Template siap pakai - paling mudah!
        CustomStickerPrinter.printProductSticker40x30(
          printer: PosUniversalPrinter.instance,
          role: PosPrinterRole.sticker,
          productName: 'KOPI ARABICA',
          productCode: 'KA001',
          price: 'Rp 35.000',
          barcodeData: '1234567890',
        );
      },
      child: Text('Print Product Sticker'),
    );
  }
}
```

---

**🎉 Selesai!** Sekarang Anda punya API lengkap untuk print sticker custom yang bisa dipanggil dari mana saja di aplikasi Anda.

Cukup import `pos_universal_printer` dan langsung pakai `CustomStickerPrinter.printProductSticker40x30()` atau `CustomStickerPrinter.printSticker()` untuk kebutuhan custom layout!
