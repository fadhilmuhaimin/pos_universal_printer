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

  void _testTspl(PosPrinterRole role) {
    // Satu label 40x30 mm (PRINT 1), orientasi sama seperti "Label 58x40",
    // margin kiri/atas seperti sample (mulai dari kiri-atas), isi penuh baris 'A'.

    // 1) Media setup (203 dpi -> 8 dots/mm). 300 dpi -> 12 dots/mm.
    const int dotsPerMm = 8;
    const int widthMm = 40;
    const int heightMm = 30;

    // 2) Margin kiri/atas mirip sample (≈20 dot ≈2.5 mm)
    const int leftMargin = 20;
    const int topMargin = 20;
    const int rightMargin = 0;
    const int bottomMargin = 0;

    // 3) Area dalam (dot)
    final int widthDots = widthMm * dotsPerMm; // 320
    final int heightDots = heightMm * dotsPerMm; // 240
    final int innerWidth = widthDots - leftMargin - rightMargin;
    final int innerHeight = heightDots - topMargin - bottomMargin;

    // 4) Font 3 @1x ≈ 24x24 dot/karakter
    const int charW = 24;
    const int charH = 24;
    final int columns = (innerWidth ~/ charW).clamp(1, 999);
    final int rows = (innerHeight ~/ charH).clamp(1, 999);
    final String line = 'A' * columns;

    // 5) Rangkai TSPL (tanpa builder sample)
    final sb = StringBuffer();
    sb.writeln('SIZE $widthMm mm, $heightMm mm');
    sb.writeln('GAP 3 mm, 0 mm'); // sesuaikan 2–4 mm + kalibrasi media
    sb.writeln('DIRECTION 1'); // ikuti orientasi Label 58x40
    sb.writeln('REFERENCE $leftMargin,$topMargin');
    sb.writeln('SPEED 2');
    sb.writeln('DENSITY 12');
    sb.writeln('CLS');

    // 6) Cetak baris 'A' dari atas ke bawah (tidak terbalik)
    for (int r = 0; r < rows; r++) {
      final int y = r * charH;
      sb.writeln('TEXT 0,$y,"3",0,1,1,"$line"');
    }
    sb.writeln('PRINT 1'); // pastikan hanya 1 lembar

    printer.printTspl(role, sb.toString());
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
