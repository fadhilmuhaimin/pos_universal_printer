import 'dart:convert';

/// Builder for TSC/Argox compatible TSPL commands. Generates simple
/// commands for labels such as SIZE, GAP, TEXT, BARCODE, QRCODE, BITMAP
/// and PRINT. Commands are concatenated with newlines and encoded in
/// ASCII when [build] is called.
class TsplBuilder {
  final StringBuffer _buffer = StringBuffer();

  /// Sets the label size in millimeters. For example `size(58, 40)` for
  /// 58×40 mm labels.
  void size(int widthMm, int heightMm) {
    _buffer.writeln('SIZE $widthMm mm, $heightMm mm');
  }

  /// Sets the gap between labels in millimeters. For example
  /// `gap(2, 0)` for 2 mm gap.
  void gap(int gapMm, int offsetMm) {
    _buffer.writeln('GAP $gapMm mm, $offsetMm mm');
  }

  /// Sets the print density (1–15). Default density is 8.
  void density(int level) {
    _buffer.writeln('DENSITY $level');
  }

  /// Adds a text element at position ([x],[y]) in dots. [font] selects
  /// built‑in font (0–8), [rotation] is 0/90/180/270 degrees, and
  /// [xMultiplier]/[yMultiplier] scale the font size. [data] is
  /// printed verbatim.
  void text(
    int x,
    int y,
    int font,
    int rotation,
    int xMultiplier,
    int yMultiplier,
    String data,
  ) {
    final escaped = data.replaceAll('"', '\\"');
    _buffer.writeln(
        'TEXT $x,$y,"$font",$rotation,$xMultiplier,$yMultiplier,"$escaped"');
  }

  /// Adds a 1D barcode at ([x],[y]). [type] could be CODE128, EAN13,
  /// etc. [height] is in dots, [humanReadable] prints human readable text
  /// (1 for yes, 0 for no), [data] is the barcode content.
  void barcode(
    int x,
    int y,
    String type,
    int height,
    int readable,
    String data,
  ) {
    final escaped = data.replaceAll('"', '\\"');
    _buffer.writeln('BARCODE $x,$y,"$type",$height,1,0,$readable,"$escaped"');
  }

  /// Adds a QR code at ([x],[y]). [model] is 2 for model 2, [unit]
  /// defines the size of module (1–10), [ecc] error correction level (L,M,Q,H),
  /// [data] contains the content.
  void qrCode(
    int x,
    int y,
    int model,
    int unit,
    String ecc,
    String data,
  ) {
    final escaped = data.replaceAll('"', '\\"');
    _buffer.writeln('QRCODE $x,$y,L,$unit,A,0,M,$model,$ecc,"$escaped"');
  }

  /// Embeds a bitmap image at ([x],[y]). The [mode] can be 0 for
  /// overwrite or 1 for OR. [bitmapData] must be a string of hex digits
  /// representing the image rows. Use a separate utility to encode
  /// images into TSPL bitmap format.
  void bitmap(int x, int y, int widthBytes, int height, int mode, String bitmapData) {
    _buffer.writeln('BITMAP $x,$y,$widthBytes,$height,$mode,$bitmapData');
  }

  /// Issues the PRINT command. [copies] sets the number of labels to print.
  void printLabel([int copies = 1]) {
    _buffer.writeln('PRINT $copies');
  }

  /// Returns the built commands as ASCII encoded bytes.
  List<int> build() => ascii.encode(_buffer.toString());

  /// Returns a sample TSPL command for a 58×40 mm label with simple text
  /// and barcode. The caller can send this output directly to the printer
  /// via [TcpClient].
  static String sampleLabel58x40() {
    final b = TsplBuilder();
    b.size(58, 40);
    b.gap(2, 0);
    b.density(8);
    b.text(20, 20, 3, 0, 1, 1, 'Label 58x40');
    b.barcode(20, 60, 'CODE128', 60, 1, '1234567890');
    b.printLabel(1);
    return b._buffer.toString();
  }

  /// Returns a sample TSPL command for an 80×50 mm label with QR code.
  static String sampleLabel80x50() {
    final b = TsplBuilder();
    b.size(80, 50);
    b.gap(2, 0);
    b.density(8);
    b.text(30, 30, 3, 0, 1, 1, 'Label 80x50');
    b.qrCode(30, 80, 2, 4, 'M', 'https://example.com');
    b.printLabel(1);
    return b._buffer.toString();
  }
}