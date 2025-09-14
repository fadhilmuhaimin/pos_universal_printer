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
  PosPrinterManager(this._channel, this.logger) : jobQueue = JobQueue(logger);

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
        logger.add(
            LogLevel.error, 'Bluetooth connect error: ${e.message ?? e.code}');
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
        // Try write once; if it fails, attempt disconnect -> reconnect -> retry once
        Future<bool> writeOnce() async {
          // If payload > 1024, split into chunks; many SPP modules prefer <~990 bytes.
          // Many low-cost modules become unstable >256 bytes per write.
          // Lower chunk size and add pacing/backoff for reliability.
          const int chunkSize = 256;
          if (data.length <= chunkSize) {
            logger.add(LogLevel.debug,
                'Attempting writeBluetooth single chunk ${data.length} bytes');
            final bool ok =
                await _channel.invokeMethod<bool>('writeBluetooth', {
                      'address': conn.device.address,
                      'bytes': data,
                    }) ??
                    false;
            logger.add(LogLevel.debug, 'writeBluetooth single returned: $ok');
            return ok;
          } else {
            logger.add(LogLevel.debug,
                'Attempting writeBluetooth multi-chunk total=${data.length} chunkSize=$chunkSize');
            for (int offset = 0; offset < data.length; offset += chunkSize) {
              final end = (offset + chunkSize < data.length)
                  ? offset + chunkSize
                  : data.length;
              final slice = data.sublist(offset, end);
              final bool ok =
                  await _channel.invokeMethod<bool>('writeBluetooth', {
                        'address': conn.device.address,
                        'bytes': slice,
                      }) ??
                      false;
              if (!ok) {
                logger.add(
                    LogLevel.warning, 'Chunk write failed at offset=$offset');
                return false;
              }
              // pacing delay: longer if large total
              int baseDelay = 25;
              if (data.length > 4000) baseDelay = 40; // bigger job, more pacing
              await Future.delayed(Duration(milliseconds: baseDelay));
            }
            logger.add(LogLevel.debug, 'All chunks sent OK');
            return true;
          }
        }

        bool ok = await writeOnce();
        if (!ok) {
          logger.add(LogLevel.warning,
              'Bluetooth write failed for ${conn.device.address}, retrying with reconnect');
          try {
            logger.add(LogLevel.debug,
                'Calling disconnectBluetooth for ${conn.device.address}');
            await _channel.invokeMethod('disconnectBluetooth', {
              'address': conn.device.address,
            });
          } catch (e) {
            logger.add(
                LogLevel.error, 'Error invoking disconnectBluetooth: $e');
          }
          try {
            logger.add(
                LogLevel.debug, 'Reconnecting to ${conn.device.address}');
            final bool reconnected = await _channel.invokeMethod<bool>(
                  'connectBluetooth',
                  {
                    'address': conn.device.address,
                  },
                ) ??
                false;
            conn.bluetoothConnected = reconnected;
            logger.add(LogLevel.debug, 'Reconnected: $reconnected');
            if (reconnected) {
              ok = await writeOnce();
            }
          } catch (e) {
            logger.add(LogLevel.error, 'Bluetooth reconnect error: $e');
          }
        }
        if (!ok) {
          // Fallback logging of payload size & first bytes for diagnostics
          final headSample = data
              .take(16)
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(' ');
          logger.add(LogLevel.error,
              'Bluetooth write ultimately failed. Payload length=${data.length}, head(16)=[$headSample]');
          throw Exception('Bluetooth write failed after reconnect');
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
