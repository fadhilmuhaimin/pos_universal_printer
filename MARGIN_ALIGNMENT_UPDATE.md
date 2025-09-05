# 🆕 UPDATE: Margin & Alignment Features

## 📋 **Fitur Baru yang Ditambahkan**

### 1. **Margin 4 Sisi (NEW!)**

Sekarang Anda bisa mengatur margin dari **semua sisi** sticker:

```dart
CustomStickerPrinter.printSticker(
  // ... parameter lain
  marginLeft: 2,      // margin kiri (mm)
  marginTop: 1,       // margin atas (mm)  
  marginRight: 2,     // margin kanan (mm) - BARU!
  marginBottom: 2,    // margin bawah (mm) - BARU!
  // ...
);
```

### 2. **Text Alignment (NEW!)**

Sekarang bisa print text dari **kiri, tengah, atau kanan**:

```dart
texts: [
  // Text align kiri (default)
  StickerText('KIRI', x: 0, y: 0, alignment: 'left'),
  
  // Text align tengah  
  StickerText('TENGAH', x: 0, y: 7, alignment: 'center'),
  
  // Text align kanan
  StickerText('KANAN', x: 0, y: 14, alignment: 'right'),
  
  // Text align kanan + offset 5mm dari tepi kanan
  StickerText('KANAN+5mm', x: 5, y: 21, alignment: 'right'),
],
```

## 🔍 **Jawaban Pertanyaan Anda**

### 1. **Kenapa margin hanya top dan left?**

**Sebelumnya** memang hanya ada `marginLeft` dan `marginTop` karena:
- Di TSPL, command `REFERENCE` hanya set koordinat awal (starting point)
- Right/bottom margin dikontrol manual lewat parameter `x` dan `y`

**Sekarang** sudah ditambahkan `marginRight` dan `marginBottom` untuk kemudahan:
- Helper otomatis menghitung area printable
- Alignment otomatis menggunakan margin ini untuk positioning

### 2. **Bagaimana print dari kanan (right-aligned)?**

**Ada 3 cara:**

#### Cara 1: Manual positioning (cara lama)
```dart
// Hitung sendiri posisi dari kanan
StickerText('Kanan', x: 30, y: 0, font: 2)  // 30mm dari kiri = kanan untuk sticker 40mm
```

#### Cara 2: Alignment 'right' (BARU - recommended!)
```dart
// Otomatis positioned dari kanan
StickerText('Kanan', x: 0, y: 0, font: 2, alignment: 'right')
```

#### Cara 3: Right alignment + offset (BARU!)
```dart
// 5mm dari tepi kanan
StickerText('Kanan+5mm', x: 5, y: 0, font: 2, alignment: 'right')
```

## 💡 **Cara Kerja Alignment**

### Left Alignment (default)
```dart
StickerText('Text', x: 5, y: 0, alignment: 'left')
// Posisi: 5mm dari margin kiri
```

### Center Alignment  
```dart
StickerText('Text', x: 2, y: 0, alignment: 'center')
// Posisi: tengah sticker + offset 2mm ke kanan
```

### Right Alignment
```dart
StickerText('Text', x: 3, y: 0, alignment: 'right')  
// Posisi: 3mm dari margin kanan (menjauh dari tepi kanan)
```

## 🧪 **Contoh Praktis**

### Layout dengan semua alignment:
```dart
CustomStickerPrinter.printSticker(
  printer: printer,
  role: PosPrinterRole.sticker,
  width: 40, height: 30, gap: 3,
  marginLeft: 2, marginTop: 1, 
  marginRight: 2, marginBottom: 2,  // margin 4 sisi
  texts: [
    // Header di tengah
    StickerText('PRODUK SAYA', x: 0, y: 0, font: 3, alignment: 'center'),
    
    // Kode di kiri, harga di kanan (same line!)
    StickerText('SKU: ABC123', x: 0, y: 8, font: 2, alignment: 'left'),
    StickerText('Rp 25.000', x: 0, y: 8, font: 2, alignment: 'right'),
    
    // Footer di tengah
    StickerText('Made in Indonesia', x: 0, y: 16, font: 1, alignment: 'center'),
  ],
);
```

### Layout dengan margin besar:
```dart
CustomStickerPrinter.printSticker(
  // ... parameter lain
  marginLeft: 5,      // 5mm dari kiri
  marginTop: 3,       // 3mm dari atas
  marginRight: 5,     // 5mm dari kanan  
  marginBottom: 3,    // 3mm dari bawah
  texts: [
    StickerText('DALAM FRAME', x: 0, y: 0, font: 2),
    // Text akan print dalam area (40-5-5) x (30-3-3) = 30x24mm
  ],
);
```

## 🎯 **Test di Example App**

Sekarang ada button baru di example app:

1. **"Left|Center|Right"** - Demo semua alignment
2. **"Full Margins"** - Demo margin 4 sisi

```bash
cd example
flutter run
# Tekan button untuk test alignment!
```

## 🔧 **Breaking Changes**

**Tidak ada breaking changes!** 
- Parameter lama tetap bekerja
- `marginRight` dan `marginBottom` bersifat opsional (default: 2)
- `alignment` bersifat opsional (default: 'left')

## ✅ **Summary**

Sekarang API custom sticker printing sudah mendukung:

- ✅ **4-side margins**: `marginLeft`, `marginTop`, `marginRight`, `marginBottom`
- ✅ **Text alignment**: `'left'`, `'center'`, `'right'`  
- ✅ **Right positioning**: Mudah print dari kanan dengan `alignment: 'right'`
- ✅ **Center positioning**: Perfect centering dengan `alignment: 'center'`
- ✅ **Offset support**: Bisa adjust posisi dengan parameter `x` pada setiap alignment
- ✅ **Backward compatible**: Code lama tetap jalan

**🎉 Problem solved! Sekarang bisa print dari kiri, tengah, atau kanan dengan mudah!**
