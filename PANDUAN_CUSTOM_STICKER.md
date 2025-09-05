# Panduan Custom Sticker Setup - TSPL

## Overview
Sistem custom sticker ini memungkinkan Anda mengatur dengan mudah:
- Ukuran label (width x height)
- Margin (kiri, atas, kanan, bawah)
- Multiple text dengan posisi dan size berbeda
- Barcode positioning
- Orientasi dan density

## Quick Start

### 1. Method Utama: `_printCustomSticker()`

```dart
_printCustomSticker(
  role: PosPrinterRole.sticker,
  width: 40,          // lebar label dalam mm
  height: 30,         // tinggi label dalam mm
  gap: 3,             // gap antar label dalam mm
  marginLeft: 2,      // margin kiri dalam mm
  marginTop: 2,       // margin atas dalam mm
  texts: [
    StickerText('JUDUL', x: 0, y: 0, font: 3, size: 1),
    StickerText('Subtitle', x: 0, y: 8, font: 2, size: 1),
  ],
  barcode: StickerBarcode('1234567890', x: 0, y: 20, height: 8),
);
```

## Parameter Detail

### Label Size & Margins
```dart
width: 40,          // mm - HARUS sesuai media fisik Anda!
height: 30,         // mm - HARUS sesuai media fisik Anda!
gap: 3,             // mm - gap antar label (biasanya 2-4mm)
marginLeft: 2,      // mm - margin dari kiri label
marginTop: 2,       // mm - margin dari atas label
```

### Text Configuration - `StickerText()`
```dart
StickerText(
  'Text Anda',        // string yang akan dicetak
  x: 0,               // mm - posisi horizontal dari margin kiri
  y: 0,               // mm - posisi vertikal dari margin atas
  font: 3,            // 0-8 (0=kecil, 8=besar)
  size: 1,            // 1-10 (multiplier ukuran)
  rotation: 0,        // 0, 90, 180, 270 derajat
)
```

### Barcode Configuration - `StickerBarcode()`
```dart
StickerBarcode(
  '1234567890',       // data barcode
  x: 0,               // mm - posisi horizontal
  y: 20,              // mm - posisi vertikal
  height: 8,          // mm - tinggi barcode
  type: 'CODE128',    // jenis barcode
)
```

## Font Size Guide

| Font | Typical Size | Use Case |
|------|--------------|----------|
| 0    | Very Small   | Detail info |
| 1    | Small        | Sub text |
| 2    | Medium       | Normal text |
| 3    | Large        | Title |
| 4    | Very Large   | Main title |
| 5-8  | Huge         | Special cases |

## Size Multiplier Guide

| Size | Effect |
|------|---------|
| 1    | Normal (1x) |
| 2    | Double (2x) |
| 3    | Triple (3x) |
| 4+   | Very large |

## Calculating Positions (mm)

### Untuk label 40x30mm dengan margin 2mm:
- **Usable area**: 36x26mm (40-2-2 x 30-2-2)
- **Text positions**:
  - Line 1: y = 0
  - Line 2: y = 6-8mm (tergantung font)
  - Line 3: y = 12-16mm
  - Line 4: y = 18-24mm

### Font Height Estimates (approximate):
- Font 1: ~3mm height
- Font 2: ~4mm height  
- Font 3: ~6mm height
- Font 4: ~8mm height

## Contoh Setup Berbagai Kebutuhan

### 1. Label Produk Sederhana (40x30mm)
```dart
_printCustomSticker(
  role: role,
  width: 40, height: 30, gap: 3,
  marginLeft: 2, marginTop: 2,
  texts: [
    StickerText('PRODUK NAME', x: 0, y: 0, font: 3, size: 1),
    StickerText('Harga: Rp 25.000', x: 0, y: 8, font: 2, size: 1),
    StickerText('Exp: 12/2024', x: 0, y: 16, font: 1, size: 1),
  ],
  barcode: StickerBarcode('1234567890', x: 0, y: 20, height: 6),
);
```

### 2. Label Alamat (58x40mm) 
```dart
_printCustomSticker(
  role: role,
  width: 58, height: 40, gap: 2,
  marginLeft: 3, marginTop: 3,
  texts: [
    StickerText('John Doe', x: 0, y: 0, font: 3, size: 1),
    StickerText('Jl. Merdeka No. 123', x: 0, y: 8, font: 2, size: 1),
    StickerText('Jakarta Pusat 10110', x: 0, y: 16, font: 2, size: 1),
    StickerText('HP: 081234567890', x: 0, y: 24, font: 1, size: 1),
  ],
);
```

### 3. Label Mini (25x15mm)
```dart
_printCustomSticker(
  role: role,
  width: 25, height: 15, gap: 2,
  marginLeft: 1, marginTop: 1,
  texts: [
    StickerText('MINI', x: 0, y: 0, font: 2, size: 1),
    StickerText('001', x: 0, y: 6, font: 1, size: 1),
  ],
);
```

### 4. Multiple Columns
```dart
_printCustomSticker(
  role: role,
  width: 50, height: 30, gap: 3,
  marginLeft: 2, marginTop: 2,
  texts: [
    // Kolom kiri
    StickerText('Item:', x: 0, y: 0, font: 2),
    StickerText('ABC123', x: 0, y: 8, font: 2),
    
    // Kolom kanan
    StickerText('Qty:', x: 25, y: 0, font: 2),
    StickerText('10', x: 25, y: 8, font: 2),
  ],
);
```

## Troubleshooting

### ❌ Problem: Print 2 label (1 kosong)
**Solusi**: Pastikan `width` dan `height` sesuai media fisik

### ❌ Problem: Text terpotong kiri
**Solusi**: Perbesar `marginLeft` atau kurangi `x` position

### ❌ Problem: Text terpotong atas
**Solusi**: Perbesar `marginTop` atau kurangi `y` position

### ❌ Problem: Text terlalu besar
**Solusi**: Kurangi `font` number atau `size` multiplier

### ❌ Problem: Text overlapping
**Solusi**: Tambah jarak `y` antar text (minimum 6-8mm untuk font 2-3)

### ❌ Problem: Barcode tidak muat
**Solusi**: Kurangi `height` barcode atau posisikan lebih atas

## Advanced Settings

### Direction (Orientasi)
```dart
direction: 0,    // Normal
direction: 1,    // Terbalik - gunakan jika text upside down
```

### Print Quality
```dart
density: 8,      // 1-15 (makin tinggi makin gelap)
speed: 2,        // 1-6 (makin rendah makin bagus kualitas)
```

## Template untuk Copy-Paste

### Basic Template
```dart
void _printMySticker(PosPrinterRole role) {
  _printCustomSticker(
    role: role,
    width: 40,          // UBAH: sesuai media Anda
    height: 30,         // UBAH: sesuai media Anda
    gap: 3,             // UBAH: sesuai gap media
    marginLeft: 2,      // UBAH: sesuai kebutuhan
    marginTop: 2,       // UBAH: sesuai kebutuhan
    texts: [
      StickerText('TEXT 1', x: 0, y: 0, font: 3, size: 1),
      StickerText('TEXT 2', x: 0, y: 8, font: 2, size: 1),
      // Tambah text lain di sini
    ],
    barcode: StickerBarcode('1234567890', x: 0, y: 20, height: 8),
  );
}
```

Dengan panduan ini, Anda bisa dengan mudah menyesuaikan layout sticker sesuai kebutuhan!
