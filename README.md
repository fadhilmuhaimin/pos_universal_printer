# pos_universal_printer

Plugin Flutter untuk mencetak struk kasir dan label pada berbagai printer thermal. Mendukung perintah ESC/POS (struk), TSPL dan CPCL (label). Dirancang multi‑peran (kasir, dapur, stiker), dengan antrian pekerjaan, retry, serta koneksi Bluetooth Classic (Android) dan TCP/IP (Android & iOS).

## Fitur utama

- ESC/POS: teks, align, bold, barcode, QR, feed/cut, buka laci kasir (cash drawer).
- TSPL & CPCL: builder sederhana untuk label (TEXT/BARCODE/QRCODE/BITMAP/PRINT).
- Multi‑peran: mapping printer per role (cashier, kitchen, sticker).
- Koneksi: Bluetooth Classic (Android) dan TCP 9100 (Android & iOS).
- Reliability: job queue dengan retry dan TCP auto‑reconnect.

## Dukungan platform & perangkat

- Android: Bluetooth Classic (SPP/RFCOMM) dan TCP.
- iOS: hanya TCP (Bluetooth SPP non‑MFi tidak didukung di iOS).
- Merek umum seperti Blue Print yang kompatibel ESC/POS/TSPL/CPCL dapat bekerja.

## Prasyarat

- Flutter 3.19+ (Dart 3.2+).
- Android: targetSdk 31+ disarankan (Android 12) untuk izin Bluetooth baru.
- iOS: iOS 12.0+ (menggunakan Network.framework untuk TCP).

## Instalasi

Opsi A — dari Git (monorepo ini):

Tambahkan dependency dan overrides berikut ke `pubspec.yaml` aplikasi Anda:

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

Catatan: karena ini federated plugin di satu repo, `dependency_overrides` memastikan paket implementasi platform ikut terambil ketika menggunakan Git.

Kemudian jalankan:

```sh
flutter pub get
```

Opsi B — dari pub.dev:

- Jika paket telah dipublikasikan, cukup:

```yaml
dependencies:
  pos_universal_printer: ^X.Y.Z
```

## Setup platform

### Android

- Izin Bluetooth (Android 12+): plugin sudah mendeklarasikan izin di manifest implementasi. Namun Anda tetap perlu meminta izin runtime sebelum scan/connect.
- Pastikan printer sudah di‑pair dari Settings bila menggunakan Bluetooth Classic. Fungsi "scan" pada plugin ini menampilkan daftar perangkat yang sudah paired (bonded), bukan discovery penuh.
- TCP tidak memerlukan izin khusus selain INTERNET (sudah dideklarasikan oleh plugin).

Contoh meminta izin (opsional) dengan `permission_handler`:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> ensureBtPermissions() async {
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
  ].request();
}
```

Panggil `ensureBtPermissions()` sebelum `scanBluetooth()`/`registerDevice()` untuk Bluetooth.

### iOS

- Hanya TCP/IP (LAN/Wi‑Fi). Bluetooth SPP non‑MFi tidak didukung iOS.
- Set deployment target ke 12.0+ di `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

Biasanya tidak perlu ATS exception untuk raw TCP ke IP LAN.

## Cara pakai (contoh cepat)

### 1) Definisikan printer per peran (Bluetooth Android atau TCP)

```dart
import 'package:pos_universal_printer/pos_universal_printer.dart';

final pos = PosUniversalPrinter.instance;

// TCP (bekerja di Android & iOS)
await pos.registerDevice(
  PosPrinterRole.cashier,
  PrinterDevice(
    id: '192.168.1.50:9100',
    name: 'Kasir LAN',
    type: PrinterType.tcp,
    address: '192.168.1.50',
    port: 9100,
  ),
);

// Bluetooth (Android saja) — hasil dari scan
final btDevices = await pos.scanBluetooth().toList();
final selected = btDevices.first; // pilih sesuai UI Anda
await pos.registerDevice(PosPrinterRole.kitchen, selected);
```

### 2) Cetak struk ESC/POS (Builder)

```dart
import 'package:pos_universal_printer/src/protocols/escpos/builder.dart';

final b = EscPosBuilder();
b.text('TOKO CONTOH', bold: true, align: PosAlign.center);
b.text('Jl. Contoh 123');
b.feed(1);
b.text('Item A           1   Rp10.000');
b.text('Item B           2   Rp20.000');
b.feed(1);
b.text('TOTAL                 Rp30.000', bold: true);
b.feed(2);
b.cut();

pos.printEscPos(PosPrinterRole.cashier, b);
```

Atau pakai renderer cepat bawaan untuk daftar item (58mm/80mm):

```dart
import 'package:pos_universal_printer/src/renderer/receipt_renderer.dart';

final items = [
  ReceiptItem(name: 'Es Teh', qty: 1, price: 5000),
  ReceiptItem(name: 'Ayam Geprek Level 3', qty: 1, price: 25000),
];

pos.printReceipt(PosPrinterRole.cashier, items, is80mm: false);
```

### 3) Buka laci kasir (cash drawer)

```dart
pos.openDrawer(PosPrinterRole.cashier); // ESC p dengan pulsa default
```

Anda dapat menyesuaikan pulsa: `openDrawer(role, m: 0, t1: 25, t2: 250)`.

### 4) Cetak label TSPL (TSC/Argox)

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

Atau langsung kirim perintah string TSPL:

```dart
// Lebih sederhana dengan helper bawaan:
pos.printTspl(PosPrinterRole.sticker, TsplBuilder.sampleLabel58x40());
```

### 5) Cetak label CPCL (Zebra)

```dart
import 'package:pos_universal_printer/src/protocols/cpcl/builder.dart';

final cpcl = CpclBuilder();
cpcl.page(600, 600, 1);
cpcl.text(0, 50, 50, 'Sample CPCL');
cpcl.barcode('CODE128', 2, 2, 80, 50, 150, '123456789012');
cpcl.qrCode(2, 4, 50, 300, 'https://example.com');
cpcl.printLabel();

pos.printCpcl(PosPrinterRole.sticker, String.fromCharCodes(cpcl.build()));

// Atau gunakan sampel bawaan:
pos.printCpcl(PosPrinterRole.sticker, CpclBuilder.sampleLabel());
```

### 6) Kirim raw bytes

```dart
pos.printRaw(PosPrinterRole.kitchen, [0x1B, 0x40, 0x0A]); // ESC @, LF
```

### 7) Disconnect / cleanup

```dart
await pos.unregisterDevice(PosPrinterRole.kitchen);
await pos.dispose();
```

## Contoh aplikasi

Lihat folder `example/` untuk UI demo yang:
- Memilih tipe koneksi per peran (Bluetooth/TCP)
- Scan Bluetooth (Android)
- Uji ESC/POS, TSPL, CPCL, Open Drawer, dan stress test

## Praktik terbaik

- Gunakan TCP/IP bila memungkinkan (stabil, lintas Android & iOS).
- Untuk Bluetooth Android: pastikan perangkat sudah paired dan izinkan `bluetoothScan`/`bluetoothConnect` saat runtime.
- Cash drawer harus terhubung ke port RJ‑11 printer struk dan printer mendukung perintah ESC/POS `ESC p`.
- Pilih protokol yang sesuai: ESC/POS untuk struk, TSPL/CPCL untuk label. Banyak printer label tidak menerima ESC/POS untuk label.

### Catatan lebar kertas dan kolom (Blueprint 80/57 mm)

- Lebar kertas 80 mm dengan lebar cetak efektif ~72 mm umumnya ≈ 48 kolom teks.
- Mode 64 mm (beberapa model Blueprint) ≈ ~42 kolom.
- Lebar kertas 57/58 mm ≈ 32 kolom.

Anda dapat mengatur kolom secara manual di `ReceiptRenderer.render()`:

```dart
// 72 mm (≈48 kolom)
pos.printReceipt(role, items, columns: 48);

// 64 mm (≈42 kolom)
pos.printReceipt(role, items, columns: 42);

// 57/58 mm (≈32 kolom)
pos.printReceipt(role, items, columns: 32);
```

## Troubleshooting

- Tidak bisa scan Bluetooth (Android 12+): minta izin runtime sebelum scan. Beberapa device membutuhkan lokasi aktif.
- iOS tidak bisa Bluetooth: ini batasan platform. Gunakan TCP.
- Tidak tercetak via TCP: pastikan IP/port (umumnya 9100) benar dan printer dalam mode yang sesuai (ESC/POS vs TSPL/CPCL).
- Hasil potong tidak jalan: tidak semua printer mendukung perintah cut penuh; coba manual tear atau model khusus.

## Lisensi

Lihat file `LICENSE` di repo ini.
