import 'package:flutter/material.dart' hide Align; // hide Flutter Align to use compat Align enum
import 'package:pos_universal_printer/pos_universal_printer.dart';
import 'demo_transaction_data.dart';
import 'finished_transaction_compat.dart';
import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
// removed unused imports



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
    // Listen to connection events and auto-update indicator
    printer.connectionEvents.listen((evt) {
      setState(() {
        _isConnected[evt.role] = evt.status == ConnectionStatus.connected;
      });
    });
    // Ensure Bluetooth permissions (Android 12+) so restore/scan can work
    _ensureBluetoothPermissions().then((_) {
      // Restore last selections and auto-reconnect if possible, then resync
      return _restoreSelectionsAndReconnect();
    }).whenComplete(() {
      // Resync native sockets (useful after hot reload)
      printer.resyncConnections();
    });
    // Auto-populate bonded Bluetooth devices so dropdown has items on first load
    _scanBluetoothDevices();
  }

  Future<void> _ensureBluetoothPermissions() async {
    if (!Platform.isAndroid) return;
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    final scanOk = statuses[Permission.bluetoothScan] == PermissionStatus.granted;
    final connectOk = statuses[Permission.bluetoothConnect] == PermissionStatus.granted;
    if (!scanOk || !connectOk) {
      // Optional: surface a message; scanning/connect will guard too.
    }
  }

  // Flutter hot reload calls reassemble() (not initState). Make sure
  // native sockets and UI state are reconciled to avoid ghost connections.
  @override
  void reassemble() {
    super.reassemble();
    // Option B: preserve connection if native sockets still alive.
    // 1) Resync from native
    printer.resyncConnections().then((_) {
      // 2) Hydrate UI selections from registered devices
      final regs = printer.registeredDevices;
      setState(() {
        for (var role in PosPrinterRole.values) {
          final dev = regs[role];
          if (dev != null) {
            _selectedType[role] = dev.type;
            if (dev.type == PrinterType.bluetooth) {
              _selectedDeviceId[role] = dev.address ?? dev.id;
            } else if (dev.type == PrinterType.tcp) {
              _ipControllers[role]?.text = dev.address ?? '';
              _portControllers[role]?.text = dev.port?.toString() ?? '9100';
            }
          }
          _isConnected[role] = printer.isRoleConnected(role);
        }
      });
    });
  }

  Future<void> _restoreSelectionsAndReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    for (var role in PosPrinterRole.values) {
      final typeStr = prefs.getString('role_${role.name}_type');
      final addr = prefs.getString('role_${role.name}_address');
      final ip = prefs.getString('role_${role.name}_ip');
      final port = prefs.getInt('role_${role.name}_port');
      if (typeStr == null) continue;
      final type = typeStr == 'tcp' ? PrinterType.tcp : PrinterType.bluetooth;
      setState(() {
        _selectedType[role] = type;
        if (type == PrinterType.bluetooth) {
          _selectedDeviceId[role] = addr;
        } else {
          _ipControllers[role]?.text = ip ?? '';
          _portControllers[role]?.text = (port ?? 9100).toString();
        }
      });
      // try register and enable auto-reconnect
      PrinterDevice? device;
      if (type == PrinterType.bluetooth && addr != null && addr.isNotEmpty) {
        device = PrinterDevice(id: addr, name: 'Restored BT', type: type, address: addr);
      } else if (type == PrinterType.tcp && ip != null && ip.isNotEmpty) {
        final p = port ?? 9100;
        device = PrinterDevice(id: '$ip:$p', name: 'Restored TCP', type: type, address: ip, port: p);
      }
      if (device != null) {
        try {
          await printer.registerDevice(role, device);
          printer.setAutoReconnect(role, true);
          // Do not mark connected eagerly; rely on connectionEvents/resync for truth
        } catch (_) {
          // ignore failing restoration
        }
      }
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
        // Enable auto reconnect for this role
        printer.setAutoReconnect(role, true);
        // Persist selection
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role_${role.name}_type',
            device.type == PrinterType.tcp ? 'tcp' : 'bluetooth');
        if (device.type == PrinterType.bluetooth) {
          await prefs.setString('role_${role.name}_address', device.address ?? device.id);
          await prefs.remove('role_${role.name}_ip');
          await prefs.remove('role_${role.name}_port');
        } else {
          if (device.address != null) {
            await prefs.setString('role_${role.name}_ip', device.address!);
          }
          await prefs.setInt('role_${role.name}_port', device.port ?? 9100);
          await prefs.remove('role_${role.name}_address');
        }
        
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
      // Disable auto-reconnect for this role first to prevent immediate re-connect
      printer.setAutoReconnect(role, false);
      // Capture the address we think is connected so we can target-disconnect
      final savedAddress = _selectedType[role] == PrinterType.bluetooth
          ? _selectedDeviceId[role]
          : null;
      await printer.unregisterDevice(role);
      // Extra safety: target-close this device (avoid disconnecting other roles)
      if (savedAddress != null && savedAddress.isNotEmpty) {
        await printer.disconnectBluetoothAddress(savedAddress);
      }
      await printer.resyncConnections();
      await printer.resyncConnections();
  // Clear persisted selection for this role (only state, keep type)
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('role_${role.name}_address');
  await prefs.remove('role_${role.name}_ip');
  await prefs.remove('role_${role.name}_port');

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
  // removed unused _compatReceiptDemo


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
                    IconButton(
                      tooltip: 'Force disconnect all (hot reload recovery)',
                      icon: const Icon(Icons.power_settings_new),
                      onPressed: () async {
                        await printer.forceDisconnectAllBluetooth();
                        await printer.resyncConnections();
                      },
                    ),
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
                    // live status dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isConnected[role] == true ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
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
                        : (_selectedDeviceId[role] == null ? null : _selectedDeviceId[role]),
                    items: () {
                      final items = _bluetoothDevices
                          .map((device) => DropdownMenuItem(
                                value: device.id,
                                child: Text('${device.name} (${device.id})'),
                              ))
                          .toList();
                      final sel = _selectedDeviceId[role];
                      if (sel != null && !_bluetoothDevices.any((d) => d.id == sel)) {
                        // Include a placeholder for the saved device so it's visible/selectable
                        items.insert(
                          0,
                          DropdownMenuItem(
                            value: sel,
                            child: Text('Saved device ($sel)'),
                          ),
                        );
                      }
                      return items;
                    }(),
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
