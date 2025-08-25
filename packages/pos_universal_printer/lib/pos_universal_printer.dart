library pos_universal_printer;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'src/core/manager.dart';
import 'src/core/logging.dart';
import 'src/net/tcp_client.dart';
import 'src/core/queue.dart';
import 'src/protocols/escpos/builder.dart';
import 'src/protocols/tspl/builder.dart';
import 'src/protocols/cpcl/builder.dart';
import 'src/renderer/receipt_renderer.dart';

/// Roles in a point‑of‑sale system. Each role can be mapped to a specific
/// printer device so that receipts are routed correctly (e.g. cashier
/// prints to the receipt printer, kitchen prints orders, sticker prints
/// labels).
enum PosPrinterRole { cashier, kitchen, sticker }

/// Types of printers supported by this plugin.
enum PrinterType { bluetooth, tcp }

/// Represents a printer discovered via scanning or configured manually.
class PrinterDevice {
  PrinterDevice({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.port,
  });

  /// Unique identifier for the device. For bluetooth this is the MAC
  /// address, for TCP this is host:port.
  final String id;

  /// Human readable name.
  final String name;

  /// Connection type.
  final PrinterType type;

  /// Device address (MAC address or IP).
  final String? address;

  /// Port number for TCP printers.
  final int? port;
}

/// Public API for pos_universal_printer. Wraps platform channels,
/// managers and builders to provide a simple high level interface.
class PosUniversalPrinter {
  PosUniversalPrinter._() {
    _manager = PosPrinterManager(_channel, _logger);
  }

  static final PosUniversalPrinter instance = PosUniversalPrinter._();

  static const MethodChannel _channel = MethodChannel('pos_universal_printer');
  final Logger _logger = Logger();
  late final PosPrinterManager _manager;

  /// Returns a copy of the current logs.
  List<LogEntry> get logs => _logger.entries;

  /// Stream of log updates. Each time a log entry is added the entire
  /// list is emitted. Consumers can listen to this to update UI.
  final StreamController<List<LogEntry>> _logController =
      StreamController<List<LogEntry>>.broadcast();

  /// Scans for Bluetooth printers on Android. Returns a stream of
  /// discovered devices. On iOS this will emit nothing because
  /// Bluetooth SPP is not supported【229364017025404†L45-L58】.
  Stream<PrinterDevice> scanBluetooth() async* {
    try {
      final List<dynamic>? results =
          await _channel.invokeMethod<List<dynamic>>('scanBluetooth');
      if (results != null) {
        for (final item in results) {
          final map = Map<String, dynamic>.from(item as Map);
          final name = map['name'] as String? ?? 'Unknown';
          final address = map['address'] as String?;
          final id = address ?? name;
          yield PrinterDevice(
              id: id,
              name: name,
              type: PrinterType.bluetooth,
              address: address);
        }
      }
    } catch (e) {
      _logger.add(LogLevel.error, 'Bluetooth scan error: $e');
    }
  }

  /// Registers [device] for [role] and connects to it. For TCP devices
  /// you must set [device.address] and [device.port]. For Bluetooth
  /// devices scanning must provide the address.
  Future<void> registerDevice(PosPrinterRole role, PrinterDevice device) async {
    await _manager.setDevice(role, device);
  }

  /// Unregisters the printer associated with [role] and closes its
  /// connection.
  Future<void> unregisterDevice(PosPrinterRole role) async {
    await _manager.removeDevice(role);
  }

  /// Sends raw bytes to the printer associated with [role]. Use this
  /// method if you already have encoded ESC/POS, TSPL or CPCL data.
  void printRaw(PosPrinterRole role, List<int> data) {
    _manager.send(role, data);
  }

  /// Builds an ESC/POS receipt using [builder] and prints it on the
  /// printer configured for [role].
  void printEscPos(PosPrinterRole role, EscPosBuilder builder) {
    final bytes = builder.build();
    printRaw(role, bytes);
  }

  /// Sends a TSPL command string directly to the printer configured for
  /// [role]. Converts the string to ASCII before sending.
  void printTspl(PosPrinterRole role, String commands) {
    final bytes = ascii.encode(commands);
    printRaw(role, bytes);
  }

  /// Sends a CPCL command string directly to the printer configured for
  /// [role]. Converts the string to ASCII before sending.
  void printCpcl(PosPrinterRole role, String commands) {
    final bytes = ascii.encode(commands);
    printRaw(role, bytes);
  }

  /// Opens the cash drawer for the printer configured for [role]. The
  /// default pulse values correspond to m=0, t1=25, t2=250 as per
  /// specification.
  void openDrawer(PosPrinterRole role, {int m = 0, int t1 = 25, int t2 = 250}) {
    final bytes = EscPosHelper.openDrawer(m: m, t1: t1, t2: t2);
    printRaw(role, bytes);
  }

  /// Prints a simple receipt generated from [items] using [ReceiptRenderer].
  /// See [ReceiptRenderer.render] for details.
  void printReceipt(PosPrinterRole role, List<ReceiptItem> items,
      {bool is80mm = false}) {
    final bytes = ReceiptRenderer.render(items, is80mm: is80mm);
    printRaw(role, bytes);
  }

  /// Disposes of all connections and cleans up resources.
  Future<void> dispose() async {
    await _manager.dispose();
    await _logController.close();
  }
}