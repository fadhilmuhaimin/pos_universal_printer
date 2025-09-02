import 'dart:convert';

/// Builder for Zebra‑compatible CPCL commands. Supports simple text,
/// barcodes, QR codes and bitmaps. Commands are assembled line by
/// line and encoded in ASCII when [build] is called.
class CpclBuilder {
  final List<String> _lines = <String>[];

  /// Starts a new CPCL page. [width] and [height] are in dots. Typically
  /// 200 dpi printers have 8 dots per mm. [copies] sets number of copies.
  void page(int width, int height, int copies) {
    _lines.add('! 0 200 200 $height $copies');
  }

  /// Adds text using the built‑in font. [font] selects the font id,
  /// [x]/[y] specify the position in dots, [text] is printed verbatim.
  void text(int font, int x, int y, String text) {
    final escaped = text.replaceAll('"', '\\"');
    _lines.add('TEXT $font 0 $x $y $escaped');
  }

  /// Adds a 1D barcode. [type] (e.g. CODE128), [width]/[ratio] specify
  /// bar width and narrow/wide ratio. [height] is in dots, [x]/[y]
  /// specify position, and [data] contains the barcode content.
  void barcode(
    String type,
    int width,
    int ratio,
    int height,
    int x,
    int y,
    String data,
  ) {
    final escaped = data.replaceAll('"', '\\"');
    _lines.add('BARCODE $type $width $ratio $height $x $y $escaped');
  }

  /// Adds a QR code. [model] selects model 2 (2), [size] sets module
  /// size (1–10), [x]/[y] position and [data] content.
  void qrCode(
    int model,
    int size,
    int x,
    int y,
    String data,
  ) {
    final escaped = data.replaceAll('"', '\\"');
    _lines.add('QRCODE $model $size $x $y $escaped');
  }

  /// Embeds a graphic (bitmap) element using hex data. [x]/[y]
  /// position the graphic, [widthBytes] width in bytes, [height] height in
  /// dots. [data] is a hex string of the bitmap (1 bit per pixel).
  void graphic(int x, int y, int widthBytes, int height, String data) {
    _lines.add('EG $widthBytes $height $x $y $data');
  }

  /// Finalizes the print job.
  void printLabel() {
    _lines.add('PRINT');
  }

  /// Returns the built commands encoded as ASCII bytes separated by
  /// newlines.
  List<int> build() => ascii.encode(_lines.join('\n') + '\n');

  /// Returns a sample CPCL page with text and barcode for labels of
  /// height 600 dots (~75 mm at 8 dots/mm).
  static String sampleLabel() {
    final b = CpclBuilder();
    b.page(600, 600, 1);
    b.text(0, 50, 50, 'Sample CPCL');
    b.barcode('CODE128', 2, 2, 80, 50, 150, '123456789012');
    b.qrCode(2, 4, 50, 300, 'https://example.com');
    b.printLabel();
    return b._lines.join('\n') + '\n';
  }
}
