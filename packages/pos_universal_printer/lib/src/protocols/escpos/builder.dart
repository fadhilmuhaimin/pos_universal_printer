import 'dart:convert';

/// Alignment options for ESC/POS printing.
enum PosAlign { left, center, right }

/// ESC/POS command builder. Constructs a sequence of bytes representing
/// commands to a thermal printer. Supports basic formatting, alignment,
/// bold text, barcode, QR code, raster image and cut.
class EscPosBuilder {
  final List<int> _bytes = <int>[];

  /// Initializes printer (ESC @) to reset modes. Safe to call multiple times.
  void init() {
    _bytes.addAll([0x1B, 0x40]);
  }

  /// Adds plain text to the buffer with optional [bold] and [align]. The
  /// default alignment is [PosAlign.left].
  void text(String text, {PosAlign align = PosAlign.left, bool bold = false}) {
    setAlign(align);
    if (bold) {
      _bytes.addAll([0x1B, 0x45, 0x01]); // ESC E 1 bold on
    }
    _bytes.addAll(utf8.encode(text));
    _bytes.add(0x0A); // line feed
    if (bold) {
      _bytes.addAll([0x1B, 0x45, 0x00]); // bold off
    }
  }

  /// Sets the alignment for subsequent text. Sent immediately when called.
  void setAlign(PosAlign align) {
    int n;
    switch (align) {
      case PosAlign.center:
        n = 1;
        break;
      case PosAlign.right:
        n = 2;
        break;
      case PosAlign.left:
        n = 0;
    }
    _bytes.addAll([0x1B, 0x61, n]);
  }

  /// Feeds the paper by [lines] lines.
  void feed(int lines) {
    if (lines <= 0) return;
    _bytes.addAll([0x1B, 0x64, lines]);
  }

  /// Cuts the paper. Uses full cut by default.
  void cut() {
    // GS V 66 0 – full cut
    _bytes.addAll([0x1D, 0x56, 0x42, 0x00]);
  }

  /// Adds a barcode using Code128 (type 73). The printer must support
  /// Code128. Data is encoded in Code Set B.
  void barcode(String data) {
    final bytes = utf8.encode(data);
    // Select barcode height (GS h). Default height 50.
    _bytes.addAll([0x1D, 0x68, 0x50]);
    // Print Code128 (GS k 73)
    _bytes.addAll([0x1D, 0x6B, 0x49, bytes.length]);
    _bytes.addAll(bytes);
  }

  /// Adds a QR code. The [data] is encoded using the ESC/POS QR code
  /// commands (model 2, error correction M, module size 4). This
  /// generates a square QR code. See Epson ESC/POS manual for details.
  void qrCode(String data) {
    final bytes = utf8.encode(data);
    final pL = (bytes.length + 3) % 256;
    final pH = (bytes.length + 3) ~/ 256;
    // Store data in symbol buffer
    _bytes.addAll([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30]);
    _bytes.addAll(bytes);
    // Select model: model 2
    _bytes.addAll([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);
    // Set module size to 4 dots
    _bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x04]);
    // Set error correction level M (0x31 0x45 0x01)
    _bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x01]);
    // Print the QR code (0x31 0x51 0x30)
    _bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
  }

  /// Adds a raster image to the buffer. The [bitmap] should contain
  /// pre‑encoded ESC/POS raster data. Generating image data is outside
  /// the scope of this builder; consider using a separate utility to
  /// convert an image to mono raster bytes.
  void raster(List<int> bitmap) {
    _bytes.addAll(bitmap);
  }

  /// Returns the complete list of bytes representing the built receipt.
  List<int> build() => List<int>.from(_bytes);
}

/// Helper utilities for ESC/POS commands.
class EscPosHelper {
  /// Builds the command sequence to open the cash drawer via the RJ‑11
  /// connector. The default values correspond to m=0, t1=25, t2=250.
  static List<int> openDrawer({int m = 0, int t1 = 25, int t2 = 250}) {
    return [0x1B, 0x70, m, t1, t2];
  }
}
