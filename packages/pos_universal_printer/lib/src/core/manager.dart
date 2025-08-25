import 'dart:async';

import 'package:flutter/services.dart';

import '../net/tcp_client.dart';
import 'logging.dart';
import 'queue.dart';
import '../../pos_universal_printer.dart';

/// Internal representation of a printer device including connection state.
class DeviceConnection {
  DeviceConnection(this.device);
  final PrinterDevice device;
  TcpClient? tcpClient;
  bool bluetoothConnected = false;
}

/// Manages multiple printer connections keyed by [PosPrinterRole]. Wraps
/// the platform channel, TCP client, job queue and logger.
class PosPrinterManager {
  PosPrinterManager(this._channel, this.logger)
      : jobQueue = JobQueue(logger);

  final MethodChannel _channel;
  final Logger logger;
  final JobQueue jobQueue;
  final Map<PosPrinterRole, DeviceConnection> _connections = {};

  /// Associates a [device] with a [role] and establishes the connection.
  Future<void> setDevice(PosPrinterRole role, PrinterDevice device) async {
    // Disconnect previous device for the role.
    await removeDevice(role);
    final conn = DeviceConnection(device);
    _connections[role] = conn;
    if (device.type == PrinterType.tcp) {
      final tcp = TcpClient(device.address!, device.port!, logger);
      await tcp.connect();
      conn.tcpClient = tcp;
    } else if (device.type == PrinterType.bluetooth) {
      try {
        final bool ok = await _channel.invokeMethod<bool>('connectBluetooth', {
          'address': device.address,
        }) ??
            false;
        conn.bluetoothConnected = ok;
        if (ok) {
          logger.add(LogLevel.info,
              'Connected Bluetooth printer ${device.name} (${device.address})');
        } else {
          logger.add(LogLevel.error,
              'Failed to connect Bluetooth printer ${device.name}');
        }
      } on PlatformException catch (e) {
        logger.add(LogLevel.error,
            'Bluetooth connect error: ${e.message ?? e.code}');
      }
    }
  }

  /// Removes the device mapped to [role] and closes the connection.
  Future<void> removeDevice(PosPrinterRole role) async {
    final conn = _connections.remove(role);
    if (conn == null) return;
    if (conn.tcpClient != null) {
      await conn.tcpClient!.close();
    }
    if (conn.bluetoothConnected) {
      try {
        await _channel.invokeMethod('disconnectBluetooth', {
          'address': conn.device.address,
        });
      } catch (e) {
        // ignore
      }
    }
  }

  /// Sends [data] to the device associated with [role]. The data will
  /// be enqueued in the job queue, ensuring sequential processing and
  /// retries.
  void send(PosPrinterRole role, List<int> data) {
    final conn = _connections[role];
    if (conn == null) {
      logger.add(LogLevel.error, 'No printer configured for role $role');
      return;
    }
    final job = PrintJob('Send to $role', () async {
      if (conn.device.type == PrinterType.tcp) {
        final tcp = conn.tcpClient;
        if (tcp == null) {
          throw StateError('TCP client not connected');
        }
        await tcp.send(data);
      } else if (conn.device.type == PrinterType.bluetooth) {
        final bool ok = await _channel.invokeMethod<bool>('writeBluetooth', {
          'address': conn.device.address,
          'bytes': data,
        }) ??
            false;
        if (!ok) {
          throw Exception('Bluetooth write failed');
        }
      }
    });
    jobQueue.addJob(job);
  }

  /// Disconnects and clears all devices.
  Future<void> dispose() async {
    final roles = List<PosPrinterRole>.from(_connections.keys);
    for (final role in roles) {
      await removeDevice(role);
    }
  }
}