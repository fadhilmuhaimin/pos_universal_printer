
import '../protocols/escpos/builder.dart';

/// Represents a line item on the receipt.
class ReceiptItem {
  ReceiptItem({required this.name, required this.qty, required this.price});

  final String name;
  final int qty;
  final double price;
}

/// Utility to render a simple receipt using ESC/POS commands. Supports
/// paper widths of 58 mm and 80 mm. Automatically wraps item names and
/// formats amounts in Rupiah.
class ReceiptRenderer {
  /// Renders a list of [items] into ESC/POS bytes. [is80mm] selects
  /// paper width (default 58 mm). Alternatifnya, tentukan [columns]
  /// (jumlah karakter per baris) untuk kontrol penuh — contoh umum:
  /// 72 mm ≈ 48 kolom, 64 mm ≈ ~42 kolom, 57/58 mm ≈ 32 kolom.
  /// [storeName] dan [footer] menyesuaikan header/footer.
  static List<int> render(
    List<ReceiptItem> items, {
    bool is80mm = false,
    int? columns,
    String storeName = 'TOKO CONTOH',
    String footer = 'Terima kasih',
  }) {
    final builder = EscPosBuilder();
    // Header
    builder.setAlign(PosAlign.center);
    builder.text(storeName, bold: true);
    builder.text('Jl. Contoh No. 123, Jakarta');
    builder.text(DateTime.now().toString());
    builder.feed(1);
    // Body
    final paperChars = columns ?? (is80mm ? 48 : 32);
    builder.setAlign(PosAlign.left);
    builder.text('Item            Qty   Harga', bold: true);
    double total = 0;
    for (final item in items) {
      total += item.price * item.qty;
      // wrap name if too long
      final nameLines = _wrap(item.name, paperChars - 16);
      for (int i = 0; i < nameLines.length; i++) {
        final namePart = nameLines[i];
        if (i == 0) {
          final qtyStr = item.qty.toString().padLeft(3);
          final priceStr = _formatRupiah(item.price * item.qty).padLeft(12);
          builder.text('${namePart.padRight(paperChars - 15)} $qtyStr $priceStr');
        } else {
          builder.text(namePart);
        }
      }
    }
    builder.feed(1);
    builder.text('TOTAL'.padRight(paperChars - 12) +
        _formatRupiah(total).padLeft(12),
        bold: true);
    builder.feed(1);
    builder.text(footer, align: PosAlign.center);
    builder.feed(3);
    builder.cut();
    return builder.build();
  }

  /// Wraps a [text] into lines not exceeding [width] characters.
  static List<String> _wrap(String text, int width) {
    final words = text.split(' ');
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      if ((current + (current.isEmpty ? '' : ' ') + word).length > width) {
        lines.add(current);
        current = word;
      } else {
        current += (current.isEmpty ? '' : ' ') + word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  /// Formats a number as Rupiah currency (e.g. 10000 becomes Rp10.000).
  static String _formatRupiah(double amount) {
    final value = amount.toInt();
    final buffer = StringBuffer('Rp');
    final s = value.toString();
    for (int i = 0; i < s.length; i++) {
      buffer.write(s[i]);
      final posFromEnd = s.length - i - 1;
      if (posFromEnd % 3 == 0 && i != s.length - 1) buffer.write('.');
    }
    return buffer.toString();
  }
}