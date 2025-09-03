import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_universal_printer/pos_universal_printer.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Universal Printer Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PosUniversalPrinter printer = PosUniversalPrinter.instance;

  final Map<PosPrinterRole, PrinterType?> _selectedType = {
    PosPrinterRole.cashier: null,
    PosPrinterRole.kitchen: null,
    PosPrinterRole.sticker: null,
  };
  final Map<PosPrinterRole, PrinterDevice?> _selectedDevice = {
    PosPrinterRole.cashier: null,
    PosPrinterRole.kitchen: null,
    PosPrinterRole.sticker: null,
  };

  // Controllers for IP/port inputs
  final Map<PosPrinterRole, TextEditingController> _ipControllers = {
    PosPrinterRole.cashier: TextEditingController(),
    PosPrinterRole.kitchen: TextEditingController(),
    PosPrinterRole.sticker: TextEditingController(),
  };
  final Map<PosPrinterRole, TextEditingController> _portControllers = {
    PosPrinterRole.cashier: TextEditingController(text: '9100'),
    PosPrinterRole.kitchen: TextEditingController(text: '9100'),
    PosPrinterRole.sticker: TextEditingController(text: '9100'),
  };

  // Bluetooth scan results
  List<PrinterDevice> _bluetoothDevices = [];

  Timer? _logTimer;

  @override
  void initState() {
    super.initState();
    // Periodically refresh logs
    _logTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    for (final c in _ipControllers.values) {
      c.dispose();
    }
    for (final c in _portControllers.values) {
      c.dispose();
    }
    _logTimer?.cancel();
    printer.dispose();
    super.dispose();
  }

  Future<void> _ensureBtPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  Future<void> _scanBluetooth() async {
    await _ensureBtPermissions();
    final results = await printer.scanBluetooth().toList();
    setState(() {
      _bluetoothDevices = results;
    });
  }

  Future<void> _register(PosPrinterRole role) async {
    final type = _selectedType[role];
    if (type == null) return;
    PrinterDevice device;
    if (type == PrinterType.bluetooth) {
      await _ensureBtPermissions();
      final selected = _selectedDevice[role];
      if (selected == null) return;
      device = selected;
    } else {
      final ip = _ipControllers[role]!.text.trim();
      final portStr = _portControllers[role]!.text.trim();
      final port = int.tryParse(portStr) ?? 9100;
      device = PrinterDevice(
        id: '$ip:$port',
        name: ip,
        type: PrinterType.tcp,
        address: ip,
        port: port,
      );
    }
    await printer.registerDevice(role, device);
    setState(() {});
  }

  void _testEsc(PosPrinterRole role) {
    final builder = EscPosBuilder();
    builder.text('TEST ESC/POS', bold: true, align: PosAlign.center);
    builder.text('Printer role: ${role.name}');
    builder.feed(2);
    builder.cut();
    printer.printEscPos(role, builder);
  }

  void _testTspl(PosPrinterRole role) {
    final cmds = TsplBuilder.sampleLabel58x40();
    printer.printTspl(role, cmds);
  }

  void _testCpcl(PosPrinterRole role) {
    final cmds = CpclBuilder.sampleLabel();
    printer.printCpcl(role, cmds);
  }

  void _openDrawer(PosPrinterRole role) {
    printer.openDrawer(role);
  }

  void _stressTest(PosPrinterRole role) {
    final builder = EscPosBuilder();
    builder.text('Stress', align: PosAlign.center);
    builder.cut();
    final data = builder.build();
    for (int i = 0; i < 100; i++) {
      printer.printRaw(role, data);
    }
  }

  Widget _buildRoleTile(PosPrinterRole role) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role.name.toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Type: '),
                DropdownButton<PrinterType>(
                  hint: const Text('Pilih'),
                  value: _selectedType[role],
                  items: const [
                    DropdownMenuItem(
                      value: PrinterType.bluetooth,
                      child: Text('Bluetooth'),
                    ),
                    DropdownMenuItem(
                      value: PrinterType.tcp,
                      child: Text('TCP/IP'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType[role] = value;
                    });
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _register(role),
                  child: const Text('Simpan'),
                ),
              ],
            ),
            if (_selectedType[role] == PrinterType.bluetooth) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _scanBluetooth,
                    child: const Text('Scan'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<PrinterDevice>(
                      isExpanded: true,
                      hint: const Text('Pilih Perangkat'),
                      value: _selectedDevice[role],
                      items: _bluetoothDevices
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('${e.name} (${e.address})'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDevice[role] = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
            if (_selectedType[role] == PrinterType.tcp) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _ipControllers[role],
                decoration: const InputDecoration(labelText: 'IP Address'),
              ),
              TextField(
                controller: _portControllers[role],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Port'),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _testEsc(role),
                  child: const Text('Test ESC/POS'),
                ),
                ElevatedButton(
                  onPressed: () => _testTspl(role),
                  child: const Text('Test TSPL'),
                ),
                ElevatedButton(
                  onPressed: () => _testCpcl(role),
                  child: const Text('Test CPCL'),
                ),
                ElevatedButton(
                  onPressed: () => _openDrawer(role),
                  child: const Text('Open Drawer'),
                ),
                ElevatedButton(
                  onPressed: () => _stressTest(role),
                  child: const Text('Stress 100x'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POS Universal Printer Demo')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildRoleTile(PosPrinterRole.cashier),
            _buildRoleTile(PosPrinterRole.kitchen),
            _buildRoleTile(PosPrinterRole.sticker),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: printer.logs.length,
                itemBuilder: (context, index) {
                  final entry = printer.logs[index];
                  return Text(entry.toString());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
