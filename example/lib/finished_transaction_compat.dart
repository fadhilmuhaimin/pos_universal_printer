import 'package:pos_universal_printer/pos_universal_printer.dart';
import 'demo_transaction_data.dart';
// Image handling removed; now handled internally by BlueThermalCompatPrinter

/// Utility to format currency (simple, no locale grouping beyond thousands).
String _formatCurrency(double v) {
  final s = v.toStringAsFixed(0);
  final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
  return 'Rp ' + s.replaceAllMapped(reg, (m) => '.');
}

/// Compatibility style printer mimicking original FinishedTransactionPrint
/// but using BlueThermalCompatPrinter facade (56mm target).
class FinishedTransactionCompatPrinter {
  FinishedTransactionCompatPrinter({
    this.is80mm = false,
    this.logoAssetPath,
    this.logoThreshold = 160,
    this.logoMaxWidth, // override auto width; if null we pick based on paper
  });

  final bool is80mm; // false => 56/58mm (32 cols), true => 80mm (48 cols)
  final String? logoAssetPath; // optional path to logo asset (handled in compat layer)
  final int logoThreshold; // luminance threshold 0-255
  final int? logoMaxWidth; // manual max width in dots (overrides paper default)

  final BlueThermalCompatPrinter _compat = BlueThermalCompatPrinter.instance;

  Future<void> printTransaction(FullTransactionDemo tx, {PosPrinterRole? role}) async {
    // If caller provides a role, set the compat defaultRole so output goes to that device.
    if (role != null) {
      _compat.defaultRole = role;
    }
    // Configure paper width
    _compat.setPaper80mm(is80mm);

    final now = DateTime.now();
    final dateStr = '${now.year}-${_pad2(now.month)}-${_pad2(now.day)}';
    final timeStr = '${_pad2(now.hour)}:${_pad2(now.minute)}';

    // Build all lines in order, mimicking previous output
    final List<CompatLine> lines = [];
    lines.add(CompatLine('TOKO DEMO', Size.boldLarge.val, Align.center.val));
    lines.add(CompatLine('Jl. Contoh No.1', Size.medium.val, Align.center.val));
    lines.add(CompatLine('', Size.normal.val, Align.left.val));
    lines.add(CompatLine(_composeLeftRight('Kasir:', 'Demo'), Size.bold.val, Align.left.val));
    lines.add(CompatLine(_composeLeftRight('Tanggal:', dateStr), Size.bold.val, Align.left.val));
    lines.add(CompatLine(_composeLeftRight('Waktu:', timeStr), Size.bold.val, Align.left.val));
    lines.add(CompatLine(_composeLeftRight('Tipe:', tx.orderType == 'take_away' ? 'Take Away' : 'Dine In'), Size.bold.val, Align.left.val));
    lines.add(CompatLine(_composeLeftRight('Customer:', tx.customerName), Size.bold.val, Align.left.val));
    lines.add(CompatLine('', Size.normal.val, Align.left.val));

    for (final line in tx.transactions) {
      final qtyPrice = line.product.price * line.quantity;
      final leftTitle = '${line.quantity}x ${line.product.name}';
      lines.add(CompatLine(_composeLeftRight(leftTitle, _formatCurrency(qtyPrice.toDouble())), Size.bold.val, Align.left.val));
      for (final v in line.selectedVariants) {
        lines.add(CompatLine('  +${v.name}', Size.bold.val, Align.left.val));
      }
      for (final a in line.selectedAdditions) {
        lines.add(CompatLine(_composeLeftRight('  +${a.name}', _formatCurrency(a.price.toDouble())), Size.bold.val, Align.left.val));
      }
      if (line.notes.isNotEmpty) {
        lines.add(CompatLine('   Catatan: ${line.notes}', Size.medium.val, Align.left.val));
      }
      lines.add(CompatLine('', Size.normal.val, Align.left.val));
    }

    final subtotal = tx.transactions.fold<double>(0, (p, e) => p + e.product.totalPrice);
    final discountGlobal = tx.discount;
    final totalAfterDiscount = subtotal - discountGlobal;
    final total = totalAfterDiscount + tx.tax;
    lines.add(CompatLine(_composeLeftRight('Sub Total:', _formatCurrency(subtotal)), Size.bold.val, Align.left.val));
    if (discountGlobal > 0) {
      lines.add(CompatLine(_composeLeftRight('Diskon:', '-${_formatCurrency(discountGlobal)}'), Size.bold.val, Align.left.val));
    }
    lines.add(CompatLine(_composeLeftRight('Pajak:', '+${_formatCurrency(tx.tax)}'), Size.bold.val, Align.left.val));
    lines.add(CompatLine(_composeLeftRight('Total:', _formatCurrency(total)), Size.boldLarge.val, Align.left.val));
    lines.add(CompatLine('', Size.normal.val, Align.left.val));
    lines.add(CompatLine('Terima Kasih :)', Size.bold.val, Align.center.val));

    await _compat.printLogoAndLines(
      assetLogoPath: logoAssetPath,
      logoThreshold: logoThreshold,
      logoMaxWidth: logoMaxWidth,
      preferBitImage: true,
      lines: lines,
    );
    // Perform cut as a separate small job (small payload)
    _compat.paperCut();
  }

  String _pad2(int v) => v.toString().padLeft(2, '0');

  String _composeLeftRight(String left, String right) {
    // Determine line width based on paper configuration
    final width = is80mm ? 48 : 32; // approximate chars
    // If already fits with at least one space
    final minSpaces = 1;
    if (left.length + right.length + minSpaces <= width) {
      final spaces = width - left.length - right.length;
      return left + ' ' * spaces + right;
    }
    // Truncate left if overly long
    final maxLeft = (width * 0.6).floor();
    String l = left;
    if (l.length > maxLeft) l = l.substring(0, maxLeft - 1) + '…';
    // Recompute available for right
    final remain = width - l.length - 1; // at least 1 space
    String r = right;
    if (r.length > remain) {
      // Keep tail of right value (price usually important at end)
      r = r.substring(r.length - remain);
    }
    final spaces = width - l.length - r.length;
    return l + ' ' * spaces + r;
  }

}

/// New printer: prints each beverage line as an individual sticker using
/// the same invoice-style format (_testInvoiceStyle logic) adapted for
/// TransactionLineDemo structures. Designed for bar/beverage station.
class BeverageStickerPrinter {
  BeverageStickerPrinter({
    this.customerName = 'Customer',
    this.detailsCharBudget = 25,
    this.maxLabelHeightMm = 30.0,
    this.detailsWrapWidthChars = 25,
    this.detailsMaxLines = 0, // 0 => unlimited
    this.autoGrowHeight = false,
    this.detailsLineHeightMm = 3.0,
    this.afterDetailsSpacingMm = 1.0,
    this.timeBlockMm = 4.0,
    this.customerBlockMm = 4.0,
    this.bottomPadMm = 6.0,
    this.detailsJoinSeparator = '',
    this.debugLog = false,
  });

  final String customerName;
  final int detailsCharBudget;
  // Maximum sticker height to target (physical label height).
  // Long details will be wrapped and truncated to fit this height.
  final double maxLabelHeightMm;
  // Wrap width for details block (characters per line before wrapping).
  final int detailsWrapWidthChars;
  // Optional hard limit on number of wrapped detail lines (0 => unlimited).
  final int detailsMaxLines;
  // If true, auto-compute label height from content and do not clamp to maxLabelHeightMm.
  // If false, clamp to maxLabelHeightMm and truncate detail lines to fit.
  final bool autoGrowHeight;
  // Vertical layout knobs
  final double detailsLineHeightMm; // per detail wrapped line height
  final double afterDetailsSpacingMm; // spacing between details and time
  final double timeBlockMm; // height reserved for printing time
  final double customerBlockMm; // height reserved for printing customer
  final double bottomPadMm; // bottom padding before label end
  // Separator used when joining variants + additions + notes before trimming by characters.
  // Default '' means strict concatenation so character counting is exact across items.
  final String detailsJoinSeparator;
  // Print debug logs to console (combined details length, trimmed result, etc.)
  final bool debugLog;
  // Limits derived from demo data lengths:
  // 'Es Kopi Susu Aren1234567' => 24 chars
  // 'John test 2lasjdnlkasdas'  => 24 chars
  static const int _maxProductChars = 24;
  static const int _maxCustomerChars = 24;
  // Word limit for combined variants + additions + notes:
  // e.g., Less Ice (2), Less Sugar (2), Extra Shotasdsadas (2), Extra extra (2),
  // 'Kocok dahulu seb' (3) => total 11 words

  // Convert a single TransactionLineDemo into sticker texts and print sequentially.
  Future<void> printBeverageLines(List<TransactionLineDemo> lines, {required PosPrinterRole role}) async {
    final printer = PosUniversalPrinter.instance;
    final now = DateTime.now();
    for (final line in lines) {
      final qty = line.quantity <= 0 ? 1 : line.quantity;
      for (int copy = 1; copy <= qty; copy++) {
      // Build sticker content with order:
      // 1) Product name (bold)
      // 2) Additions/Variants/Notes (regular)
      // 3) Time (regular)
      // 4) Customer name UPPERCASE (regular)
      final texts = <StickerText>[];
  double currentY = 1;
      const double x = 0; // relative start (margin handled by print call)
      
      // 1) Product name (bold)
      // Compute product name within char limit (including copy suffix if any)
      String baseName = line.product.name;
      String suffix = '';
      if (qty > 1) {
        suffix = ' (${copy}/$qty)';
      }
      final int allowed = (_maxProductChars - suffix.length).clamp(0, _maxProductChars);
      if (baseName.length > allowed) {
        baseName = baseName.substring(0, allowed);
      }
      final productName = baseName + suffix;
      texts.add(StickerText(productName, x: x, y: currentY, font: 2, size: 1, alignment: 'left', weight: StickerWeight.bold));
  currentY += 4; // product line block (kept constant for now)

      // 2) Details block (variants + additions + notes)
      final detailsTexts = _createDetailsTexts(line);
      for (final detailText in detailsTexts) {
        texts.add(StickerText(detailText, x: x, y: currentY, font: 2, size: 1, alignment: 'left', weight: StickerWeight.normal));
        currentY += detailsLineHeightMm;
      }
      if (detailsTexts.isNotEmpty) {
        currentY += afterDetailsSpacingMm;
      }

      // 3) Time (regular)
      final dateStr = '${now.day.toString().padLeft(2,'0')} ${_monthName(now.month)} ${now.year} : '
          '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
  texts.add(StickerText(dateStr, x: x, y: currentY, font: 1, size: 1, alignment: 'left', weight: StickerWeight.normal));
  currentY += timeBlockMm;

      // 4) Customer name UPPERCASE (regular)
      // Customer uppercased with char limit
      String custCaps = _allCaps(customerName);
      if (custCaps.length > _maxCustomerChars) {
        custCaps = custCaps.substring(0, _maxCustomerChars);
      }
  texts.add(StickerText(custCaps, x: x, y: currentY, font: 2, size: 1, alignment: 'left', weight: StickerWeight.normal));
  currentY += customerBlockMm;

  final computed = currentY + bottomPadMm;
  final height = autoGrowHeight ? computed.clamp(15.0, 300.0) : computed.clamp(15.0, maxLabelHeightMm);
      // Print sticker (simplified API)
      await CustomStickerPrinter.printStickerSimple(
        printer: printer,
        role: role,
        width: 49,
        height: height,
        gap: 3,
        margin: 0,
        texts: texts,
      );
      // small delay between stickers/copies
      await Future.delayed(const Duration(milliseconds: 800));
      }
    }
  }

  static String _monthName(int m) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m];
  }

  static String _allCaps(String s) => s.toUpperCase();

  /// Build the combined details string from variants, additions, and notes
  String _buildDetailsText(TransactionLineDemo line) {
    final parts = <String>[];
    parts.addAll(line.selectedVariants.map((e) => e.name));
    parts.addAll(line.selectedAdditions.map((e) => e.name));
    final notes = line.notes.trim();
    if (notes.isNotEmpty) parts.add(notes);
    
    final combined = parts.join(detailsJoinSeparator);
    if (combined.length <= detailsCharBudget) return combined;
    return combined.substring(0, detailsCharBudget);
  }

  /// Calculate maximum allowed detail lines based on height constraints
  int _calculateMaxAllowedLines(double currentY) {
    if (autoGrowHeight) {
      return detailsMaxLines > 0 ? detailsMaxLines : 999; // effectively unlimited
    }
    
    // Calculate remaining space for details
    final remainingForDetails = maxLabelHeightMm - 
        (currentY + afterDetailsSpacingMm + timeBlockMm + customerBlockMm + bottomPadMm);
    int maxDetailLines = (remainingForDetails / detailsLineHeightMm).floor();
    if (maxDetailLines < 0) maxDetailLines = 0;
    
    if (detailsMaxLines > 0) {
      maxDetailLines = maxDetailLines.clamp(0, detailsMaxLines);
    }
    return maxDetailLines;
  }

  /// Wrap text into lines with proper character limits
  List<String> _wrapDetailsText(String text) {
    if (text.length <= detailsWrapWidthChars) return [text];
    
    final lines = <String>[];
    var remaining = text;
    
    // Simple character-based wrapping (ignore word boundaries for consistent behavior)
    while (remaining.length > detailsWrapWidthChars) {
      lines.add(remaining.substring(0, detailsWrapWidthChars));
      remaining = remaining.substring(detailsWrapWidthChars);
    }
    
    if (remaining.isNotEmpty) {
      lines.add(remaining);
    }
    
    return lines;
  }

  /// Create the final list of detail text lines for printing
  List<String> _createDetailsTexts(TransactionLineDemo line) {
    final detailsText = _buildDetailsText(line);
    if (detailsText.isEmpty) return [];
    
    if (debugLog) {
      // ignore: avoid_print
      print('[StickerDebug] budget=$detailsCharBudget, wrapWidth=$detailsWrapWidthChars, '
          'autoGrow=$autoGrowHeight, joinSep="${detailsJoinSeparator.replaceAll(' ', '␠')}" '
          '=> len=${detailsText.length}, text="$detailsText"');
    }
    
    final wrappedLines = _wrapDetailsText(detailsText);
    final maxAllowedLines = _calculateMaxAllowedLines(5.0); // approximate currentY after product
    
    return wrappedLines.take(maxAllowedLines).toList();
  }

  

}
