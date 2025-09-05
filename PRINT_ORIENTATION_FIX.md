# Solusi Masalah Text Terbalik pada Print Sticker TSPL

## Masalah
Text pada sticker muncul terbalik (upside down/inverted) saat menggunakan TSPL printer.

## Penyebab
Masalah ini disebabkan oleh pengaturan `DIRECTION` dalam TSPL command:
- `DIRECTION 0` = orientasi normal
- `DIRECTION 1` = orientasi terbalik (reversed)

Banyak contoh di dokumentasi menggunakan `DIRECTION 1` yang bisa menyebabkan text terbalik pada beberapa model printer.

## Solusi

### 1. Menggunakan TsplBuilder dengan pengaturan manual

```dart
import 'package:pos_universal_printer/src/protocols/tspl/builder.dart';

void printStickerNormal(PosPrinterRole role) {
  final tspl = TsplBuilder();
  
  // Pengaturan dasar
  tspl.size(58, 40);           // ukuran label dalam mm
  tspl.gap(2, 0);              // jarak antar label
  
  // KUNCI: Gunakan direction 0 untuk orientasi normal
  tspl._buffer.writeln('DIRECTION 0');  // orientasi normal
  tspl._buffer.writeln('REFERENCE 0,0'); // titik referensi
  tspl._buffer.writeln('CLS');           // bersihkan buffer
  
  tspl.density(8);             // kepadatan print
  
  // Tambahkan text dan barcode
  tspl.text(20, 20, 3, 0, 1, 1, 'Label Normal');
  tspl.barcode(20, 60, 'CODE128', 60, 1, '1234567890');
  
  tspl.printLabel(1);
  
  // Print ke printer
  printer.printTspl(role, String.fromCharCodes(tspl.build()));
}
```

### 2. Menggunakan StringBuffer langsung (Recommended)

```dart
void printStickerFixed(PosPrinterRole role) {
  final sb = StringBuffer();
  
  // Pengaturan media
  sb.writeln('SIZE 58 mm, 40 mm');
  sb.writeln('GAP 2 mm, 0 mm');
  
  // PENTING: Gunakan DIRECTION 0 untuk text normal
  sb.writeln('DIRECTION 0');      // 0 = normal, 1 = terbalik
  sb.writeln('REFERENCE 0,0');    // titik referensi
  sb.writeln('DENSITY 8');        // kepadatan
  sb.writeln('CLS');              // bersihkan buffer
  
  // Text dan barcode
  sb.writeln('TEXT 20,20,"3",0,1,1,"STICKER NORMAL"');
  sb.writeln('BARCODE 20,60,"CODE128",60,1,0,1,"1234567890"');
  
  // Print
  sb.writeln('PRINT 1');
  
  // Kirim ke printer
  printer.printTspl(role, sb.toString());
}
```

### 3. Fungsi helper untuk test orientasi

```dart
void testOrientation(PosPrinterRole role, int direction) {
  final sb = StringBuffer();
  
  sb.writeln('SIZE 58 mm, 40 mm');
  sb.writeln('GAP 2 mm, 0 mm');
  sb.writeln('DIRECTION $direction');  // Test dengan 0 atau 1
  sb.writeln('REFERENCE 0,0');
  sb.writeln('DENSITY 8');
  sb.writeln('CLS');
  
  sb.writeln('TEXT 20,20,"3",0,1,1,"DIRECTION $direction"');
  sb.writeln('TEXT 20,50,"2",0,1,1,"Test orientation"');
  
  sb.writeln('PRINT 1');
  
  printer.printTspl(role, sb.toString());
}

// Test kedua orientasi
void testBothOrientations(PosPrinterRole role) {
  // Test direction 0 (normal)
  testOrientation(role, 0);
  
  // Tunggu sebentar lalu test direction 1 (terbalik)
  Future.delayed(Duration(seconds: 2), () {
    testOrientation(role, 1);
  });
}
```

### 4. Solusi untuk label 40x30 mm

```dart
void printLabel40x30Fixed(PosPrinterRole role) {
  final sb = StringBuffer();
  
  // Label 40x30 mm dengan orientasi normal
  sb.writeln('SIZE 40 mm, 30 mm');
  sb.writeln('GAP 3 mm, 0 mm');        // sesuaikan dengan media
  sb.writeln('DIRECTION 0');           // NORMAL orientation
  sb.writeln('REFERENCE 0,0');
  sb.writeln('DENSITY 8');
  sb.writeln('CLS');
  
  // Text yang mudah dibaca
  sb.writeln('TEXT 10,10,"3",0,1,1,"40x30 NORMAL"');
  sb.writeln('TEXT 10,40,"2",0,1,1,"Text tidak terbalik"');
  
  sb.writeln('PRINT 1');
  
  printer.printTspl(role, sb.toString());
}
```

## Tips Troubleshooting

1. **Jika text masih terbalik dengan DIRECTION 0**: Coba DIRECTION 1
2. **Jika posisi text salah**: Sesuaikan koordinat x,y dalam TEXT command
3. **Jika label tidak terpotong dengan benar**: Kalibrasi GAP di printer atau sesuaikan nilai GAP
4. **Jika ada label kosong**: Pastikan menggunakan CLS sebelum drawing

## Implementasi di Example App

Tambahkan method ini di `example/lib/main.dart`:

```dart
void _testStickerFixed(PosPrinterRole role) {
  final sb = StringBuffer();
  
  sb.writeln('SIZE 58 mm, 40 mm');
  sb.writeln('GAP 2 mm, 0 mm');
  sb.writeln('DIRECTION 0');      // FIX: orientasi normal
  sb.writeln('REFERENCE 0,0');
  sb.writeln('DENSITY 8');
  sb.writeln('CLS');
  
  sb.writeln('TEXT 20,20,"3",0,1,1,"STICKER FIXED"');
  sb.writeln('TEXT 20,50,"2",0,1,1,"Text normal"');
  sb.writeln('BARCODE 20,80,"CODE128",60,1,0,1,"1234567890"');
  
  sb.writeln('PRINT 1');
  
  printer.printTspl(role, sb.toString());
}
```

Dan tambahkan button di UI:

```dart
ElevatedButton(
  onPressed: () => _testStickerFixed(role),
  child: const Text('Test Fixed Sticker'),
),
```

## Catatan Penting

- Selalu gunakan `CLS` sebelum menggambar untuk membersihkan buffer
- Test dengan `DIRECTION 0` terlebih dahulu, baru coba `DIRECTION 1` jika masih terbalik
- Sesuaikan `GAP` dengan ukuran sebenarnya gap di media label Anda
- Kalibrasi printer jika label tidak terpotong dengan benar
