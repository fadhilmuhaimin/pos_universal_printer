import 'package:flutter/material.dart' hide Align; // hide Flutter Align to use compat Align enum
import 'package:pos_universal_printer/pos_universal_printer.dart';
import 'package:pos_universal_printer/src/helpers/custom_sticker.dart';
import 'demo_transaction_data.dart';
import 'finished_transaction_compat.dart';
import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui' as ui;

// 🧾 Model untuk Invoice Menu
class OrderItem {
  final String name;
  final List<String> modifications;
  final String? note;

  OrderItem({
    required this.name,
    this.modifications = const [],
    this.note,
  });
}

// 📝 MODEL BARU UNTUK DATA POS SYSTEM
class Product {
  final int id;
  final String name;
  final int price;
  final String totalPrice;
  final String discountProduct;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.totalPrice,
    required this.discountProduct,
  });
}

class VariantOption {
  final int id;
  final String name;
  final int price;

  VariantOption({
    required this.id,
    required this.name,
    required this.price,
  });
}

class AdditionOption {
  final int id;
  final String name;
  final String price;

  AdditionOption({
    required this.id,
    required this.name,
    required this.price,
  });
}

class PosTransaction {
  final Product product;
  final List<VariantOption> selectedVariants;
  final List<AdditionOption> selectedAdditions;
  final String notes;
  final int quantity;

  PosTransaction({
    required this.product,
    required this.selectedVariants,
    required this.selectedAdditions,
    required this.notes,
    required this.quantity,
  });
}

class Order {
  final DateTime dateTime;
  final List<OrderItem> items;
  final String customerName; // 🆕 Nama customer

  Order({
    required this.dateTime,
    required this.items,
    required this.customerName, // 🆕 Required customer name
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Universal Printer Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'POS Universal Printer Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PosUniversalPrinter printer = PosUniversalPrinter.instance;
  Map<PosPrinterRole, PrinterType> _selectedType = {};
  Map<PosPrinterRole, String?> _selectedDeviceId = {};
  Map<PosPrinterRole, TextEditingController> _ipControllers = {};
  Map<PosPrinterRole, TextEditingController> _portControllers = {};
  List<PrinterDevice> _bluetoothDevices = [];
  
  // 🆕 Loading states untuk UI
  Map<PosPrinterRole, bool> _isConnecting = {};
  Map<PosPrinterRole, bool> _isDisconnecting = {};
  Map<PosPrinterRole, bool> _isConnected = {};
  bool _isScanning = false;
  bool _showLogs = false;
  // (Removed stream subscription approach; using one-shot scan now)

  @override
  void initState() {
    super.initState();
    for (var role in PosPrinterRole.values) {
      _selectedType[role] = PrinterType.bluetooth;
      _ipControllers[role] = TextEditingController(text: '192.168.1.100');
      _portControllers[role] = TextEditingController(text: '9100');
      
      // 🆕 Initialize loading states
      _isConnecting[role] = false;
      _isDisconnecting[role] = false;
      _isConnected[role] = false;
    }
  }

  // 🆕 Method untuk connect printer dengan loading
  Future<void> _connectPrinter(PosPrinterRole role) async {
    setState(() {
      _isConnecting[role] = true;
    });

    try {
      final type = _selectedType[role]!;
      PrinterDevice? device;

      if (type == PrinterType.bluetooth) {
        String? deviceId = _selectedDeviceId[role];
        if (deviceId != null) {
          // Cari device dari list bluetooth devices
          device = _bluetoothDevices.firstWhere(
            (d) => d.id == deviceId,
            orElse: () => PrinterDevice(
              id: deviceId,
              name: 'Device $deviceId',
              type: PrinterType.bluetooth,
              address: deviceId,
            ),
          );
        }
      } else if (type == PrinterType.tcp) {
        final ip = _ipControllers[role]!.text;
        final port = int.tryParse(_portControllers[role]!.text) ?? 9100;
        device = PrinterDevice(
          id: '$ip:$port',
          name: 'TCP Printer',
          type: PrinterType.tcp,
          address: ip,
          port: port,
        );
      }

      if (device != null) {
        await printer.registerDevice(role, device);
        
        setState(() {
          _isConnected[role] = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${role.name} printer connected!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Connection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isConnecting[role] = false;
      });
    }
  }

  // 🆕 Method untuk disconnect printer dengan loading
  Future<void> _disconnectPrinter(PosPrinterRole role) async {
    setState(() {
      _isDisconnecting[role] = true;
    });

    try {
      await printer.unregisterDevice(role);

      setState(() {
        _isConnected[role] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔌 ${role.name} printer disconnected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Disconnect failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDisconnecting[role] = false;
      });
    }
  }

  // 🆕 Method untuk scan Bluetooth dengan loading
  Future<void> _scanBluetoothDevices() async {
    if (_isScanning) return; // guard
    setState(() {
      _isScanning = true;
      _bluetoothDevices.clear();
    });

    try {
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();
        final scanOk = statuses[Permission.bluetoothScan] == PermissionStatus.granted;
        final connectOk = statuses[Permission.bluetoothConnect] == PermissionStatus.granted;
        if (!scanOk || !connectOk) {
          if (!mounted) return;
          setState(() => _isScanning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissions required: enable Bluetooth Scan & Connect'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      // Collect devices from single scan call (plugin returns bonded list once)
      final devices = await printer.scanBluetooth().toList();
      final dedup = <String, PrinterDevice>{};
      for (final d in devices) {
        dedup[d.id] = d;
      }
      if (!mounted) return;
      setState(() {
        _bluetoothDevices = dedup.values.toList();
        _isScanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Scan failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper untuk nama bulan
  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  // 🏷️ TEMPLATE BUILT-IN - Siap pakai!
  void _testProductTemplate(PosPrinterRole role) {
    CustomStickerPrinter.printProductSticker40x30(
      printer: printer,
      role: role,
      productName: 'KOPI ARABICA',
      productCode: 'KA001', 
      price: 'Rp 35.000',
      barcodeData: '1234567890',
    );
  }

  void _testAddressTemplate(PosPrinterRole role) {
    CustomStickerPrinter.printAddressSticker58x40(
      printer: printer,
      role: role,
      receiverName: 'John Doe',
      address: 'Jl. Merdeka No. 123, Jakarta Pusat',
      phone: '081234567890',
      orderCode: 'ORD-2024-001',
    );
  }

  // 🎯 TEMPLATE MUDAH UNTUK CUSTOM - COPY & MODIFY INI
  void _myCustomSticker(PosPrinterRole role) {
    CustomStickerPrinter.printSticker(
      printer: printer,
      role: role,
      width: 40,          // mm - sesuaikan dengan media Anda
      height: 30,         // mm - sesuaikan dengan media Anda
      gap: 3,             // mm - gap antar label
      marginLeft: 8,      // mm - margin kiri
      marginTop: 2,       // mm - margin atas
      texts: [
        StickerText('CUSTOM STICKER', x: 0, y: 0, font: 3, size: 1),
        StickerText('Teks Anda', x: 0, y: 8, font: 2, size: 1),
        StickerText('Barcode dibawah', x: 0, y: 16, font: 1, size: 1),
      ],
      barcode: StickerBarcode('1234567890', x: 0, y: 20, height: 8),
    );
  }

  void _testTsplFixed(PosPrinterRole role) {
    // Fixed version dengan ukuran 40x30 sesuai media
    CustomStickerPrinter.printSticker(
      printer: printer,
      role: role,
      width: 40,          // mm - sesuaikan dengan media Anda
      height: 30,         // mm - sesuaikan dengan media Anda
      gap: 3,             // mm - gap antar label
      marginLeft: 8,      // mm - margin kiri
      marginTop: 2,       // mm - margin atas
      texts: [
        StickerText('STICKER FIXED', x: 0, y: 0, font: 3, size: 1),
        StickerText('Normal orientation', x: 0, y: 8, font: 2, size: 1),
        StickerText('40x30mm size', x: 0, y: 16, font: 1, size: 1),
      ],
      barcode: StickerBarcode('1234567890', x: 0, y: 20, height: 8),
    );
  }

  void _testCustomSize(PosPrinterRole role) {
    // Contoh dengan berbagai ukuran text dan positioning
    CustomStickerPrinter.printSticker(
      printer: printer,
      role: role,
      width: 40,
      height: 30,
      gap: 3,
      marginLeft: 8,      // margin kiri lebih kecil
      marginTop: 1,       // margin atas lebih kecil
      texts: [
        StickerText('BIG TEXT DARI LAHIR', x: 0, y: 0, font: 4, size: 2),       // text besar
        StickerText('Medium', x: 0, y: 10, font: 3, size: 1),        // text sedang
        StickerText('Small text here', x: 0, y: 18, font: 1, size: 1), // text kecil
      ],
    );
  }

  void _testMultiLine(PosPrinterRole role) {
    // Contoh dengan banyak baris text
    CustomStickerPrinter.printSticker(
      printer: printer,
      role: role,
      width: 40,
      height: 30,
      gap: 3,
      marginLeft: 1,
      marginTop: 1,
      texts: [
        StickerText('Line 1', x: 0, y: 0, font: 2),
        StickerText('Line 2', x: 0, y: 5, font: 2),
        StickerText('Line 3', x: 0, y: 10, font: 2),
        StickerText('Line 4', x: 0, y: 15, font: 2),
        StickerText('Line 5', x: 0, y: 20, font: 2),
      ],
    );
  }

    // 🆕 DEMO ALIGNMENT - Left, Center, Right
  void _testAlignment(PosPrinterRole role) {
    CustomStickerPrinter.printSticker(
      printer: printer,
      role: role,
      width: 40,
      height: 30,
      gap: 3,
      marginLeft: 2,      // margin kiri
      marginTop: 1,       // margin atas 
      marginRight: 2,     // margin kanan (NEW!)
      marginBottom: 2,    // margin bawah (NEW!)
      texts: [
        // Left aligned text (default)
        StickerText('KIRI', x: 0, y: 0, font: 2, alignment: 'left'),
        
        // Center aligned text  
        StickerText('TENGAH', x: 0, y: 7, font: 2, alignment: 'center'),
        
        // Right aligned text
        StickerText('KANAN', x: 0, y: 14, font: 2, alignment: 'right'),
        
        // Right aligned with offset (5mm dari kanan)
        StickerText('KANAN+5', x: 5, y: 21, font: 1, alignment: 'right'),
      ],
    );
  }

  // 🔥 DEMO KIRI & KANAN DALAM 1 LINE (NEW!)
  void _testLeftRightSameLine(PosPrinterRole role) {
    CustomStickerPrinter.printSticker(
      printer: printer,
      role: role,
      width: 40,
      height: 30,
      gap: 3,
      marginLeft: 2,
      marginTop: 1,
      marginRight: 2,
      marginBottom: 2,
      texts: [
        // Line 1: Kode (kiri) + Harga (kanan) - SAME Y!
        StickerText('SKU: ABC123', x: 0, y: 0, font: 2, alignment: 'left'),
        StickerText('Rp 25.', x: 10, y: 0, font: 2, alignment: 'right'),
        
        // Line 2: Nama produk (tengah)
        StickerText('KOPI ARABICA', x: 0, y: 7, font: 3, alignment: 'left'),
        
        // Line 3: Tanggal (kiri) + Batch (kanan) - SAME Y!
        StickerText('01/09/25', x: 0, y: 14, font: 1, alignment: 'left'),
        StickerText('B001', x: 0, y: 14, font: 1, alignment: 'right'),
        
        // Line 4: Made in (kiri) + QR code info (kanan) - SAME Y!
        StickerText('Made in', x: 0, y: 21, font: 1, alignment: 'left'),
        StickerText('Indonesia', x: 0, y: 21, font: 1, alignment: 'right'),
      ],
    );
  }

  // 🧾 INVOICE STYLE - Print per menu dengan format yang diminta
  void _testInvoiceStyle(PosPrinterRole role) {
    // Contoh data pesanan dengan 2 menu
    final order = Order(
      dateTime: DateTime.now(),
      customerName: 'John Does', // 🆕 Nama customer
      items: [
        OrderItem(
          name: 'Kopi Gula Aren',
          modifications: ['Less Sugar', 'Extra Topping Oreo'], // 🆕 Pisahkan dari note
          note: 'Saus Terpisah', // 🆕 Note terpisah lagi
        ),
        // OrderItem(
        //   name: 'Es Teh Manis',
        //   modifications: ['Extra Manis', 'Tambah Es', 'Gelas Besar'], // 🆕 Pisahkan dari note
        //   note: 'Minum langsung', // 🆕 Note terpisah lagi
        // ),
        // OrderItem(
        //   name: 'Es Teh Manis',
        //   modifications: ['Extra Manis', 'Tambah Es', 'Gelas Besar'], // 🆕 Pisahkan dari note
        //   note: 'Minum langsung', // 🆕 Note terpisah lagi
        // ),
        // OrderItem(
        //   name: 'Es Teh Manis',
        //   modifications: ['Extra Manis', 'Tambah Es', 'Gelas Besar'], // 🆕 Pisahkan dari note
        //   note: 'Minum langsung', // 🆕 Note terpisah lagi
        // ),
      ],
    );

    // Print menggunakan method universal
    _printOrderStickers(role, order);
  }

  void _testPosSystemData(PosPrinterRole role) {
    // Data sesuai JSON POS system
    final order = Order(
      dateTime: DateTime.now(),
      customerName: 'Customer #23', 
      items: [
        OrderItem(
          name: 'Special Rice Menu', // product.id: 21
          modifications: ['Normal Portion'], // selectedVariants (id: 26)
          note: 'Sambel Mata Spesial', // selectedAdditions (id: 14)
        ),
        OrderItem(
          name: 'Beverage Item', // product.id: 603
          modifications: [], // no variants
          note: '', // no additions
        ),
      ],
    );

    // Print menggunakan method universal yang sama
    _printOrderStickers(role, order);
  }

  // 🎯 METHOD UNIVERSAL untuk print order stickers
  Future<void> _printOrderStickers(PosPrinterRole role, Order order) async {
    // Print stickers strictly sequentially: await each job and a small pause
    // so the printer firmware has time to finish feeding and reset state.
    for (int i = 0; i < order.items.length; i++) {
      final item = order.items[i];

      await _printSingleMenuStickerOnly(role, order.dateTime, item, order.customerName);

      // Fixed pause between prints; increase if   your printer needs more time.
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  // 🧾 Helper untuk print 1 menu sticker dengan format yang diminta - PERFECT FORMAT
  Future<void> _printSingleMenuStickerOnly(PosPrinterRole role, DateTime dateTime, OrderItem item, String customerName) async {
    List<StickerText> texts = [];
    double currentY = 0; // Start from 0, margin akan ditangani oleh marginTop
    
    // 🔧 PERBAIKAN FINAL: Positioning yang benar berdasarkan cara kerja TSPL
    // TSPL REFERENCE command membuat origin point, jadi x=0 adalah RELATIVE terhadap margin
    const double xPosition = 1;   // x=0 berarti mulai dari origin (setelah margin diterapkan)
    
    // 0. Nama customer (rata kiri, font 1 ukuran 1) - 🆕 PALING ATAS
    texts.add(StickerText(customerName, x: xPosition, y: currentY, font: 1, size: 1, alignment: 'left')); 
    currentY += 4; // Spacing kecil
    
    // 1. Tanggal dan jam (rata kiri, font 1 ukuran 1)
    final dateStr = '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year} : ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    texts.add(StickerText(dateStr, x: xPosition, y: currentY, font: 1, size: 1, alignment: 'left')); 
    currentY += 4; // Spacing lebih kecil
    
    // 2. Nama menu (rata kiri, font 8 ukuran 1 - BESAR!)
    texts.add(StickerText(item.name, x: xPosition, y: currentY, font: 8, size: 1, alignment: 'left')); 
    currentY += 4; // Spacing kecil antara nama dan modification
    
    // 3. Gabung modifications dan note, font LEBIH KECIL (TSPL font 2 = terkecil yang reliable)
    List<String> allModsAndNotes = [];
    if (item.modifications.isNotEmpty) {
      allModsAndNotes.addAll(item.modifications);
    }
    if (item.note != null && item.note!.isNotEmpty) {
      allModsAndNotes.add(item.note!); // 🆕 Tambah note ke list
    }
    
    if (allModsAndNotes.isNotEmpty) {
      final allText = allModsAndNotes.join(', '); // Gabung semua dengan koma
      final wrappedMods = _wrapText(allText, 25); // max 30 char per line untuk font kecil

      for (String line in wrappedMods) {
        texts.add(StickerText(line, x: xPosition, y: currentY, font: 2, size: 1, alignment: 'left')); 
        currentY += 3; // 🆕 Spacing lebih kecil untuk font kecil
      }
    }

    // Hitung tinggi dinamis berdasarkan content yang ada - PENTING!
    final calculatedHeight = (currentY + 6).clamp(15.0, 30.0); // min 15mm, max 30mm
    
    // 🔧 PERBAIKAN FINAL: Margin yang proper sesuai cara kerja TSPL
    await _printStickerWithClear(
      role: role,
      width: 49,
      height: calculatedHeight,
      gap: 3,
      marginLeft: 2,   // 🔧 Margin kiri 2mm (proper margin untuk TSPL REFERENCE)
      marginTop: 2,    // 🔧 Margin atas 2mm (proper margin untuk TSPL REFERENCE)  
      marginRight: 1,
      marginBottom: 1,
      texts: texts,
    );
  }

  // Helper untuk wrap text otomatis
  List<String> _wrapText(String text, int maxLength) {
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

  // 🔧 PERBAIKAN: Method khusus untuk print sticker dengan clear buffer yang konsisten
  Future<void> _printStickerWithClear({
    required PosPrinterRole role,
    required double width,
    required double height,
    required double gap,
    required double marginLeft,
    required double marginTop,
    required double marginRight,
    required double marginBottom,
    required List<StickerText> texts,
    StickerBarcode? barcode,
  }) async {
    // Ensure prior work has settled, then send the sticker payload and wait
    // for the print call to finish. Adding a small post-delay helps some
    // printers finish feeding before the next job starts.
  await Future.delayed(const Duration(milliseconds: 300));
    await CustomStickerPrinter.printSticker(
      printer: printer,
      role: role,
      width: width,
      height: height,
      gap: gap,
      marginLeft: marginLeft,
      marginTop: marginTop,
      marginRight: marginRight,
      marginBottom: marginBottom,
  texts: texts,
      barcode: barcode,
    );
    // allow small settle time after the physical print
    await Future.delayed(const Duration(milliseconds: 300));
  }


  void _openDrawer(PosPrinterRole role) {
    printer.openDrawer(role);
  }

  void _testRaw(PosPrinterRole role) {
    final data = [0x1B, 0x40]; // ESC @ (initialize printer)
    printer.printRaw(role, data);
  }

  // 🔍 Diagnostic: minimal ESC/POS test to verify connection for cashier role
  void _diagnoseCashier(PosPrinterRole role) {
    final b = EscPosBuilder();
    b.text('*** DIAGNOSTIC TEST ***', bold: true, align: PosAlign.center);
    b.text('Role: ${role.name}');
    b.text('Time: ${DateTime.now().toIso8601String()}');
    b.feed(2);
    b.text('--- END ---', align: PosAlign.center);
    b.cut();
    printer.printEscPos(role, b);
    setState(() {}); // to allow log viewer refresh
  }

  // 🔄 Print full transaction (compat style) for 56mm test
  Future<void> _printCompatFinishedTransaction(PosPrinterRole role) async {
    final tx = sample56mmTransaction();
    final compatPrinter = FinishedTransactionCompatPrinter(
      is80mm: false,
      logoAssetPath: 'assets/images/akib.png', // print this logo at top
    );
    // Ensure the compat facade targets the currently selected role/device
    if (_isConnected[role] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer not connected for this role'), backgroundColor: Colors.red),
      );
      return;
    }
    await compatPrinter.printTransaction(tx, role: role);
  }

  // 🆕 BLUE THERMAL COMPAT DEMO (Receipt style, minimal migration example)
  void _compatReceiptDemo(PosPrinterRole role) {
    final compat = BlueThermalCompatPrinter.instance;
    compat.defaultRole = role; // ensure role
    // set 80mm or 58mm example
    compat.setPaper80mm(true);
    // Use prefixed names to avoid clash with Flutter's Align widget
  compat.printCustom('TOKO MAJU JAYA', Size.boldLarge.val, Align.center.val);
  compat.printCustom('Jl. Contoh No. 1', Size.medium.val, Align.center.val);
    compat.printNewLine();
    compat.printLeftRight('Kasir:', 'Andi', Size.bold.val);
    compat.printLeftRight('Tanggal:', '2025-09-14', Size.bold.val);
    compat.printLeftRight('Waktu:', '14:33', Size.bold.val);
    compat.printNewLine();
    compat.printLeftRight('2x Nasi Goreng', '40.000', Size.bold.val);
    compat.printLeftRight('1x Es Teh Manis', '8.000', Size.bold.val);
    compat.printLeftRight('Tambah Telur', '5.000', Size.medium.val);
    compat.printNewLine();
    compat.printLeftRight('Sub Total', '53.000', Size.bold.val);
    compat.printLeftRight('Pajak', '+5.300', Size.bold.val);
    compat.printLeftRight('Total', '58.300', Size.boldLarge.val);
    compat.printNewLine();
  compat.printCustom('Terima Kasih :)', Size.bold.val, Align.center.val);
    compat.paperCut();
  }

  // 🖼️ Print image (logo) di bagian paling atas struk (ESC/POS)
  Future<void> _printLogoReceipt(PosPrinterRole role) async {
    if (_isConnected[role] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect printer dulu'), backgroundColor: Colors.red),
      );
      return;
    }
    try {
      // 1. Load bytes asset
      final data = await rootBundle.load('assets/images/akib.png');
      final bytes = data.buffer.asUint8List();
      // 2. Decode image using ui.instantiateImageCodec
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      // 3. Convert to monochrome bitmap (simple threshold) and ESC/POS raster format
      final escposBytes = await _encodeImageToEscPosRaster(img, threshold: 160, maxWidth: 384);
      final builder = EscPosBuilder();
      builder.setAlign(PosAlign.center);
      builder.raster(escposBytes);
      builder.feed(1);
      builder.text('Struk Dengan Logo', align: PosAlign.center, bold: true);
      builder.text('Contoh print logo di atas', align: PosAlign.center);
      builder.feed(1);
      builder.text('Item 1   x1   10.000');
      builder.text('Item 2   x2   30.000');
      builder.feed(1);
      builder.text('TOTAL: 40.000', bold: true, align: PosAlign.right);
      builder.feed(2);
      builder.text('Terima Kasih!', align: PosAlign.center, bold: true);
      builder.cut();
      printer.printEscPos(role, builder);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal print logo: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Konversi ui.Image ke ESC/POS raster
  Future<List<int>> _encodeImageToEscPosRaster(ui.Image image, {int threshold = 160, int? maxWidth}) async {
    final width = maxWidth != null && image.width > maxWidth ? maxWidth : image.width;
    final scale = width / image.width;
    final height = (image.height * scale).round();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();
    canvas.scale(scale);
    canvas.drawImage(image, const ui.Offset(0, 0), paint);
    final picture = recorder.endRecording();
    final resized = await picture.toImage(width, height);
    final byteData = await resized.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return [];
    final pixels = byteData.buffer.asUint8List();
    // Each line: width pixels -> pack 8 pixels per byte
    final bytes = <int>[];
    // ESC/POS Raster format: GS v 0 (obsolete) or newer 0x1D 0x76 0x30 0x00
    // We use: GS v 0 m xL xH yL yH [data]
    // m=0 normal
    final xL = (width % 256);
    final xH = (width ~/ 256);
    final yL = (height % 256);
    final yH = (height ~/ 256);
    bytes.addAll([0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH]);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x += 8) {
        int b = 0;
        for (int bit = 0; bit < 8; bit++) {
          final px = x + bit;
          int color = 0xFFFFFF;
            if (px < width) {
              final idx = (y * width + px) * 4;
              final r = pixels[idx];
              final g = pixels[idx + 1];
              final bG = pixels[idx + 2];
              final lum = (0.299 * r + 0.587 * g + 0.114 * bG).round();
              if (lum < threshold) {
                color = 0x000000;
              }
            }
            b <<= 1;
            if (color == 0x000000) b |= 0x01;
        }
        bytes.add(b);
      }
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView(
        children: PosPrinterRole.values.map((role) => Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.name.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<PrinterType>(
                        value: _selectedType[role],
                        items: PrinterType.values.map((type) => 
                          DropdownMenuItem(
                            value: type,
                            child: Text(type.name),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType[role] = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 🆕 Connect/Disconnect Button dengan Loading
                    _isConnected[role] == true
                        ? ElevatedButton.icon(
                            onPressed: _isDisconnecting[role] == true ? null : () => _disconnectPrinter(role),
                            icon: _isDisconnecting[role] == true 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.bluetooth_disabled),
                            label: Text(_isDisconnecting[role] == true ? 'Disconnecting...' : 'Disconnect'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          )
                        : ElevatedButton.icon(
                            onPressed: _isConnecting[role] == true || 
                                      (_selectedType[role] == PrinterType.bluetooth && _selectedDeviceId[role] == null) ||
                                      (_selectedType[role] == PrinterType.tcp && _ipControllers[role]!.text.isEmpty)
                                ? null 
                                : () => _connectPrinter(role),
                            icon: _isConnecting[role] == true 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.bluetooth_connected),
                            label: Text(_isConnecting[role] == true ? 'Connecting...' : 'Connect'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_selectedType[role] == PrinterType.bluetooth) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isScanning ? null : _scanBluetoothDevices,
                          icon: _isScanning 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.bluetooth_searching),
                          label: Text(_isScanning ? 'Scanning...' : 'Scan Bluetooth'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select Bluetooth device'),
                    // Make safe: if selected id is no longer in the list, show null
                    value: _bluetoothDevices.any((d) => d.id == _selectedDeviceId[role])
                        ? _selectedDeviceId[role]
                        : null,
                    items: _bluetoothDevices
                        .map((device) => DropdownMenuItem(
                              value: device.id,
                              child: Text('${device.name} (${device.id})'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDeviceId[role] = value;
                      });
                    },
                  ),
                ],
                if (_selectedType[role] == PrinterType.tcp) ...[
                  TextField(
                    controller: _ipControllers[role],
                    decoration: const InputDecoration(labelText: 'IP Address'),
                  ),
                  TextField(
                    controller: _portControllers[role],
                    decoration: const InputDecoration(labelText: 'Port'),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('🏷️ TEMPLATE STICKER SIAP PAKAI:', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: () => _testProductTemplate(role),
                      child: const Text('Product 40x30'),
                    ),
                    ElevatedButton(
                      onPressed: () => _testAddressTemplate(role),
                      child: const Text('Address 58x40'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('🎯 CUSTOM STICKER TESTS:', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: () => _myCustomSticker(role),
                      child: const Text('My Custom'),
                    ),
                    ElevatedButton(
                      onPressed: () => _testTsplFixed(role),
                      child: const Text('Fixed 40x30'),
                    ),
                    ElevatedButton(
                      onPressed: () => _testCustomSize(role),
                      child: const Text('Different Sizes'),
                    ),
                    ElevatedButton(
                      onPressed: () => _testMultiLine(role),
                      child: const Text('Multi Line'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('🧾 INVOICE STYLE:', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                // Button ini sudah ada di bagian "KIRI-KANAN SAME LINE" 
                const SizedBox(height: 8),
                const Text('🆕 ALIGNMENT & MARGINS (NEW!):', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: () => _testAlignment(role),
                      child: const Text('Left|Center|Right'),
                    ),
                    // ElevatedButton(
                    //   onPressed: () => _testFullMargins(role),
                    //   child: const Text('Full Margins'),
                    // ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('� LEVEL 1: SUPER SIMPLE (ONE-LINER):', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: () => _testLevel1SimpleInvoice(role),
                      child: const Text('Simple Invoice'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('⚙️ LEVEL 2: TEMPLATE WITH OPTIONS:', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: () => _testLevel2TemplateInvoice(role),
                      child: const Text('Template Invoice'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('👨‍🍳 LEVEL 3: MULTI-MENU RESTAURANT:', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: () => _testLevel3RestaurantOrder(role),
                      child: const Text('Restaurant Order'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('💪 LEVEL 4: FULL CUSTOM (ADVANCED):', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: () => _testLeftRightSameLine(role),
                      child: const Text('Kiri & Kanan'),
                    ),
                    ElevatedButton(
                      onPressed: () => _testInvoiceStyle(role),
                      child: const Text('Invoice Style'),
                    ),
                    ElevatedButton(
                      onPressed: () => _testPosSystemData(role),
                      child: const Text('POS System Data'),
                    ),
                    ElevatedButton(
                      onPressed: () => _testComplexPosOrder(role),
                      child: const Text('Complex POS Order'),
                    ),
                    ElevatedButton(
                      onPressed: () => _diagnosticTsplTest(role),
                      child: const Text('Diagnostic TSPL'),
                    ),
                    ElevatedButton(
                      onPressed: () => _printBeverageStickers(role),
                      child: const Text('Beverage Stickers'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('⚙️ OTHER FUNCTIONS:', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: () => _openDrawer(role),
                      child: const Text('Open Drawer'),
                    ),
                    ElevatedButton(
                      onPressed: () => _printLogoReceipt(role),
                      child: const Text('Logo Receipt'),
                    ),
                    ElevatedButton(
                      onPressed: () => _testRaw(role),
                      child: const Text('Test Raw'),
                    ),
                    ElevatedButton(
                      onPressed: () => _compatReceiptDemo(role),
                      child: const Text('Compat Receipt'),
                    ),
                    ElevatedButton(
                      onPressed: () => _printCompatFinishedTransaction(role),
                      child: const Text('Compat Full Tx 56mm'),
                    ),
                    ElevatedButton(
                      onPressed: () => _diagnoseCashier(role),
                      child: const Text('Diagnostic Receipt'),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _showLogs = !_showLogs),
                      child: Text(_showLogs ? 'Hide Logs' : 'Show Logs'),
                    ),
                  ],
                ),
                if (_showLogs) ...[
                  const SizedBox(height: 12),
                  Text('Logs (${printer.logs.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.all(8),
                    color: Colors.black12,
                    child: SingleChildScrollView(
                      child: Text(
                        printer.logs.map((e) => '[${e.level.name}] ${e.message}').join('\n'),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _ipControllers.values) {
      controller.dispose();
    }
    for (var controller in _portControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  // 🚀 LEVEL 1: Super Simple Invoice (ONE-LINER)
  void _testLevel1SimpleInvoice(PosPrinterRole role) {
    CustomStickerPrinter.printInvoice(
      printer: printer,
      role: role,
      customer: 'John Doe',
      menu: 'Nasi Goreng Spesial',
      details: 'Extra Pedas, Tanpa Bawang, Jangan asin',
    );
  }

  // ⚙️ LEVEL 2: Template with Options
  void _testLevel2TemplateInvoice(PosPrinterRole role) {
    CustomStickerPrinter.printInvoiceSticker(
      printer: printer,
      role: role,
      customerName: 'John Doe',
      menuName: 'Nasi Goreng Spesial',
      modifications: ['Extra Pedas', 'Tanpa Bawang'],
      note: 'Jangan terlalu asin',
      stickerSize: StickerSize.mm58x40,
      fontSize: FontSize.large,
    );
  }

  // 👨‍🍳 LEVEL 3: Multi-Menu Restaurant Style  
  void _testLevel3RestaurantOrder(PosPrinterRole role) {
    List<MenuItem> menuItems = [
      MenuItem('Nasi Goreng Spesial', ['Extra Pedas', 'Tanpa Bawang'], 'Jangan terlalu asin'),
      MenuItem('Es Teh Manis', ['Gelas Besar'], 'Banyak es'),
    ];

    CustomStickerPrinter.printRestaurantOrder(
      printer: printer,
      role: role,
      customerName: 'John Doe',
      menuItems: menuItems,
    );
  }

    // 🚀 LEVEL 1: Super Simple Invoice (ONE-LINER)

  // 🏷️ Helper untuk print 1 transaction sticker dengan format POS
  Future<void> _printPosTransactionSticker(PosPrinterRole role, PosTransaction transaction, String customerName) async {
    List<StickerText> texts = [];
    double currentY = 0; // Start from 0, margin akan ditangani oleh marginTop
    
    // 1. Customer name (paling atas)
    texts.add(StickerText(customerName, x: 0, y: currentY, font: 1, size: 1, alignment: 'left')); // x=0 untuk konsisten dengan margin
    currentY += 4;
    
    // 2. Tanggal dan jam (real time)
    final now = DateTime.now();
    final dateStr = '${now.day} ${_getMonthName(now.month)} ${now.year} : ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    texts.add(StickerText(dateStr, x: 0, y: currentY, font: 1, size: 1, alignment: 'left')); // x=0 untuk konsisten dengan margin
    currentY += 4;
    
    // 3. Nama produk (font besar)
    String productName = transaction.product.name;
    if (transaction.quantity > 1) {
      productName = '${transaction.quantity}x $productName';
    }
    texts.add(StickerText(productName, x: 0, y: currentY, font: 8, size: 1, alignment: 'left')); // x=0 untuk konsisten dengan margin
    currentY += 4;
    
    // 4. Variants + Additions + Notes (gabung semua)
    List<String> allModifications = [];
    
    // Tambahkan variants
    for (final variant in transaction.selectedVariants) {
      // Sticker: no price display
      allModifications.add(variant.name);
    }
    
    // Tambahkan additions
    for (final addition in transaction.selectedAdditions) {
      // Sticker: no price display
      allModifications.add(addition.name);
    }
    
    // Tambahkan notes jika ada
    if (transaction.notes.isNotEmpty) {
      allModifications.add(transaction.notes);
    }
    
    // Print modifications jika ada
    if (allModifications.isNotEmpty) {
      final allText = allModifications.join(', ');
      final wrappedLines = _wrapText(allText, 30);
      
      for (String line in wrappedLines) {
        texts.add(StickerText(line, x: 0, y: currentY, font: 2, size: 1, alignment: 'left')); // x=0 untuk konsisten dengan margin
        currentY += 3;
      }
    }

    // Hitung tinggi dinamis
    final calculatedHeight = (currentY + 6).clamp(15.0, 30.0);
    
    // 🔧 PERBAIKAN FINAL: Margin yang IDENTIK dengan method lain
    await _printStickerWithClear(
      role: role,
      width: 40,
      height: calculatedHeight,
      gap: 3,
      marginLeft: 2,   // 🔧 Margin kiri 2mm (IDENTIK dengan _printSingleMenuStickerOnly)
      marginTop: 2,    // 🔧 Margin atas 2mm (IDENTIK dengan _printSingleMenuStickerOnly)
      marginRight: 1,
      marginBottom: 1,
      texts: texts,
    );
  }


  // 🍽️ COMPLEX POS ORDER - Sesuai dengan JSON variant & addition
  Future<void> _testComplexPosOrder(PosPrinterRole role) async {
    // Data lebih complex berdasarkan struktur JSON yang diberikan
    final List<PosTransaction> complexTransactions = [
      // Transaction 1: Minuman dengan multiple variants
      PosTransaction(
        product: Product(
          id: 101,
          name: 'Iced Coffee Latte',
          price: 25000,
          totalPrice: '35000',
          discountProduct: '0.0',
        ),
        selectedVariants: [
          VariantOption(id: 9, name: 'Large', price: 5000), // Tipe Gelas
          VariantOption(id: 11, name: 'Less Sugar', price: 0), // Sugar
          VariantOption(id: 13, name: 'Double Shot', price: 5000), // Topping
        ],
        selectedAdditions: [],
        notes: 'Extra hot, no ice',
        quantity: 2,
      ),
      // Transaction 2: Nasi dengan variant dan addition
      PosTransaction(
        product: Product(
          id: 201,
          name: 'Nasi Ayam Bakar',
          price: 32000,
          totalPrice: '47000',
          discountProduct: '0.0',
        ),
        selectedVariants: [
          VariantOption(id: 28, name: 'Large', price: 8000), // Porsi Large
        ],
        selectedAdditions: [
          AdditionOption(id: 14, name: 'Sambel Mata Spesial', price: '4000'),
          AdditionOption(id: 16, name: 'Telur Dadar', price: '3000'),
        ],
        notes: 'Nasi terpisah, sambel banyak',
        quantity: 1,
      ),
      // Transaction 3: Simple drink
      PosTransaction(
        product: Product(
          id: 301,
          name: 'Es Teh Manis',
          price: 8000,
          totalPrice: '8000',
          discountProduct: '0.0',
        ),
        selectedVariants: [
          VariantOption(id: 8, name: 'Reguler', price: 0), // Gelas Reguler
          VariantOption(id: 10, name: 'Normal Sugar', price: 0), // Normal Sugar
        ],
        selectedAdditions: [
          AdditionOption(id: 14, name: 'Jelly', price: '5000'),
        ],
        notes: '',
        quantity: 3,
      ),
    ];

    // Info customer dan order
    const String customerName = 'Budi Santoso'; // Real customer name
    
    // Print each transaction strictly sequentially and await completion.
    for (int i = 0; i < complexTransactions.length; i++) {
      final transaction = complexTransactions[i];

      await _printPosTransactionSticker(role, transaction, customerName);

      // small fixed pause between stamps
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  // 🔍 Diagnostic TSPL test to help reproduce duplicate/offset issues
  void _diagnosticTsplTest(PosPrinterRole role) {
    final texts = [
      StickerText('DIAG: START', x: 0, y: 0, font: 2, size: 1),
      StickerText('Timestamp: ${DateTime.now().toIso8601String()}', x: 0, y: 6, font: 1, size: 1),
    ];

    final tspl = CustomStickerPrinter.createSticker(
      widthMm: 40,
      heightMm: 20,
      gapMm: 3,
      texts: texts,
      marginLeft: 2,
      marginTop: 2,
    );

  // Log the TSPL payload so we can inspect per-print commands in Logcat
  // and ensure CLS/PRINT are present per sticker.
  // ignore: avoid_print
  print('DIAGNOSTIC TSPL:\n$tspl');

  // Send directly so we can observe manager logs for enqueue/write
  printer.printTspl(role, tspl);
  }

  // 🥤 Print 3 beverage stickers (one by one) using BeverageStickerPrinter
  Future<void> _printBeverageStickers(PosPrinterRole role) async {
    // Use the same full transaction source so cashier & sticker outputs stay in sync.
    final tx = sample56mmTransaction();
    // Filter only beverage lines (heuristic in demo data helper)
    final beverageLines = tx.transactions.where(isBeverageLine).toList();
    if (beverageLines.isEmpty) {
      // ignore: avoid_print
      print('No beverage lines detected for sticker printing');
      return;
    }
    final bevPrinter = BeverageStickerPrinter(customerName: tx.customerName);
    await bevPrinter.printBeverageLines(beverageLines, role: role);
  }

}
