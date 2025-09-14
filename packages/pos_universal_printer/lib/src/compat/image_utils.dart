import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;

/// Utility helpers for loading and encoding images into ESC/POS friendly
/// byte formats (raster and legacy bit-image). These are intentionally
/// simple and synchronous-within-async to avoid adding heavy dependencies.
class CompatImageUtils {
  /// Loads an asset image, optionally resizes to [maxWidth] (preserving
  /// aspect ratio), converts to monochrome using a simple luminance
  /// threshold, and returns ESC/POS raster bytes (GS v 0).
  static Future<Uint8List> loadAssetAsRaster(
    String assetPath, {
    int? maxWidth,
    int threshold = 160,
  }) async {
    final data = await rootBundle.load(assetPath);
    return _rawImageToRaster(data.buffer.asUint8List(),
        maxWidth: maxWidth, threshold: threshold);
  }

  /// Attempts to decode raw bytes (PNG/JPEG) already in memory and return
  /// ESC/POS raster bytes.
  static Future<Uint8List> rawBytesToRaster(
    Uint8List raw, {
    int? maxWidth,
    int threshold = 160,
  }) async {
    return _rawImageToRaster(raw, maxWidth: maxWidth, threshold: threshold);
  }

  /// Returns true if the provided bytes appear to already be an ESC/POS
  /// raster (GS v 0) sequence.
  static bool looksLikeRaster(Uint8List b) {
    if (b.length < 4) return false;
    return b[0] == 0x1D && b[1] == 0x76 && b[2] == 0x30;
  }

  /// Returns true if the bytes look like PNG (89 50 4E 47) or JPEG (FF D8).
  static bool looksLikeImage(Uint8List b) {
    if (b.length < 4) return false;
    // PNG
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47)
      return true;
    // JPEG
    if (b[0] == 0xFF && b[1] == 0xD8) return true;
    return false;
  }

  /// Internal: decode raw image (PNG/JPG) bytes then convert to raster.
  static Future<Uint8List> _rawImageToRaster(
    Uint8List raw, {
    int? maxWidth,
    int threshold = 160,
  }) async {
    final codec = await ui.instantiateImageCodec(raw);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final targetWidth =
        (maxWidth != null && img.width > maxWidth) ? maxWidth : img.width;
    final scale = targetWidth / img.width;
    final targetHeight = (img.height * scale).round();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();
    canvas.scale(scale);
    canvas.drawImage(img, const ui.Offset(0, 0), paint);
    final picture = recorder.endRecording();
    final resized = await picture.toImage(targetWidth, targetHeight);
    final byteData =
        await resized.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return Uint8List(0);
    final pixels = byteData.buffer.asUint8List();
    final bytes = <int>[];
    final xL = targetWidth % 256;
    final xH = targetWidth ~/ 256;
    final yL = targetHeight % 256;
    final yH = targetHeight ~/ 256;
    bytes.addAll([0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH]);
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x += 8) {
        int b = 0;
        for (int bit = 0; bit < 8; bit++) {
          final px = x + bit;
          int color = 0xFFFFFF;
          if (px < targetWidth) {
            final idx = (y * targetWidth + px) * 4;
            final r = pixels[idx];
            final g = pixels[idx + 1];
            final bl = pixels[idx + 2];
            final lum = (0.299 * r + 0.587 * g + 0.114 * bl).round();
            if (lum < threshold) color = 0x000000;
          }
          b <<= 1;
          if (color == 0x000000) b |= 0x01;
        }
        bytes.add(b);
      }
    }
    return Uint8List.fromList(bytes);
  }

  /// Optional legacy ESC * bit-image encoder for wider compatibility.
  /// Some very old printers only support the bit-image command. This will
  /// split the image into horizontal bands of 24 dots height.
  static Future<Uint8List> loadAssetAsBitImage(
    String assetPath, {
    int? maxWidth,
    int threshold = 160,
  }) async {
    final data = await rootBundle.load(assetPath);
    return _rawImageToBitImage(data.buffer.asUint8List(),
        maxWidth: maxWidth, threshold: threshold);
  }

  static Future<Uint8List> _rawImageToBitImage(
    Uint8List raw, {
    int? maxWidth,
    int threshold = 160,
  }) async {
    final codec = await ui.instantiateImageCodec(raw);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final targetWidth =
        (maxWidth != null && img.width > maxWidth) ? maxWidth : img.width;
    final scale = targetWidth / img.width;
    final targetHeight = (img.height * scale).round();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();
    canvas.scale(scale);
    canvas.drawImage(img, const ui.Offset(0, 0), paint);
    final picture = recorder.endRecording();
    final resized = await picture.toImage(targetWidth, targetHeight);
    final byteData =
        await resized.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return Uint8List(0);
    final pixels = byteData.buffer.asUint8List();
    final out = <int>[];
    // Each band is 24 dots tall.
    for (int bandTop = 0; bandTop < targetHeight; bandTop += 24) {
      // ESC * m nL nH
      final nL = targetWidth % 256;
      final nH = targetWidth ~/ 256;
      // Mode 33 = 24-dot double density often supported; fallback to 32 if needed.
      out.addAll([0x1B, 0x2A, 33, nL, nH]);
      for (int x = 0; x < targetWidth; x++) {
        for (int k = 0; k < 3; k++) {
          // 24 dots => 3 bytes vertical
          int byte = 0;
          for (int bit = 0; bit < 8; bit++) {
            final y = bandTop + k * 8 + bit;
            int color = 0xFFFFFF;
            if (y < targetHeight) {
              final idx = (y * targetWidth + x) * 4;
              final r = pixels[idx];
              final g = pixels[idx + 1];
              final bl = pixels[idx + 2];
              final lum = (0.299 * r + 0.587 * g + 0.114 * bl).round();
              if (lum < threshold) color = 0x000000;
            }
            byte <<= 1;
            if (color == 0x000000) byte |= 0x01;
          }
          out.add(byte);
        }
      }
      // Line feed after each band
      out.add(0x0A);
    }
    return Uint8List.fromList(out);
  }

  /// Public helper to convert raw image bytes already in memory directly
  /// to legacy ESC * bit-image bytes (same logic as asset variant but
  /// without asset bundle load).
  static Future<Uint8List> rawBytesToBitImage(
    Uint8List raw, {
    int? maxWidth,
    int threshold = 160,
  }) async {
    return _rawImageToBitImage(raw, maxWidth: maxWidth, threshold: threshold);
  }
}
