/// Compatibility layer for developers migrating from the
/// `blue_thermal_printer` package (kakzaki.dev). This provides a minimal
/// facade with method names & signatures that resemble the old API so you
/// can switch dependencies with minimal refactors, while internally using
/// the modern PosUniversalPrinter architecture.
///
/// Example migration:
///
///   // OLD
///   import 'package:blue_thermal_printer/blue_thermal_printer.dart';
///   final bluetooth = BlueThermalPrinter.instance;
///   bluetooth.printCustom('Hello', Size.bold.val, Align.center.val);
///
///   // NEW (after adding this package)
///   import 'package:pos_universal_printer/pos_universal_printer.dart';
///   final compat = BlueThermalCompatPrinter.instance;
///   await compat.ensureDevice(role: PosPrinterRole.cashier, device: myDevice);
///   compat.printCustom('Hello', Size.bold.val, Align.center.val);
///
/// Stickers / labels: Keep using `CustomStickerPrinter.printSticker(...)`.
library blue_thermal_compat;

import 'dart:typed_data';
import 'pos_universal_printer.dart';
import 'src/compat/image_utils.dart';
import 'src/core/logging.dart';

/// Public line descriptor for combined logo+lines API.
class CompatLine {
  const CompatLine(this.text, this.size, this.align);
  final String text;
  final int size;
  final int align; // 0/1/2
}

/// Enum copies mimicking the old plugin sizing constants. Internally we map
/// them to ESC/POS bold & size flags (limited by standard fonts).
class Size {
  const Size._(this.val);
  final int val;
  static const normal = Size._(0);
  static const medium = Size._(1); // treated as normal bold
  static const bold = Size._(2);
  static const boldMedium = Size._(3);
  static const boldLarge = Size._(4);
}

/// Alignment enum mimic.
class Align {
  const Align._(this.val);
  final int val;
  static const left = Align._(0);
  static const center = Align._(1);
  static const right = Align._(2);
}

/// Main compatibility facade. Collects commands into an ESC/POS builder
/// and flushes them when requested (or on cut). Not a full re-implementation
/// but enough for common migration scenarios.
class BlueThermalCompatPrinter {
  BlueThermalCompatPrinter._();
  static final BlueThermalCompatPrinter instance = BlueThermalCompatPrinter._();

  final PosUniversalPrinter _printer = PosUniversalPrinter.instance;

  // Role defaults to cashier for receipt style printing.
  PosPrinterRole defaultRole = PosPrinterRole.cashier;

  /// Approximate line character capacity (32 for 58mm, 48 for 80mm).
  int _lineChars = 32;

  /// Set paper size quickly (true = 80mm / 48 chars, false = 58mm / 32 chars)
  void setPaper80mm(bool is80) {
    _lineChars = is80 ? 48 : 32;
  }

  /// Provide a printer device mapping before printing if not already set
  /// via your app logic.
  Future<void> ensureDevice({
    required PosPrinterRole role,
    required PrinterDevice device,
  }) async {
    await _printer.registerDevice(role, device);
  }

  /// Adds a custom text line using similar signature: text, size, align.
  void printCustom(String text, int size, int align) {
    final builder = EscPosBuilder();
    final bold = size >= Size.bold.val; // treat size >=2 as bold
    builder.text(
      text,
      align: _mapAlign(align),
      bold: bold,
    );
    _printer.printEscPos(defaultRole, builder);
  }

  /// Simple newline feed.
  void printNewLine() {
    final b = EscPosBuilder();
    b.feed(1);
    _printer.printEscPos(defaultRole, b);
  }

  /// Print a left/right aligned line (approximation using two separate
  /// draws). Original plugin tried to fit both sides in one line width;
  /// here we just print left then right with alignment adjustments.
  void printLeftRight(String left, String right, int size) {
    final bold = size >= Size.bold.val;
    // Attempt single line composition similar to original plugin.
    final available = _lineChars;
    String composed;
    if (left.length + right.length + 1 <= available) {
      final spaces = available - left.length - right.length;
      composed = left + ' ' * spaces + right;
    } else {
      // Fallback: truncate left if necessary.
      final maxLeft = (available / 2).floor() - 1;
      String l = left;
      if (l.length > maxLeft) l = l.substring(0, maxLeft);
      int remaining = available - l.length - 1;
      String r = right;
      if (r.length > remaining) {
        r = r.substring(r.length - remaining); // keep end of right value
      }
      final spaces = available - l.length - r.length;
      composed = l + ' ' * spaces + r;
    }
    final builder = EscPosBuilder();
    builder.text(composed, align: PosAlign.left, bold: bold);
    _printer.printEscPos(defaultRole, builder);
  }

  /// Prints raw image bytes if already ESC/POS formatted. For migration,
  /// this USED TO expect pre‑encoded ESC/POS raster. Now it auto-detects:
  ///   - If bytes start with ESC/POS raster header (1D 76 30) => send directly.
  ///   - Else treat as an image (PNG/JPG/etc), decode and convert to mono.
  /// Provides legacy ESC * bit-image fallback for broader printer support.
  Future<void> printImageBytes(
    Uint8List bytes, {
    bool center = true,
    bool preferBitImage = false,
    int threshold = 160,
  }) async {
    _printer.debugLog(LogLevel.debug,
        'Compat: printImageBytes len=${bytes.length} preferBitImage=$preferBitImage');
    Uint8List? raster;
    if (CompatImageUtils.looksLikeRaster(bytes)) {
      _printer.debugLog(
          LogLevel.debug, 'Compat: detected existing raster header');
      raster = bytes; // already raster
    } else if (CompatImageUtils.looksLikeImage(bytes)) {
      _printer.debugLog(
          LogLevel.debug, 'Compat: raw image detected, converting to raster');
      raster = await CompatImageUtils.rawBytesToRaster(bytes,
          maxWidth: _lineChars == 48 ? 512 : 384, threshold: threshold);
      _printer.debugLog(
          LogLevel.debug, 'Compat: raster after convert len=${raster.length}');
      if (raster.isEmpty) raster = null;
    } else {
      _printer.debugLog(
          LogLevel.debug, 'Compat: unknown format, forwarding raw bytes');
      raster = bytes; // assume printable
    }
    if (preferBitImage) {
      _printer.debugLog(LogLevel.debug,
          'Compat: preferBitImage path; attempting legacy bit-image encode');
      // We need original decoded image; if we only have raster we cannot revert
      if (CompatImageUtils.looksLikeImage(bytes)) {
        final bit = await CompatImageUtils.rawBytesToBitImage(bytes,
            maxWidth: _lineChars == 48 ? 512 : 384, threshold: threshold);
        if (bit.isNotEmpty) {
          final b = EscPosBuilder();
          b.init();
          if (center) b.setAlign(PosAlign.center);
          b.raster(bit);
          b.feed(1);
          _printer.debugLog(
              LogLevel.debug, 'Compat: dispatched bit-image len=${bit.length}');
          _printer.printEscPos(defaultRole, b);
          return;
        }
      }
    }
    // Fallback to raster (or original if not convertible)
    if (raster == null) {
      _printer.debugLog(
          LogLevel.warning, 'Compat: no raster/bit-image produced, aborting');
      return;
    }
    final builder = EscPosBuilder();
    builder.init();
    if (center) builder.setAlign(PosAlign.center);
    builder.raster(raster);
    builder.feed(2);
    _printer.debugLog(
        LogLevel.debug, 'Compat: dispatch raster len=${raster.length}');
    _printer.printEscPos(defaultRole, builder);
  }

  /// Convenience: load an asset image and print (auto raster). Optionally
  /// specify [threshold] and explicit [maxWidth] (dots). Falls back to
  /// legacy bit-image if raster result is empty.
  Future<void> printImageAsset(
    String assetPath, {
    bool center = true,
    int threshold = 160,
    int? maxWidth,
    bool preferBitImage = false,
  }) async {
    _printer.debugLog(LogLevel.debug,
        'Compat: printImageAsset path=$assetPath preferBitImage=$preferBitImage');
    final width = maxWidth ?? (_lineChars == 48 ? 512 : 384);
    Uint8List? raster;
    if (!preferBitImage) {
      raster = await CompatImageUtils.loadAssetAsRaster(
        assetPath,
        maxWidth: width,
        threshold: threshold,
      );
      _printer.debugLog(
          LogLevel.debug, 'Compat: asset raster len=${raster.length}');
      if (raster.isEmpty) raster = null;
    }
    if (preferBitImage || raster == null) {
      _printer.debugLog(LogLevel.debug, 'Compat: generating bit-image variant');
      final bit = await CompatImageUtils.loadAssetAsBitImage(
        assetPath,
        maxWidth: width,
        threshold: threshold,
      );
      _printer.debugLog(LogLevel.debug, 'Compat: bit-image len=${bit.length}');
      if (bit.isNotEmpty) {
        final b = EscPosBuilder();
        b.init();
        if (center) b.setAlign(PosAlign.center);
        b.raster(bit);
        b.feed(1);
        _printer.printEscPos(defaultRole, b);
        return;
      }
      if (raster == null) {
        _printer.debugLog(
            LogLevel.warning, 'Compat: no raster/bit produced; abort');
        return;
      }
    }
    final builder = EscPosBuilder();
    builder.init();
    if (center) builder.setAlign(PosAlign.center);
    builder.raster(raster);
    builder.feed(2);
    _printer.debugLog(
        LogLevel.debug, 'Compat: dispatch asset image len=${raster.length}');
    _printer.printEscPos(defaultRole, builder);
  }

  /// Barcode convenience (Code128).
  void printBarcode(String data) {
    final builder = EscPosBuilder();
    builder.barcode(data);
    _printer.printEscPos(defaultRole, builder);
  }

  /// QR code convenience.
  void printQRcode(String data) {
    final builder = EscPosBuilder();
    builder.qrCode(data);
    _printer.printEscPos(defaultRole, builder);
  }

  /// Cash drawer pulse.
  void openCashDrawer() {
    _printer.openDrawer(defaultRole);
  }

  /// Paper cut.
  void paperCut() {
    final builder = EscPosBuilder();
    builder.cut();
    _printer.printEscPos(defaultRole, builder);
  }

  /// Combined convenience: prints (optional) asset logo followed by a list of
  /// text lines (each tuple: text, size, align). This reduces Bluetooth round‑trips
  /// versus calling multiple small printCustom and image calls separately.
  Future<void> printLogoAndLines({
    String? assetLogoPath,
    int logoThreshold = 160,
    int? logoMaxWidth,
    bool preferBitImage = false,
    List<CompatLine> lines = const [],
  }) async {
    final b = EscPosBuilder();
    b.init();
    // Insert logo if provided
    if (assetLogoPath != null) {
      try {
        final width = logoMaxWidth ?? (_lineChars == 48 ? 512 : 384);
        Uint8List raster = Uint8List(0);
        if (!preferBitImage) {
          raster = await CompatImageUtils.loadAssetAsRaster(
            assetLogoPath,
            maxWidth: width,
            threshold: logoThreshold,
          );
          _printer.debugLog(
              LogLevel.debug, 'Compat: combined raster len=${raster.length}');
        }
        if (preferBitImage || raster.isEmpty) {
          _printer.debugLog(
              LogLevel.debug, 'Compat: combined using bit-image path');
          final bit = await CompatImageUtils.loadAssetAsBitImage(
            assetLogoPath,
            maxWidth: width,
            threshold: logoThreshold,
          );
          if (bit.isNotEmpty) {
            b.setAlign(PosAlign.center);
            b.raster(bit);
            b.feed(1);
          }
        } else if (raster.isNotEmpty) {
          b.setAlign(PosAlign.center);
          b.raster(raster);
          b.feed(1);
        }
      } catch (_) {
        // ignore logo failure
      }
    }
    // Text lines
    for (final l in lines) {
      final bold = l.size >= Size.bold.val;
      b.text(l.text, align: _mapAlign(l.align), bold: bold);
    }
    _printer.printEscPos(defaultRole, b);
  }

  /// Internal record style representation of a line.
// (moved definition to top)
  PosAlign _mapAlign(int a) {
    switch (a) {
      case 1:
        return PosAlign.center;
      case 2:
        return PosAlign.right;
      default:
        return PosAlign.left;
    }
  }
}
