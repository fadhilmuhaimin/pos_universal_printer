import '../../pos_universal_printer.dart';

/// Class untuk mendefinisikan text pada sticker label
/// 
/// Digunakan bersama dengan [CustomStickerPrinter.printSticker] untuk membuat
/// layout text yang fleksibel pada sticker.
class StickerText {
  /// Text yang akan dicetak
  final String text;
  
  /// Posisi X dalam milimeter (dari kiri, setelah margin)
  /// - 0 = mulai dari margin kiri
  /// - Nilai positif = bergeser ke kanan
  /// - Nilai negatif = bergeser ke kiri (dari reference point)
  final double x;
  
  /// Posisi Y dalam milimeter (dari atas, setelah margin)
  /// - 0 = mulai dari margin atas
  /// - Nilai positif = bergeser ke bawah
  /// - Jarak minimal antar baris: 5-8mm untuk text normal
  final double y;
  
  /// Ukuran font (0-8)
  /// - 0, 1 = sangat kecil
  /// - 2, 3 = normal/sedang  
  /// - 4, 5 = besar
  /// - 6, 7, 8 = sangat besar
  final int font;
  
  /// Multiplier ukuran text (1-10)
  /// - 1 = ukuran normal
  /// - 2 = 2x lebih besar
  /// - 3 = 3x lebih besar, dst
  final int size;
  
  /// Rotasi text dalam derajat
  /// - 0 = horizontal normal
  /// - 90 = vertikal (diputar 90° searah jarum jam)
  /// - 180 = terbalik horizontal
  /// - 270 = vertikal terbalik
  final int rotation;

  /// Alignment text (opsional, untuk kemudahan positioning)
  /// - 'left' = align kiri (default)
  /// - 'center' = align tengah  
  /// - 'right' = align kanan
  /// 
  /// Ketika menggunakan alignment, [x] akan diinterpretasikan sesuai alignment:
  /// - left: x = jarak dari kiri
  /// - center: x = offset dari tengah sticker  
  /// - right: x = jarak dari kanan (nilai positif = menjauh dari kanan)
  final String? alignment;
  
  /// Membuat objek StickerText untuk text pada sticker
  /// 
  /// [text] adalah string yang akan dicetak
  /// [x] dan [y] adalah posisi dalam mm relatif terhadap margin
  /// [font] adalah ukuran font (0-8, default: 2)
  /// [size] adalah multiplier ukuran (1-10, default: 1) 
  /// [rotation] adalah rotasi dalam derajat (0/90/180/270, default: 0)
  /// [alignment] adalah perataan text ('left'/'center'/'right', default: 'left')
  /// 
  /// Contoh:
  /// ```dart
  /// // Text kiri (default)
  /// StickerText('Kiri', x: 0, y: 0, font: 2)
  /// 
  /// // Text tengah
  /// StickerText('Tengah', x: 0, y: 0, font: 2, alignment: 'center')
  /// 
  /// // Text kanan
  /// StickerText('Kanan', x: 0, y: 0, font: 2, alignment: 'right')
  /// 
  /// // Text kanan dengan offset 5mm dari tepi kanan
  /// StickerText('Kanan+5mm', x: 5, y: 0, font: 2, alignment: 'right')
  /// ```
  /// ```dart
  /// StickerText('Judul Besar', x: 0, y: 0, font: 4, size: 2)
  /// StickerText('Text normal', x: 0, y: 10, font: 2, size: 1)
  /// StickerText('Text kecil', x: 5, y: 20, font: 1, size: 1)
  /// ```
  StickerText(
    this.text, {
    required this.x,
    required this.y,
    this.font = 2,
    this.size = 1,
    this.rotation = 0,
    this.alignment = 'left',
  }) : assert(font >= 0 && font <= 8, 'Font harus antara 0-8'),
       assert(size >= 1 && size <= 10, 'Size harus antara 1-10'),
       assert([0, 90, 180, 270].contains(rotation), 'Rotation harus 0, 90, 180, atau 270'),
       assert(['left', 'center', 'right'].contains(alignment), 'Alignment harus left, center, atau right');
}

/// Class untuk mendefinisikan barcode pada sticker label
///
/// Digunakan bersama dengan [CustomStickerPrinter.printSticker] untuk menambahkan
/// barcode ke dalam layout sticker.
class StickerBarcode {
  /// Data/isi barcode yang akan dicetak
  final String data;
  
  /// Posisi X dalam milimeter (dari kiri, setelah margin)
  final double x;
  
  /// Posisi Y dalam milimeter (dari atas, setelah margin)
  final double y;
  
  /// Tinggi barcode dalam milimeter
  /// - 5-8mm = barcode kecil
  /// - 10-15mm = barcode normal
  /// - 20mm+ = barcode besar
  final double height;
  
  /// Jenis barcode
  /// - 'CODE128' = paling umum, bisa angka dan huruf
  /// - 'CODE39' = angka, huruf, beberapa simbol
  /// - 'EAN13' = barcode produk retail (13 digit)
  /// - 'EAN8' = barcode produk kecil (8 digit)
  final String type;
  
  /// Membuat objek StickerBarcode untuk barcode pada sticker
  ///
  /// [data] adalah string data yang akan diencode ke barcode
  /// [x] dan [y] adalah posisi dalam mm relatif terhadap margin
  /// [height] adalah tinggi barcode dalam mm (default: 10)
  /// [type] adalah jenis barcode (default: 'CODE128')
  ///
  /// Contoh:
  /// ```dart
  /// StickerBarcode('1234567890', x: 0, y: 20, height: 8)
  /// StickerBarcode('ABC123', x: 5, y: 25, height: 12, type: 'CODE39')
  /// ```
  StickerBarcode(
    this.data, {
    required this.x,
    required this.y,
    this.height = 10,
    this.type = 'CODE128',
  }) : assert(height > 0, 'Height harus lebih besar dari 0'),
       assert(data.isNotEmpty, 'Data barcode tidak boleh kosong');
}

/// Utility class untuk mencetak sticker dengan layout yang dapat dikustomisasi
///
/// Menyediakan cara mudah untuk membuat sticker dengan text dan barcode
/// yang posisinya dapat diatur dengan presisi dalam satuan milimeter.
///
/// Contoh penggunaan:
/// ```dart
/// await CustomStickerPrinter.printSticker(
///   printer: PosUniversalPrinter.instance,
///   role: PosPrinterRole.sticker,
///   width: 40,
///   height: 30,
///   gap: 3,
///   marginLeft: 2,
///   marginTop: 2,
///   texts: [
///     StickerText('JUDUL BESAR', x: 0, y: 0, font: 4, size: 1),
///     StickerText('Text normal', x: 0, y: 8, font: 2, size: 1),
///     StickerText('Info detail', x: 0, y: 16, font: 1, size: 1),
///   ],
///   barcode: StickerBarcode('1234567890', x: 0, y: 22, height: 6),
/// );
/// ```
class CustomStickerPrinter {
  /// Mencetak sticker dengan layout yang dapat dikustomisasi
  ///
  /// Method ini adalah "canvas" utama untuk membuat sticker. Anda dapat
  /// mengatur ukuran sticker, margin, dan menambahkan elemen text dan barcode
  /// dengan posisi yang presisi.
  ///
  /// ## Parameter Ukuran & Layout:
  /// - [printer]: Instance PosUniversalPrinter
  /// - [role]: Role printer (biasanya PosPrinterRole.sticker)
  /// - [width]: Lebar sticker dalam mm (HARUS sesuai media fisik!)
  /// - [height]: Tinggi sticker dalam mm (HARUS sesuai media fisik!)
  /// - [gap]: Jarak antar sticker dalam mm (biasanya 2-4mm)
  /// - [marginLeft]: Margin kiri dalam mm (jarak dari tepi kiri sticker)
  /// - [marginTop]: Margin atas dalam mm (jarak dari tepi atas sticker)
  ///
  /// ## Parameter Konten:
  /// - [texts]: List StickerText untuk semua text yang akan dicetak
  /// - [barcode]: StickerBarcode opsional untuk barcode
  ///
  /// ## Parameter Printer (Opsional):
  /// - [direction]: Orientasi print (0=normal, 1=terbalik 180°)
  /// - [density]: Kepadatan tinta (1-15, makin tinggi makin gelap)
  /// - [speed]: Kecepatan print (1-6, makin rendah makin bagus kualitas)
  ///
  /// ## Panduan Ukuran:
  /// 
  /// ### Ukuran Sticker Umum:
  /// - 40x30mm: Sticker produk kecil
  /// - 58x40mm: Sticker produk medium
  /// - 80x50mm: Sticker produk besar
  /// - 100x60mm: Label alamat
  ///
  /// ### Margin yang Disarankan:
  /// - Margin kiri/kanan: 1-5mm
  /// - Margin atas/bawah: 1-3mm
  /// - Untuk sticker kecil (40x30): margin 1-2mm
  /// - Untuk sticker besar (80x50+): margin 3-5mm
  ///
  /// ### Font dan Size Guide:
  /// - Font 1 + Size 1 = ~3mm tinggi (untuk detail kecil)
  /// - Font 2 + Size 1 = ~4mm tinggi (untuk text normal)
  /// - Font 3 + Size 1 = ~5mm tinggi (untuk subtitle)
  /// - Font 4 + Size 1 = ~6mm tinggi (untuk judul)
  /// - Font 3 + Size 2 = ~10mm tinggi (untuk judul besar)
  ///
  /// ### Jarak Antar Baris:
  /// - Text kecil (font 1-2): jarak minimal 5mm
  /// - Text normal (font 3): jarak minimal 6-8mm
  /// - Text besar (font 4+): jarak minimal 8-10mm
  ///
  /// ## Contoh Lengkap:
  /// ```dart
  /// // Sticker produk 40x30mm
  /// await CustomStickerPrinter.printSticker(
  ///   printer: PosUniversalPrinter.instance,
  ///   role: PosPrinterRole.sticker,
  ///   
  ///   // Ukuran sticker (WAJIB sesuai media!)
  ///   width: 40,           // mm
  ///   height: 30,          // mm  
  ///   gap: 3,              // mm - sesuaikan dengan gap fisik
  ///   
  ///   // Margin untuk positioning
  ///   marginLeft: 2,       // mm - mulai print 2mm dari kiri
  ///   marginTop: 1,        // mm - mulai print 1mm dari atas
  ///   
  ///   // Layout text
  ///   texts: [
  ///     // Baris 1: Nama produk (besar)
  ///     StickerText('NAMA PRODUK', x: 0, y: 0, font: 3, size: 1),
  ///     
  ///     // Baris 2: Kode/SKU (normal)  
  ///     StickerText('SKU: ABC123', x: 0, y: 7, font: 2, size: 1),
  ///     
  ///     // Baris 3: Harga (normal)
  ///     StickerText('Rp 25.000', x: 0, y: 14, font: 2, size: 1),
  ///   ],
  ///   
  ///   // Barcode di bagian bawah
  ///   barcode: StickerBarcode('1234567890', x: 0, y: 21, height: 7),
  ///   
  ///   // Fine tuning (opsional)
  ///   direction: 0,        // coba 1 jika terbalik
  ///   density: 8,          // 1-15, coba naik jika print pucat
  ///   speed: 2,            // 1-6, turun untuk kualitas lebih baik
  /// );
  /// ```
  ///
  /// ## Tips Troubleshooting:
  /// - **Sticker double/kosong**: Pastikan width/height sesuai media fisik
  /// - **Text terpotong kiri**: Perbesar marginLeft atau kurangi x
  /// - **Text terpotong kanan**: Perbesar marginRight atau gunakan alignment: 'right'
  /// - **Text terpotong atas**: Perbesar marginTop atau kurangi y
  /// - **Text terpotong bawah**: Perbesar marginBottom atau kurangi y
  /// - **Text terbalik**: Ubah direction dari 0 ke 1 atau sebaliknya
  /// - **Print pucat**: Naikkan density (8 -> 10 -> 12)
  /// - **Kualitas buruk**: Turunkan speed (2 -> 1)
  /// - **Gap salah**: Sesuaikan parameter gap dengan jarak fisik antar sticker
  /// 
  /// ## Alignment dan Positioning:
  /// - **Left align**: `StickerText('Left', x: 0, y: 0, alignment: 'left')`
  /// - **Center align**: `StickerText('Center', x: 0, y: 0, alignment: 'center')`
  /// - **Right align**: `StickerText('Right', x: 0, y: 0, alignment: 'right')`
  /// - **Right align + offset**: `StickerText('Right+5mm', x: 5, y: 0, alignment: 'right')`
  static Future<void> printSticker({
    required PosUniversalPrinter printer,
    required PosPrinterRole role,
    required double width,        // lebar sticker dalam mm
    required double height,       // tinggi sticker dalam mm  
    required double gap,          // gap antar sticker dalam mm
    required double marginLeft,   // margin kiri dalam mm
    required double marginTop,    // margin atas dalam mm
    double marginRight = 2,       // margin kanan dalam mm (NEW!)
    double marginBottom = 2,      // margin bawah dalam mm (NEW!)
    required List<StickerText> texts,
    StickerBarcode? barcode,
    int direction = 0,            // 0=normal, 1=terbalik
    int density = 8,              // 1-15 (kepadatan tinta)
    int speed = 2,                // 1-6 (kecepatan print)
  }) async {
    final sb = StringBuffer();
    const double dotsPerMm = 8;   // 203 DPI ≈ 8 dots/mm
    
    // Setup dasar sticker
    sb.writeln('SIZE $width mm, $height mm');
    sb.writeln('GAP $gap mm, 0 mm');
    sb.writeln('DIRECTION $direction');
    sb.writeln('REFERENCE ${(marginLeft * dotsPerMm).round()},${(marginTop * dotsPerMm).round()}');
    sb.writeln('SPEED $speed');
    sb.writeln('DENSITY $density');
    sb.writeln('CLS');
    
    // Hitung area yang bisa digunakan untuk layout
    final printableWidth = width - marginLeft - marginRight;
    // final printableHeight = height - marginTop - marginBottom; // untuk future use
    
    // Tambahkan semua text dengan perhitungan alignment
    for (final text in texts) {
      double finalX = text.x;
      
      // Hitung posisi X berdasarkan alignment
      switch (text.alignment) {
        case 'center':
          finalX = (printableWidth / 2) + text.x; // text.x sebagai offset dari center
          break;
        case 'right':
          finalX = printableWidth - text.x; // text.x sebagai offset dari kanan
          break;
        case 'left':
        default:
          finalX = text.x; // tetap seperti sebelumnya
          break;
      }
      
      final xDots = (finalX * dotsPerMm).round();
      final yDots = (text.y * dotsPerMm).round();
      sb.writeln('TEXT $xDots,$yDots,"${text.font}",${text.rotation},${text.size},${text.size},"${text.text}"');
    }
    
    // Tambahkan barcode jika ada
    if (barcode != null) {
      final xDots = (barcode.x * dotsPerMm).round();
      final yDots = (barcode.y * dotsPerMm).round();
      final heightDots = (barcode.height * dotsPerMm).round();
      sb.writeln('BARCODE $xDots,$yDots,"${barcode.type}",$heightDots,1,0,1,"${barcode.data}"');
    }
    
    sb.writeln('PRINT 1');
    
    // Print ke printer
    printer.printTspl(role, sb.toString());
  }

  /// Template siap pakai untuk sticker produk 40x30mm
  ///
  /// Template yang sudah dioptimasi untuk sticker produk berukuran 40x30mm
  /// dengan layout yang umum digunakan: nama produk, kode, harga, dan barcode.
  ///
  /// [productName]: Nama produk (akan ditampilkan besar di atas)
  /// [productCode]: Kode/SKU produk  
  /// [price]: Harga produk (format: "Rp 25.000")
  /// [barcodeData]: Data untuk barcode (opsional)
  ///
  /// Contoh:
  /// ```dart
  /// await CustomStickerPrinter.printProductSticker40x30(
  ///   printer: PosUniversalPrinter.instance,
  ///   role: PosPrinterRole.sticker,
  ///   productName: 'KOPI ARABICA',
  ///   productCode: 'KA001', 
  ///   price: 'Rp 35.000',
  ///   barcodeData: '1234567890',
  /// );
  /// ```
  static Future<void> printProductSticker40x30({
    required PosUniversalPrinter printer,
    required PosPrinterRole role,
    required String productName,
    required String productCode,
    required String price,
    String? barcodeData,
    int direction = 0,
    int density = 8,
    int speed = 2,
  }) async {
    await printSticker(
      printer: printer,
      role: role,
      width: 40,
      height: 30,
      gap: 3,
      marginLeft: 2,
      marginTop: 1,
      texts: [
        StickerText(productName, x: 0, y: 0, font: 3, size: 1),
        StickerText(productCode, x: 0, y: 7, font: 2, size: 1),
        StickerText(price, x: 0, y: 14, font: 2, size: 1),
      ],
      barcode: barcodeData != null 
        ? StickerBarcode(barcodeData, x: 0, y: 21, height: 7)
        : null,
      direction: direction,
      density: density,
      speed: speed,
    );
  }

  /// Template siap pakai untuk sticker alamat 58x40mm
  ///
  /// Template yang sudah dioptimasi untuk sticker alamat pengiriman
  /// berukuran 58x40mm dengan layout standar e-commerce.
  ///
  /// [receiverName]: Nama penerima
  /// [address]: Alamat lengkap (akan otomatis dipotong jika terlalu panjang)
  /// [phone]: Nomor telepon
  /// [orderCode]: Kode pesanan (opsional)
  ///
  /// Contoh:
  /// ```dart
  /// await CustomStickerPrinter.printAddressSticker58x40(
  ///   printer: PosUniversalPrinter.instance,
  ///   role: PosPrinterRole.sticker,
  ///   receiverName: 'John Doe',
  ///   address: 'Jl. Merdeka No. 123, Jakarta',
  ///   phone: '081234567890',
  ///   orderCode: 'ORD-2024-001',
  /// );
  /// ```
  static Future<void> printAddressSticker58x40({
    required PosUniversalPrinter printer,
    required PosPrinterRole role,
    required String receiverName,
    required String address,
    required String phone,
    String? orderCode,
    int direction = 0,
    int density = 8,
    int speed = 2,
  }) async {
    // Potong address jika terlalu panjang (maksimal ~25 karakter per baris untuk font 2)
    final addressLines = <String>[];
    if (address.length <= 25) {
      addressLines.add(address);
    } else {
      // Split menjadi 2 baris
      final words = address.split(' ');
      String line1 = '';
      String line2 = '';
      
      for (final word in words) {
        if ((line1 + ' ' + word).length <= 25) {
          line1 += (line1.isEmpty ? '' : ' ') + word;
        } else {
          line2 += (line2.isEmpty ? '' : ' ') + word;
        }
      }
      
      addressLines.add(line1);
      if (line2.isNotEmpty) addressLines.add(line2);
    }

    final texts = <StickerText>[
      // Nama penerima (besar)
      StickerText(receiverName, x: 0, y: 0, font: 3, size: 1),
      // Alamat baris 1
      StickerText(addressLines[0], x: 0, y: 8, font: 2, size: 1),
    ];

    // Alamat baris 2 jika ada
    if (addressLines.length > 1) {
      texts.add(StickerText(addressLines[1], x: 0, y: 15, font: 2, size: 1));
    }

    // Phone
    final phoneY = addressLines.length > 1 ? 22.0 : 15.0;
    texts.add(StickerText(phone, x: 0, y: phoneY, font: 2, size: 1));

    // Order code jika ada
    if (orderCode != null) {
      final orderY = addressLines.length > 1 ? 29.0 : 22.0;
      texts.add(StickerText(orderCode, x: 0, y: orderY, font: 1, size: 1));
    }

    await printSticker(
      printer: printer,
      role: role,
      width: 58,
      height: 40,
      gap: 2,
      marginLeft: 2,
      marginTop: 2,
      texts: texts,
      direction: direction,
      density: density,
      speed: speed,
    );
  }
}
