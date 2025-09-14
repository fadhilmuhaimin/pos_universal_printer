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
