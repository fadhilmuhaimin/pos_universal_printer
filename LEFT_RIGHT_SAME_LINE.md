# 🔥 KIRI & KANAN DALAM 1 LINE - Tutorial Lengkap

## 🎯 **Konsep Dasar**

**"Kiri dan kanan dalam 1 line"** adalah layout di mana dalam 1 baris yang sama, Anda memiliki text di posisi kiri dan text di posisi kanan. Ini sangat umum untuk:

- **Produk:** Kode SKU (kiri) + Harga (kanan)
- **Invoice:** Item name (kiri) + Price (kanan)  
- **Receipt:** Description (kiri) + Amount (kanan)
- **Label:** Date (kiri) + Batch number (kanan)

## 💡 **Cara Kerja**

Kuncinya adalah menggunakan **Y coordinate yang sama** tetapi **alignment yang berbeda**:

```dart
texts: [
  // SAME Y = 0 (line yang sama)
  StickerText('KIRI', x: 0, y: 0, alignment: 'left'),   // di kiri
  StickerText('KANAN', x: 0, y: 0, alignment: 'right'), // di kanan
],
```

## 🧪 **Contoh Praktis**

### 1. **Product Label dengan Kode + Harga**

```dart
CustomStickerPrinter.printSticker(
  printer: printer,
  role: PosPrinterRole.sticker,
  width: 40, height: 30, gap: 3,
  marginLeft: 2, marginTop: 1, marginRight: 2, marginBottom: 2,
  texts: [
    // Line 1: SKU (kiri) + Harga (kanan)
    StickerText('SKU: ABC123', x: 0, y: 0, font: 2, alignment: 'left'),
    StickerText('Rp 25.000', x: 0, y: 0, font: 2, alignment: 'right'),
    
    // Line 2: Nama produk (tengah)
    StickerText('KOPI ARABICA', x: 0, y: 8, font: 3, alignment: 'center'),
    
    // Line 3: Tanggal (kiri) + Batch (kanan)  
    StickerText('01/09/25', x: 0, y: 16, font: 1, alignment: 'left'),
    StickerText('Batch: B001', x: 0, y: 16, font: 1, alignment: 'right'),
  ],
);
```

**Output:**
```
SKU: ABC123              Rp 25.000
        KOPI ARABICA
01/09/25            Batch: B001
```

### 2. **Invoice/Receipt Style**

```dart
CustomStickerPrinter.printSticker(
  printer: printer,
  role: PosPrinterRole.sticker,
  width: 50, height: 30, gap: 3,  // lebih lebar untuk invoice
  marginLeft: 2, marginTop: 1, marginRight: 2, marginBottom: 2,
  texts: [
    // Header
    StickerText('INVOICE #12345', x: 0, y: 0, font: 3, alignment: 'center'),
    
    // Item lines: Name (kiri) + Price (kanan)
    StickerText('Kopi Arabica x2', x: 0, y: 8, font: 2, alignment: 'left'),
    StickerText('50.000', x: 0, y: 8, font: 2, alignment: 'right'),
    
    StickerText('Gula Merah x1', x: 0, y: 14, font: 2, alignment: 'left'),
    StickerText('15.000', x: 0, y: 14, font: 2, alignment: 'right'),
    
    // Total line (bold)
    StickerText('TOTAL', x: 0, y: 20, font: 3, alignment: 'left'),
    StickerText('Rp 65.000', x: 0, y: 20, font: 3, alignment: 'right'),
  ],
);
```

**Output:**
```
          INVOICE #12345
Kopi Arabica x2         50.000
Gula Merah x1           15.000
TOTAL              Rp 65.000
```

### 3. **Multi-Info Label**

```dart
CustomStickerPrinter.printSticker(
  printer: printer,
  role: PosPrinterRole.sticker,
  width: 40, height: 30, gap: 3,
  marginLeft: 2, marginTop: 1, marginRight: 2, marginBottom: 2,
  texts: [
    // Header
    StickerText('PRODUCT INFO', x: 0, y: 0, font: 3, alignment: 'center'),
    
    // Multi-line info
    StickerText('Code:', x: 0, y: 8, font: 2, alignment: 'left'),
    StickerText('P001', x: 0, y: 8, font: 2, alignment: 'right'),
    
    StickerText('Weight:', x: 0, y: 14, font: 2, alignment: 'left'),
    StickerText('250gr', x: 0, y: 14, font: 2, alignment: 'right'),
    
    StickerText('Exp:', x: 0, y: 20, font: 2, alignment: 'left'),
    StickerText('Dec 2025', x: 0, y: 20, font: 2, alignment: 'right'),
  ],
);
```

**Output:**
```
        PRODUCT INFO
Code:                P001
Weight:             250gr
Exp:            Dec 2025
```

## 🎨 **Advanced Layout Combinations**

### Kiri-Tengah-Kanan dalam 1 Line

```dart
texts: [
  // Y=0: 3 text dalam 1 line!
  StickerText('Left', x: 0, y: 0, font: 2, alignment: 'left'),
  StickerText('Center', x: 0, y: 0, font: 2, alignment: 'center'), 
  StickerText('Right', x: 0, y: 0, font: 2, alignment: 'right'),
],
```

### Mixed Alignment Layout

```dart
texts: [
  // Line 1: Header center
  StickerText('MY STORE', x: 0, y: 0, font: 3, alignment: 'center'),
  
  // Line 2: Date (kiri) + Time (kanan)
  StickerText('05/09/2025', x: 0, y: 8, font: 1, alignment: 'left'),
  StickerText('14:30', x: 0, y: 8, font: 1, alignment: 'right'),
  
  // Line 3: Item details kiri-kanan
  StickerText('Item: Coffee', x: 0, y: 14, font: 2, alignment: 'left'),
  StickerText('Qty: 2', x: 0, y: 14, font: 2, alignment: 'right'),
  
  // Line 4: Footer center
  StickerText('Thank You!', x: 0, y: 20, font: 2, alignment: 'center'),
],
```

## 🎛️ **Parameter Fine-Tuning**

### Offset dari Tepi

```dart
// Jika text kanan terlalu mepet ke tepi:
StickerText('Kanan', x: 2, y: 0, alignment: 'right')  // 2mm dari tepi kanan

// Jika text kiri terlalu mepet ke tepi:
StickerText('Kiri', x: 1, y: 0, alignment: 'left')   // 1mm dari tepi kiri
```

### Font Size Berbeda dalam Same Line

```dart
texts: [
  // Kiri besar, kanan kecil
  StickerText('PRODUK', x: 0, y: 0, font: 3, alignment: 'left'),
  StickerText('v1.2', x: 0, y: 0, font: 1, alignment: 'right'),
],
```

### Spacing Y untuk Multiple Lines

```dart
// Spacing 6-8mm untuk font normal
StickerText('Line 1 L', x: 0, y: 0, alignment: 'left'),
StickerText('Line 1 R', x: 0, y: 0, alignment: 'right'),

StickerText('Line 2 L', x: 0, y: 7, alignment: 'left'),   // y+7
StickerText('Line 2 R', x: 0, y: 7, alignment: 'right'),

StickerText('Line 3 L', x: 0, y: 14, alignment: 'left'),  // y+7
StickerText('Line 3 R', x: 0, y: 14, alignment: 'right'),
```

## 🧪 **Test di Example App**

Sekarang ada button baru untuk testing:

1. **"Kiri & Kanan"** - Demo basic left-right same line
2. **"Invoice Style"** - Demo invoice/receipt layout

```bash
cd example
flutter run
# Tekan button "Kiri & Kanan" untuk test!
```

## 🔧 **Tips & Tricks**

### 1. **Hindari Text Overlap**
```dart
// ❌ WRONG: Text terlalu panjang bisa overlap
StickerText('Very Long Product Name Here', x: 0, y: 0, alignment: 'left'),
StickerText('Rp 999.999.999', x: 0, y: 0, alignment: 'right'),

// ✅ CORRECT: Sesuaikan panjang text atau font size
StickerText('Long Product', x: 0, y: 0, font: 2, alignment: 'left'),
StickerText('Rp 999K', x: 0, y: 0, font: 2, alignment: 'right'),
```

### 2. **Gunakan Margin yang Cukup**
```dart
// Beri margin left/right yang cukup agar text tidak mepet tepi
marginLeft: 2,   // minimal 2mm
marginRight: 2,  // minimal 2mm
```

### 3. **Sesuaikan dengan Lebar Sticker**
```dart
// Untuk sticker sempit (30-40mm): font kecil, text pendek
width: 40,
texts: [
  StickerText('ABC', x: 0, y: 0, font: 2, alignment: 'left'),
  StickerText('25K', x: 0, y: 0, font: 2, alignment: 'right'),
],

// Untuk sticker lebar (50-60mm): bisa font besar, text panjang  
width: 58,
texts: [
  StickerText('Product Name', x: 0, y: 0, font: 3, alignment: 'left'),
  StickerText('Rp 25.000', x: 0, y: 0, font: 3, alignment: 'right'),
],
```

## ✅ **Summary**

**Kiri & Kanan dalam 1 Line** sekarang super mudah dengan:

- ✅ **Same Y coordinate** untuk text yang ingin dalam 1 line
- ✅ **Different alignment** (`'left'` dan `'right'`)  
- ✅ **Margin control** untuk spacing dari tepi
- ✅ **Font mixing** untuk emphasis berbeda
- ✅ **Perfect untuk invoice, receipt, product label**

**🚀 Perfect solution untuk layout professional dan rapi!** 🏷️✨
