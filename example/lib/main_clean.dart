import 'package:flutter/material.dart';
import 'package:pos_universal_printer/pos_universal_printer.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeMaps();
  }

  void _initializeMaps() {
    for (PosPrinterRole role in PosPrinterRole.values) {
      _selectedType[role] = PrinterType.bluetooth;
      _selectedDeviceId[role] = null;
      _ipControllers[role] = TextEditingController(text: '192.168.1.100');
      _portControllers[role] = TextEditingController(text: '9100');
    }
  }

  void _register(PosPrinterRole role) async {
    final type = _selectedType[role]!;
    final deviceId = _selectedDeviceId[role];
    final ip = _ipControllers[role]!.text;
    final port = int.tryParse(_portControllers[role]!.text) ?? 9100;

    PrinterDevice? device;
    if (type == PrinterType.bluetooth && deviceId != null) {
      device = _bluetoothDevices.firstWhere((d) => d.id == deviceId);
    } else if (type == PrinterType.tcp) {
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
    }
  }

  void _scanBluetooth() async {
    try {
      final devices = <PrinterDevice>[];
      await for (final device in printer.scanBluetooth()) {
        devices.add(device);
      }
      setState(() {
        _bluetoothDevices = devices;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bluetooth scan failed: $e')),
      );
    }
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
                    ElevatedButton(
                      onPressed: () => _register(role),
                      child: const Text('Register'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_selectedType[role] == PrinterType.bluetooth) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _scanBluetooth,
                          child: const Text('Scan Bluetooth'),
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
