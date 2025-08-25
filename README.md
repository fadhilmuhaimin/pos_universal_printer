# pos_universal_printer

Plugin Flutter federated untuk mencetak struk kasir dan label menggunakan berbagai jenis printer thermal. Mendukung perintah ESC/POS untuk printer kasir, serta TSPL dan CPCL untuk printer label. Plugin ini memisahkan logika inti (Dart) dan implementasi platform (Android/iOS) sehingga mudah dipelihara dan dikembangkan.

## Fitur Utama

- **ESC/POS**: mencetak teks, mengatur alignment, menebalkan huruf, barcode, QR code, raster image, memotong kertas, dan membuka laci kasir.
- **TSPL & CPCL**: membangun label untuk printer TSC/Argox (TSPL) dan Zebra (CPCL).
- **Multi-peran**: dukungan untuk beberapa printer (kasir, dapur, stiker) dengan antrian peran terpisah dan retry otomatis.
- **Koneksi**: Bluetooth Classic (hanya Android) dan TCP/IP (Android & iOS).
- **Logging**: ring buffer log dan streaming perubahan log ke UI.

## Instalasi

1. Pastikan Anda sudah menginisialisasi dependensi Flutter di proyek Anda.
2. Tambahkan plugin ini dari GitHub di `pubspec.yaml` aplikasi Anda:

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     pos_universal_printer:
       git:
         url: https://github.com/fadhilmuhaimin/pos_universal_printer.git
         path: packages/pos_universal_printer
