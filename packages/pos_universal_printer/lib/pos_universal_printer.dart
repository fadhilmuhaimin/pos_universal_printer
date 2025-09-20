import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'src/core/manager.dart';
import 'src/core/logging.dart';
import 'src/protocols/escpos/builder.dart';
import 'src/renderer/receipt_renderer.dart';
// EventChannel is already available from the full services import above

// Public re-exports for builders and renderer so users don't import from src/.
export 'src/protocols/escpos/builder.dart'
    show EscPosBuilder, PosAlign, EscPosHelper;
export 'src/protocols/tspl/builder.dart' show TsplBuilder;
export 'src/protocols/cpcl/builder.dart' show CpclBuilder;
export 'src/renderer/receipt_renderer.dart' show ReceiptItem, ReceiptRenderer;
export 'src/helpers/custom_sticker.dart'
    show
        StickerText,
        StickerBarcode,
        CustomStickerPrinter,
        MenuItemModel,
        StickerWeight;
export 'src/core/manager.dart'
    show ConnectionEvent, ConnectionStatus, ConnectionKind;
// Blue thermal compatibility facade
export 'blue_thermal_compat.dart'
    show BlueThermalCompatPrinter, Size, Align, CompatLine;

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
    // Ensure event listening starts early to catch native events even after hot reload
    _manager.ensureEventListening(_events);
  }

  /// Entry point for printing receipts/labels and managing printer roles.
  static final PosUniversalPrinter instance = PosUniversalPrinter._();

  static const MethodChannel _channel = MethodChannel('pos_universal_printer');
  static const EventChannel _events =
      EventChannel('pos_universal_printer/events');
  final Logger _logger = Logger();
  late final PosPrinterManager _manager;

  /// Returns a copy of the current logs.
  List<LogEntry> get logs => _logger.entries;

  /// Internal: add a log entry (temporary public so compat layer can add
  /// detailed diagnostics without exposing the Logger type itself).
  void debugLog(LogLevel level, String message) {
    _logger.add(level, message);
  }

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

  /// Stream of connection state changes across all roles.
  Stream<ConnectionEvent> get connectionEvents => _manager.connectionEvents;

  /// Enables or disables auto-reconnect for the specified [role]. If enabled,
  /// the manager will attempt to reconnect when a disconnection is detected.
  void setAutoReconnect(PosPrinterRole role, bool enabled) {
    _manager.setAutoReconnect(role, enabled);
  }

  /// Internal: start listening to native event channel (idempotent).
  void ensureEventListening() {
    _manager.ensureEventListening(_events);
  }

  /// Forces sync with native side after hot reload: checks any still-open
  /// native Bluetooth sockets and emits events accordingly.
  Future<void> resyncConnections() async {
    await _manager.resyncConnections();
  }

  /// Disconnect all native Bluetooth sockets (safety valve when Dart state
  /// is reset by hot reload but native sockets persist).
  Future<void> forceDisconnectAllBluetooth() async {
    await _channel.invokeMethod('disconnectAllBluetooth');
  }

  /// Disconnect a specific Bluetooth device by MAC [address]. This is a
  /// precise alternative to [forceDisconnectAllBluetooth] when you know
  /// which device to close.
  Future<void> disconnectBluetoothAddress(String address) async {
    try {
      await _channel.invokeMethod('disconnectBluetooth', {
        'address': address,
      });
    } on PlatformException catch (_) {
      // ignore; best-effort disconnect
    }
  }

  /// Snapshot of registered devices per role.
  Map<PosPrinterRole, PrinterDevice> get registeredDevices =>
      _manager.registeredDevices;

  /// Returns whether a role is currently connected.
  bool isRoleConnected(PosPrinterRole role) => _manager.isRoleConnected(role);
}
