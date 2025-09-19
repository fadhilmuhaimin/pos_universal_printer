import '../../pos_universal_printer.dart';

/// Helper classes for simple invoice printing
class MenuItem {
  final String name;
  final List<String> modifications;
  final String? note;

  MenuItem(this.name, this.modifications, [this.note]);
}

/// Predefined sticker sizes for easy use
enum StickerSize {
  mm40x30(40, 30),
  mm58x40(58, 40),
  mm40x25(40, 25),
  mm32x20(32, 20);

  const StickerSize(this.width, this.height);
  final double width;
  final double height;

  ({double width, double height}) get dimensions =>
      (width: width, height: height);
}

/// Font sizes with predefined font combinations
enum FontSize {
  small(1, 2, 4),
  medium(2, 4, 6),
  large(4, 6, 8);

  const FontSize(this.smallFont, this.mediumFont, this.largeFont);
  final int smallFont;
  final int mediumFont;
  final int largeFont;

  ({int small, int medium, int large}) get fonts =>
      (small: smallFont, medium: mediumFont, large: largeFont);
}

/// Model untuk menu item pada invoice sticker
class MenuItemModel {
  final String menuName;
  final List<String> modifications;
  final String? note;
  final String customerName;

  MenuItemModel({
    required this.menuName,
    this.modifications = const [],
    this.note,
    required this.customerName,
  });
}

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

  /// Ketebalan huruf (berat font)
  /// - normal: standar printer
  /// - semiBold: sedikit lebih tebal
  /// - bold: tebal
  final StickerWeight weight;

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
    this.weight = StickerWeight.normal,
  })  : assert(font >= 0 && font <= 8, 'Font harus antara 0-8'),
        assert(size >= 1 && size <= 10, 'Size harus antara 1-10'),
        assert([0, 90, 180, 270].contains(rotation),
            'Rotation harus 0, 90, 180, atau 270'),
        assert(['left', 'center', 'right'].contains(alignment),
            'Alignment harus left, center, atau right');
}

/// Tiga level ketebalan huruf untuk TSPL (dipetakan ke SETBOLD)
enum StickerWeight { normal, semiBold, bold }

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
  })  : assert(height > 0, 'Height harus lebih besar dari 0'),
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
  /// Simplified sticker print API with minimal parameters.
  ///
  /// This uses sane defaults for direction/density/speed and applies a
  /// uniform margin to all sides. Advanced tuning (bold emulation, ensureNewLabel,
  /// y/reference adjustments) are intentionally hidden to keep usage simple.
  static Future<void> printStickerSimple({
    required PosUniversalPrinter printer,
    required PosPrinterRole role,
    required double width,
    required double height,
    required double gap,
    double margin = 1,
    required List<StickerText> texts,
    StickerBarcode? barcode,
    bool emulateBold = true,
  }) async {
    await printSticker(
      printer: printer,
      role: role,
      width: width,
      height: height,
      gap: gap,
      marginLeft: margin,
      marginTop: margin,
      marginRight: margin,
      marginBottom: margin,
      texts: texts,
      barcode: barcode,
      ensureNewLabel: false,
      direction: 0,
      density: 8,
      speed: 2,
      emulateBold: emulateBold,
      yAdjustMm: 0.0,
      referenceYAdjustMm: 0.0,
    );
  }

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
    required double width, // lebar sticker dalam mm
    required double height, // tinggi sticker dalam mm
    required double gap, // gap antar sticker dalam mm
    required double marginLeft, // margin kiri dalam mm
    required double marginTop, // margin atas dalam mm
    double marginRight = 2, // margin kanan dalam mm (NEW!)
    double marginBottom = 2, // margin bawah dalam mm (NEW!)
    required List<StickerText> texts,
    StickerBarcode? barcode,
    // If true, append a FORMFEED after PRINT so the printer advances to the
    // next label gap. Some firmwares require an explicit feed to reset the
    // head/reference between labels. Default=false to avoid changing behavior
    // for users who rely on current settings.
    bool ensureNewLabel = false,
    int direction = 0, // 0=normal, 1=terbalik
    int density = 8, // 1-15 (kepadatan tinta)
    int speed = 2, // 1-6 (kecepatan print)
    // If true, emulate bold/semibold with overstrike (duplicate TEXT with 1-dot offset)
    // to support printers that ignore SETBOLD. Default false to avoid too-bold output
    // on firmwares that already implement hardware bold.
    bool emulateBold = false,
    // Fine-tune vertical position of all texts relative to the label's origin
    // (REFERENCE). Negative values move content up (closer to top edge),
    // positive values move it down. Useful when TOP margin feels too big but
    // setting marginTop=0 makes the next label inconsistent.
    double yAdjustMm = 0.0,
    // Adjust the printer REFERENCE Y directly. Negative reduces the top origin
    // (closer to physical top), positive pushes it down. This is often more
    // reliable than per-text yAdjust when printers differ in DIRECTION.
    double referenceYAdjustMm = 0.0,
    double backfeedMm = 0.0,
  }) async {
    final sb = StringBuffer();
    const double dotsPerMm = 8; // 203 DPI ≈ 8 dots/mm

    // Reset printer state for consistency. Use a single CLS only —
    // FORMFEED and duplicate CLS were causing extra feed/duplicate
    // prints and inconsistent offsets on some firmwares, so remove them.
    sb.writeln('CLS'); // Clear buffer

    // Setup dasar sticker
    sb.writeln('SIZE $width mm, $height mm');
    sb.writeln('GAP $gap mm, 0 mm');
    sb.writeln('DIRECTION $direction');
    // no OFFSET usage by default; keep behavior stable across firmwares
    final refYmm = (marginTop + referenceYAdjustMm);
    final refYdots = (refYmm < 0 ? 0 : (refYmm * dotsPerMm)).round();
    sb.writeln('REFERENCE ${(marginLeft * dotsPerMm).round()},$refYdots');
    sb.writeln('SPEED $speed');
    sb.writeln('DENSITY $density');

    // Optionally backfeed a little to start printing closer to the top edge.
    // Many firmwares interpret BACKFEED value as dots. We convert mm->dots.
    if (backfeedMm > 0) {
      final bfDots = (backfeedMm * dotsPerMm).round();
      if (bfDots > 0) sb.writeln('BACKFEED $bfDots');
    }

    // Hitung area yang bisa digunakan untuk layout
    final printableWidth = width - marginLeft - marginRight;
    // final printableHeight = height - marginTop - marginBottom; // untuk future use

    // Tambahkan semua text dengan perhitungan alignment
    for (final text in texts) {
      double finalX = text.x;

      // Hitung posisi X berdasarkan alignment
      switch (text.alignment) {
        case 'center':
          finalX = (printableWidth / 2) +
              text.x; // text.x sebagai offset dari center
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
      final yDots = ((text.y + yAdjustMm) * dotsPerMm).round();
      // Hardware bold if available, else emulate with overstrike
      if (!emulateBold) {
        // Map ketebalan ke SETBOLD level (0=normal, 1=semi, 2=bold)
        final boldLevel = switch (text.weight) {
          StickerWeight.normal => 0,
          StickerWeight.semiBold => 1,
          StickerWeight.bold => 2,
        };
        sb.writeln('SETBOLD $boldLevel');
        sb.writeln(
            'TEXT $xDots,$yDots,"${text.font}",${text.rotation},${text.size},${text.size},"${text.text}"');
      } else {
        // Emulate bold: draw text multiple times with tiny offsets
        // Keep hardware bold off
        sb.writeln('SETBOLD 0');
        sb.writeln(
            'TEXT $xDots,$yDots,"${text.font}",${text.rotation},${text.size},${text.size},"${text.text}"');
        switch (text.weight) {
          case StickerWeight.normal:
            break; // no extra pass
          case StickerWeight.semiBold:
            sb.writeln(
                'TEXT ${xDots + 1},$yDots,"${text.font}",${text.rotation},${text.size},${text.size},"${text.text}"');
            break;
          case StickerWeight.bold:
            sb.writeln(
                'TEXT ${xDots + 1},$yDots,"${text.font}",${text.rotation},${text.size},${text.size},"${text.text}"');
            sb.writeln(
                'TEXT $xDots,${yDots + 1},"${text.font}",${text.rotation},${text.size},${text.size},"${text.text}"');
            break;
        }
      }
    }
    // Reset bold to normal to avoid affecting next jobs implicitly
    sb.writeln('SETBOLD 0');

    // Tambahkan barcode jika ada
    if (barcode != null) {
      final xDots = (barcode.x * dotsPerMm).round();
      final yDots = (barcode.y * dotsPerMm).round();
      final heightDots = (barcode.height * dotsPerMm).round();
      sb.writeln(
          'BARCODE $xDots,$yDots,"${barcode.type}",$heightDots,1,0,1,"${barcode.data}"');
    }

    sb.writeln('PRINT 1');
    if (ensureNewLabel) {
      // Ask the printer to advance to the next label gap explicitly.
      sb.writeln('FORMFEED');
    }

    // Print ke printer
    final payload = sb.toString();

    // Debug: log TSPL payload so we can inspect exact commands per job
    // ignore: avoid_print
    print('TSPL PAYLOAD (printSticker):\n$payload');

    printer.printTspl(role, payload);

    // Small delay to allow the printer firmware to finish feeding/moving
    // media to the next label. Increase this if your printer needs more time.
    await Future.delayed(const Duration(milliseconds: 600));
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

  /// Membuat invoice sticker untuk menu restoran
  ///
  /// Method ini menghasilkan String TSPL yang siap dikirim ke printer,
  /// dengan format khusus untuk invoice restoran (customer name, timestamp, menu, modifications)
  ///
  /// ## Parameter:
  /// - [menuItem]: Data menu item dengan customer name, menu name, modifications, note
  /// - [widthMm]: Lebar sticker dalam mm (default: 58mm)
  /// - [gapMm]: Gap antar sticker dalam mm (default: 3mm)
  /// - [marginLeft]: Margin kiri dalam mm (default: 3mm)
  /// - [marginTop]: Margin atas dalam mm (default: 3mm)
  /// - [marginRight]: Margin kanan dalam mm (default: 3mm)
  /// - [marginBottom]: Margin bawah dalam mm (default: 3mm)
  ///
  /// ## Format Invoice:
  /// - Customer name (paling atas)
  /// - Timestamp (tanggal jam)
  /// - Menu name (font besar)
  /// - Modifications & note (font kecil, dipisah koma)
  ///
  /// ## Contoh penggunaan:
  /// ```dart
  /// final menuItem = MenuItemModel(
  ///   menuName: 'Nasi Goreng Spesial',
  ///   modifications: ['Extra Pedas', 'Tanpa Bawang'],
  ///   note: 'Jangan terlalu asin',
  ///   customerName: 'John Doe',
  /// );
  ///
  /// final invoiceSticker = CustomStickerPrinter.createInvoiceSticker(
  ///   menuItem: menuItem,
  ///   widthMm: 58,
  ///   gapMm: 3,
  ///   marginLeft: 3,
  ///   marginTop: 3,
  ///   marginRight: 3,
  ///   marginBottom: 3,
  /// );
  ///
  /// await pos.printTspl(PosPrinterRole.sticker, invoiceSticker);
  /// ```
  static String createInvoiceSticker({
    required MenuItemModel menuItem,
    double widthMm = 58,
    double gapMm = 3,
    double marginLeft = 3,
    double marginTop = 3,
    double marginRight = 3,
    double marginBottom = 3,
  }) {
    final now = DateTime.now();
    List<StickerText> texts = [];
    double currentY = 0;

    // Helper untuk nama bulan
    String getMonthName(int month) {
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return months[month];
    }

    // Helper untuk wrap text
    List<String> wrapText(String text, int maxLength) {
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

    // 1. Customer name (paling atas, font kecil)
    texts.add(StickerText(menuItem.customerName,
        x: 0, y: currentY, font: 1, size: 1, alignment: 'left'));
    currentY += 4;

    // 2. Timestamp
    final dateStr =
        '${now.day} ${getMonthName(now.month)} ${now.year} : ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    texts.add(StickerText(dateStr,
        x: 0, y: currentY, font: 1, size: 1, alignment: 'left'));
    currentY += 4;

    // 3. Menu name (font besar)
    texts.add(StickerText(menuItem.menuName,
        x: 0, y: currentY, font: 3, size: 1, alignment: 'left'));
    currentY += 6;

    // 4. Modifications & note (gabung dengan koma, font kecil)
    List<String> allModsAndNotes = [];
    if (menuItem.modifications.isNotEmpty) {
      allModsAndNotes.addAll(menuItem.modifications);
    }
    if (menuItem.note != null && menuItem.note!.isNotEmpty) {
      allModsAndNotes.add(menuItem.note!);
    }

    if (allModsAndNotes.isNotEmpty) {
      final allText = allModsAndNotes.join(', ');
      final wrappedMods =
          wrapText(allText, 30); // max 30 char per line untuk font kecil

      for (String line in wrappedMods) {
        texts.add(StickerText(line,
            x: 0, y: currentY, font: 1, size: 1, alignment: 'left'));
        currentY += 3;
      }
    }

    // Hitung tinggi dinamis berdasarkan content
    final calculatedHeight =
        (currentY + marginTop + marginBottom + 3).clamp(20.0, 50.0);

    // Generate TSPL command string
    return createSticker(
      widthMm: widthMm,
      heightMm: calculatedHeight,
      gapMm: gapMm,
      texts: texts,
      marginLeft: marginLeft,
      marginTop: marginTop,
      marginRight: marginRight,
      marginBottom: marginBottom,
    );
  }

  /// Helper method untuk membuat String TSPL dari texts
  static String createSticker({
    required double widthMm,
    required double heightMm,
    required double gapMm,
    required List<StickerText> texts,
    double marginLeft = 0,
    double marginTop = 0,
    double marginRight = 0,
    double marginBottom = 0,
    List<StickerBarcode>? barcodes,
    bool emulateBold = false,
    double yAdjustMm = 0.0,
  }) {
    final tspl = TsplBuilder();

    // Setup sticker
    tspl.size(widthMm.round(), heightMm.round());
    tspl.gap(gapMm.round(), 0);
    tspl.density(8);

    // Add texts
    for (final text in texts) {
      double actualX = text.x + marginLeft;
      double actualY = text.y + marginTop + yAdjustMm;

      // Handle alignment
      if (text.alignment == 'center') {
        actualX = (widthMm / 2) + text.x;
      } else if (text.alignment == 'right') {
        actualX = widthMm - marginRight + text.x;
      }

      // Convert mm to dots (8 dots per mm for TSPL)
      final xDots = (actualX * 8).round();
      final yDots = (actualY * 8).round();

      if (!emulateBold) {
        // Hardware bold mapping for TsplBuilder (0/1/2)
        final boldLevel = switch (text.weight) {
          StickerWeight.normal => 0,
          StickerWeight.semiBold => 1,
          StickerWeight.bold => 2,
        };
        tspl.setBold(boldLevel);
        tspl.text(xDots, yDots, text.font, text.rotation, text.size, text.size,
            text.text);
      } else {
        // Software bold: disable hardware bold and overstrike
        tspl.setBold(0);
        tspl.text(xDots, yDots, text.font, text.rotation, text.size, text.size,
            text.text);
        switch (text.weight) {
          case StickerWeight.normal:
            break;
          case StickerWeight.semiBold:
            tspl.text(xDots + 1, yDots, text.font, text.rotation, text.size,
                text.size, text.text);
            break;
          case StickerWeight.bold:
            tspl.text(xDots + 1, yDots, text.font, text.rotation, text.size,
                text.size, text.text);
            tspl.text(xDots, yDots + 1, text.font, text.rotation, text.size,
                text.size, text.text);
            break;
        }
      }
    }

    // Add barcodes if any
    if (barcodes != null) {
      for (final barcode in barcodes) {
        final xDots = ((barcode.x + marginLeft) * 8).round();
        final yDots = ((barcode.y + marginTop) * 8).round();
        final heightDots = (barcode.height * 8).round();

        if (barcode.type == 'QR') {
          tspl.qrCode(xDots, yDots, 2, 4, 'M', barcode.data);
        } else {
          tspl.barcode(xDots, yDots, barcode.type, heightDots, 1, barcode.data);
        }
      }
    }

    tspl.setBold(0);
    tspl.printLabel(1);

    return String.fromCharCodes(tspl.build());
  }

  /// **Level 1: Super Simple Invoice (ONE-LINER)**
  ///
  /// Method paling mudah untuk print invoice sticker restoran.
  /// Cocok untuk pemula yang ingin langsung pakai tanpa ribet.
  ///
  /// ```dart
  /// await CustomStickerPrinter.printInvoice(
  ///   printer: printer,
  ///   role: PosPrinterRole.sticker,
  ///   customer: 'John Doe',
  ///   menu: 'Nasi Goreng Spesial',
  ///   details: 'Extra Pedas, Tanpa Bawang, Jangan asin',
  /// );
  /// ```
  static Future<void> printInvoice({
    required PosUniversalPrinter printer,
    required PosPrinterRole role,
    required String customer,
    required String menu,
    String? details,
    double widthMm = 40,
    double heightMm = 30,
    double gapMm = 3,
  }) async {
    final now = DateTime.now();
    final dateStr =
        '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    List<StickerText> texts = [
      // Customer name
      StickerText(customer, x: 2, y: 0, font: 1, size: 1, alignment: 'left'),
      // Date time
      StickerText(dateStr, x: 2, y: 4, font: 1, size: 1, alignment: 'left'),
      // Menu name (big font)
      StickerText(menu, x: 2, y: 8, font: 4, size: 1, alignment: 'left'),
    ];

    // Details if provided
    if (details != null && details.isNotEmpty) {
      texts.add(StickerText(details,
          x: 2, y: 16, font: 1, size: 1, alignment: 'left'));
    }

    await printSticker(
      printer: printer,
      role: role,
      width: widthMm,
      height: heightMm,
      gap: gapMm,
      marginLeft: 1,
      marginTop: 1,
      texts: texts,
    );
  }

  /// **Level 2: Template with Options (CUSTOMIZABLE)**
  ///
  /// Template invoice dengan opsi customization untuk user menengah.
  /// Bisa atur ukuran sticker, font, dan spacing.
  ///
  /// ```dart
  /// await CustomStickerPrinter.printInvoiceSticker(
  ///   printer: printer,
  ///   role: PosPrinterRole.sticker,
  ///   customerName: 'John Doe',
  ///   menuName: 'Nasi Goreng Spesial',
  ///   modifications: ['Extra Pedas', 'Tanpa Bawang'],
  ///   note: 'Jangan terlalu asin',
  ///   stickerSize: StickerSize.mm58x40,
  ///   fontSize: FontSize.large,
  /// );
  /// ```
  static Future<void> printInvoiceSticker({
    required PosUniversalPrinter printer,
    required PosPrinterRole role,
    required String customerName,
    required String menuName,
    List<String> modifications = const [],
    String? note,
    StickerSize stickerSize = StickerSize.mm40x30,
    FontSize fontSize = FontSize.medium,
    double gapMm = 3,
    double marginMm = 2,
  }) async {
    final now = DateTime.now();
    final dateStr =
        '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Get size from enum
    final size = stickerSize.dimensions;
    final fonts = fontSize.fonts;

    List<StickerText> texts = [];
    double currentY = 0;

    // Customer name
    texts.add(StickerText(customerName,
        x: marginMm,
        y: currentY,
        font: fonts.small,
        size: 1,
        alignment: 'left'));
    currentY += 4;

    // Date time
    texts.add(StickerText(dateStr,
        x: marginMm,
        y: currentY,
        font: fonts.small,
        size: 1,
        alignment: 'left'));
    currentY += 4;

    // Menu name (big)
    texts.add(StickerText(menuName,
        x: marginMm,
        y: currentY,
        font: fonts.large,
        size: 1,
        alignment: 'left'));
    currentY += 6;

    // Modifications + note
    List<String> allDetails = [];
    allDetails.addAll(modifications);
    if (note != null && note.isNotEmpty) allDetails.add(note);

    if (allDetails.isNotEmpty) {
      final detailText = allDetails.join(', ');
      texts.add(StickerText(detailText,
          x: marginMm,
          y: currentY,
          font: fonts.small,
          size: 1,
          alignment: 'left'));
    }

    await printSticker(
      printer: printer,
      role: role,
      width: size.width,
      height: size.height,
      gap: gapMm,
      marginLeft: marginMm,
      marginTop: marginMm,
      texts: texts,
    );
  }

  /// **Level 3: Multi-Menu Invoice (RESTAURANT STYLE)**
  ///
  /// Print multiple menu items sekaligus, setiap menu = 1 sticker terpisah.
  /// Seperti implementasi di main.dart yang sudah perfect.
  ///
  /// ```dart
  /// await CustomStickerPrinter.printRestaurantOrder(
  ///   printer: printer,
  ///   role: PosPrinterRole.sticker,
  ///   customerName: 'John Doe',
  ///   menuItems: [
  ///     MenuItem('Nasi Goreng', ['Extra Pedas'], 'Jangan asin'),
  ///     MenuItem('Es Teh Manis', ['Gelas Besar'], 'Banyak es'),
  ///   ],
  /// );
  /// ```
  static Future<void> printRestaurantOrder({
    required PosUniversalPrinter printer,
    required PosPrinterRole role,
    required String customerName,
    required List<MenuItem> menuItems,
    double widthMm = 40,
    double gapMm = 3,
    double marginLeftMm = 12, // 🔧 Margin kiri yang konsisten
    double marginTopMm = 2, // 🔧 Margin atas yang konsisten
  }) async {
    final now = DateTime.now();

    // Print each menu item as separate sticker dengan delay untuk konsistensi
    for (int i = 0; i < menuItems.length; i++) {
      final menuItem = menuItems[i];

      // Tambahkan delay kecil antar sticker untuk memastikan positioning yang benar
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      List<StickerText> texts = [];
      double currentY = 0; // Start from 0, margin akan ditangani oleh marginTop

      // Customer name (paling atas)
      texts.add(StickerText(customerName,
          x: 0,
          y: currentY,
          font: 1,
          size: 1,
          alignment: 'left')); // x=0 untuk konsisten dengan margin
      currentY += 4;

      // Date time
      final dateStr =
          '${now.day} ${_getMonthName(now.month)} ${now.year} : ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      texts.add(StickerText(dateStr,
          x: 0,
          y: currentY,
          font: 1,
          size: 1,
          alignment: 'left')); // x=0 untuk konsisten dengan margin
      currentY += 4;

      // Menu name (font besar)
      texts.add(StickerText(menuItem.name,
          x: 0,
          y: currentY,
          font: 8,
          size: 1,
          alignment: 'left')); // x=0 untuk konsisten dengan margin
      currentY += 4;

      // Modifications + note (gabung dengan koma)
      List<String> allDetails = [];
      allDetails.addAll(menuItem.modifications);
      if (menuItem.note != null && menuItem.note!.isNotEmpty) {
        allDetails.add(menuItem.note!);
      }

      if (allDetails.isNotEmpty) {
        final detailText = allDetails.join(', ');
        final wrappedLines = _wrapText(detailText, 30);

        for (String line in wrappedLines) {
          texts.add(StickerText(line,
              x: 0,
              y: currentY,
              font: 2,
              size: 1,
              alignment: 'left')); // x=0 untuk konsisten dengan margin
          currentY += 3;
        }
      }

      // Dynamic height
      final calculatedHeight = (currentY + 6).clamp(15.0, 30.0);

      await printSticker(
        printer: printer,
        role: role,
        width: widthMm,
        height: calculatedHeight,
        gap: gapMm,
        marginLeft: marginLeftMm, // 🔧 Gunakan margin kiri yang konsisten
        marginTop: marginTopMm, // 🔧 Gunakan margin atas yang konsisten
        marginRight: 1,
        marginBottom: 1,
        texts: texts,
      );
    }
  }

  // Helper methods
  static String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }

  static List<String> _wrapText(String text, int maxLength) {
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
}
