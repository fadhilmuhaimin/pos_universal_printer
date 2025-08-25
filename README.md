# pos_universal_printer

Plugin Flutter federated untuk mencetak struk dan label melalui berbagai jenis printer kasir.

## Fitur

- Pencetakan ESC/POS: teks, align, bold, barcode, QR, raster, potong kertas, dan buka laci.
- Pencetakan label TSPL (TSC/Argox) dan CPCL (Zebra).
- Koneksi Bluetooth Classic (Android) dan TCP/IP (Android & iOS).
- Antrian kerja per peran (kasir, dapur, stiker) dengan retry otomatis.
- Logging terstruktur dengan ring buffer dan streaming ke UI.

## Instalasi

Tambahkan dependensi berikut di `pubspec.yaml` proyek Anda:

```yaml
dependencies:
  pos_universal_printer:
    git:
      url: https://github.com/<username>/pos_universal_printer.git
      path: packages/pos_universal_printer
