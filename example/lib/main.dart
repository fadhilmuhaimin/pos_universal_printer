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
                    ElevatedButton(
                      onPressed: () => _printBeverageStickers(role),
                      child: const Text('beverages'),
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
  final bevPrinter = BeverageStickerPrinter(
    customerName: tx.customerName,
    detailsCharBudget: 100, // test: allow more chars to see wrapping behavior
    detailsJoinSeparator: ', ', // add comma separator between items
    detailsWrapWidthChars: 24, // reduce by 1 char to avoid right edge
    detailsMaxLines: 3, // limit details block to maximum 3 lines
    autoGrowHeight: true, // show all trimmed content across lines
    debugLog: true, // enable debug to see char count in console
  );
    await bevPrinter.printBeverageLines(beverageLines, role: role);
  }

}
