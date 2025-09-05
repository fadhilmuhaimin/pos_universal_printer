import 'package:flutter/material.dart';
import 'package:pos_universal_printer/pos_universal_printer.dart';

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
    setState(() {
      _isScanning = true;
      _bluetoothDevices.clear();
    });

    try {
      await for (PrinterDevice device in printer.scanBluetooth()) {
        if (mounted) {
          setState(() {
            _bluetoothDevices.add(device);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Scan failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
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
      ],
    );

    // Print sticker untuk setiap menu (1 menu = 1 sticker)
    for (int i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      _printSingleMenuStickerOnly(role, order.dateTime, item, order.customerName); // 🆕 Pass customer name
    }
  }

  // 🧾 Helper untuk print 1 menu sticker dengan format yang diminta
  void _printSingleMenuStickerOnly(PosPrinterRole role, DateTime dateTime, OrderItem item, String customerName) {
    List<StickerText> texts = [];
    double currentY = 0;
    
    // 0. Nama customer (rata kiri, font 1 ukuran 1) - 🆕 PALING ATAS
    texts.add(StickerText(customerName, x: 12, y: currentY, font: 1, size: 1, alignment: 'left'));
    currentY += 4; // Spacing kecil
    
    // 1. Tanggal dan jam (rata kiri, font 1 ukuran 1)
    final dateStr = '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year} : ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    texts.add(StickerText(dateStr, x: 12, y: currentY, font: 1, size: 1, alignment: 'left'));
    currentY += 4; // Spacing lebih kecil
    
    // 2. Nama menu (rata kiri, font 1 ukuran 1 - SAMA dengan modification)
    texts.add(StickerText(item.name, x: 12, y: currentY, font: 8, size: 1, alignment: 'left'));
    currentY += 4; // Spacing kecil antara nama dan modification
    
    // 3. Gabung modifications dan note, font LEBIH KECIL (TSPL font 1 = terkecil)
    List<String> allModsAndNotes = [];
    if (item.modifications.isNotEmpty) {
      allModsAndNotes.addAll(item.modifications);
    }
    if (item.note != null && item.note!.isNotEmpty) {
      allModsAndNotes.add(item.note!); // 🆕 Tambah note ke list
    }
    
    if (allModsAndNotes.isNotEmpty) {
      final allText = allModsAndNotes.join(', '); // Gabung semua dengan koma
      final wrappedMods = _wrapText(allText, 30); // max 30 char per line untuk font kecil

      for (String line in wrappedMods) {
        texts.add(StickerText(line, x: 12, y: currentY, font: 2, size: 1, alignment: 'left')); // 🔧 Font 1 = terkecil yang reliable
        currentY += 3; // 🆕 Spacing lebih kecil untuk font kecil
      }
    }

    // Hitung tinggi dinamis berdasarkan content yang ada - PENTING!
    final calculatedHeight = (currentY + 6).clamp(15.0, 30.0); // min 15mm, max 30mm
    
    CustomStickerPrinter.printSticker(
      printer: printer,
      role: role,
      width: 40,  // lebar 40mm sesuai request
      height: calculatedHeight, // tinggi dinamis, bukan fixed 30mm
      gap: 3,
      marginLeft: 1,
      marginTop: 1,
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


  void _openDrawer(PosPrinterRole role) {
    printer.openDrawer(role);
  }

  void _testRaw(PosPrinterRole role) {
    final data = [0x1B, 0x40]; // ESC @ (initialize printer)
    printer.printRaw(role, data);
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
                    value: _selectedDeviceId[role],
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
                const Text('🔥 KIRI-KANAN SAME LINE (HOT!):', 
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
                      onPressed: () => _testRaw(role),
                      child: const Text('Test Raw'),
                    ),
                  ],
                ),
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

}
