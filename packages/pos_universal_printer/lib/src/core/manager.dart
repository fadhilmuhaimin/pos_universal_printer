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
  bool autoReconnect = true;
}

/// Manages multiple printer connections keyed by [PosPrinterRole]. Wraps
/// the platform channel, TCP client, job queue and logger.
class PosPrinterManager {
  PosPrinterManager(this._channel, this.logger) : jobQueue = JobQueue(logger);

  final MethodChannel _channel;
  final Logger logger;
  final JobQueue jobQueue;
  final Map<PosPrinterRole, DeviceConnection> _connections = {};
  final StreamController<ConnectionEvent> _connectionController =
      StreamController<ConnectionEvent>.broadcast();
  StreamSubscription<dynamic>? _eventSub;
  Timer? _pollTimer;

  /// Emits connection state changes across all roles.
  Stream<ConnectionEvent> get connectionEvents => _connectionController.stream;

  /// Enables/disables auto-reconnect for [role].
  void setAutoReconnect(PosPrinterRole role, bool enabled) {
    final conn = _connections[role];
    if (conn != null) conn.autoReconnect = enabled;
  }

  /// Start listening to native event channel and start a polling fallback.
  void ensureEventListening(EventChannel events) {
    _eventSub ??= events.receiveBroadcastStream().listen((dynamic e) {
      try {
        final map = Map<Object?, Object?>.from(e as Map);
        final type = map['type'] as String?;
        final event = map['event'] as String?;
        final address = map['address'] as String?;
        if (type == 'bluetooth' && address != null) {
          _handleBluetoothEvent(address, event);
        }
      } catch (_) {
        // ignore malformed
      }
    });
    _pollTimer ??= Timer.periodic(const Duration(seconds: 10), (_) async {
      await _pollConnections();
    });
  }

  void _handleBluetoothEvent(String address, String? event) {
    MapEntry<PosPrinterRole, DeviceConnection>? entry;
    for (final e in _connections.entries) {
      if (e.value.device.address == address) {
        entry = e;
        break;
      }
    }
    if (entry == null) return;
    final role = entry.key;
    final conn = entry.value;
    if (event == 'connected') {
      conn.bluetoothConnected = true;
      _connectionController.add(ConnectionEvent(
          role: role,
          kind: ConnectionKind.bluetooth,
          address: address,
          status: ConnectionStatus.connected));
    } else if (event == 'disconnecting') {
      _connectionController.add(ConnectionEvent(
          role: role,
          kind: ConnectionKind.bluetooth,
          address: address,
          status: ConnectionStatus.disconnecting));
    } else if (event == 'disconnected') {
      final wasConnected = conn.bluetoothConnected;
      conn.bluetoothConnected = false;
      _connectionController.add(ConnectionEvent(
          role: role,
          kind: ConnectionKind.bluetooth,
          address: address,
          status: ConnectionStatus.disconnected));
      if (wasConnected && conn.autoReconnect) {
        _attemptBluetoothReconnect(conn, role);
      }
    }
  }

  /// Queries native for any still-open Bluetooth sockets and reconciles
  /// internal state (useful after hot reload when Dart state resets).
  Future<void> resyncConnections() async {
    List<dynamic> addrs = const [];
    try {
      final res =
          await _channel.invokeMethod<List<dynamic>>('listConnectedBluetooth');
      addrs = res ?? const [];
    } catch (_) {
      // ignore
    }
    final connectedSet = addrs.map((e) => e.toString()).toSet();
    for (final entry in _connections.entries) {
      final role = entry.key;
      final conn = entry.value;
      if (conn.device.type == PrinterType.bluetooth &&
          conn.device.address != null) {
        final addr = conn.device.address!;
        final isNowConnected = connectedSet.contains(addr);
        if (conn.bluetoothConnected != isNowConnected) {
          conn.bluetoothConnected = isNowConnected;
          _connectionController.add(ConnectionEvent(
              role: role,
              kind: ConnectionKind.bluetooth,
              address: addr,
              status: isNowConnected
                  ? ConnectionStatus.connected
                  : ConnectionStatus.disconnected));
        }
      }
    }
  }

  Future<void> _pollConnections() async {
    for (final entry in _connections.entries) {
      final role = entry.key;
      final conn = entry.value;
      if (conn.device.type == PrinterType.bluetooth &&
          conn.device.address != null) {
        try {
          final ok = await _channel.invokeMethod<bool>('isBluetoothConnected', {
                'address': conn.device.address,
              }) ??
              false;
          if (ok != conn.bluetoothConnected) {
            conn.bluetoothConnected = ok;
            _connectionController.add(ConnectionEvent(
                role: role,
                kind: ConnectionKind.bluetooth,
                address: conn.device.address,
                status: ok
                    ? ConnectionStatus.connected
                    : ConnectionStatus.disconnected));
            if (!ok && conn.autoReconnect) {
              _attemptBluetoothReconnect(conn, role);
            }
          }
        } catch (_) {
          // ignore
        }
      }
    }
  }

  Future<void> _attemptBluetoothReconnect(
      DeviceConnection conn, PosPrinterRole role) async {
    int attempt = 0;
    while (attempt < 3) {
      // Abort if user has removed/unregistered this role or disabled auto-reconnect
      final current = _connections[role];
      if (current != conn || !conn.autoReconnect) {
        logger.add(LogLevel.debug,
            'Auto-reconnect aborted for role ' + role.toString());
        return;
      }
      attempt++;
      try {
        logger.add(LogLevel.info,
            'Auto-reconnect Bluetooth (${conn.device.address}) attempt $attempt');
        final ok = await _channel.invokeMethod<bool>('connectBluetooth', {
              'address': conn.device.address,
            }) ??
            false;
        conn.bluetoothConnected = ok;
        if (ok) {
          _connectionController.add(ConnectionEvent(
              role: role,
              kind: ConnectionKind.bluetooth,
              address: conn.device.address,
              status: ConnectionStatus.connected));
          return;
        }
      } catch (e) {
        logger.add(LogLevel.error, 'Bluetooth auto-reconnect error: $e');
      }
      await Future.delayed(Duration(milliseconds: 500 * (1 << (attempt - 1))));
    }
  }

  /// Associates a [device] with a [role] and establishes the connection.
  Future<void> setDevice(PosPrinterRole role, PrinterDevice device) async {
    // Disconnect previous device for the role.
    await removeDevice(role);
    final conn = DeviceConnection(device);
    _connections[role] = conn;
    if (device.type == PrinterType.tcp) {
      final tcp = TcpClient(
        device.address!,
        device.port!,
        logger,
        onConnectionChanged: (connected) {
          _connectionController.add(ConnectionEvent(
            role: role,
            kind: ConnectionKind.tcp,
            address: '${device.address}:${device.port}',
            status: connected
                ? ConnectionStatus.connected
                : ConnectionStatus.disconnected,
          ));
        },
      );
      conn.tcpClient = tcp;
      // Reachability probe; TcpClient keeps probing in the background while
      // the printer is unreachable.
      await tcp.connect();
    } else if (device.type == PrinterType.bluetooth) {
      try {
        // If native already has an open socket (e.g., after hot reload), adopt it instead of reconnecting.
        final bool already =
            await _channel.invokeMethod<bool>('isBluetoothConnected', {
                  'address': device.address,
                }) ??
                false;
        bool ok = already;
        if (!already) {
          ok = await _channel.invokeMethod<bool>('connectBluetooth', {
                'address': device.address,
              }) ??
              false;
        }
        conn.bluetoothConnected = ok;
        if (ok) {
          logger.add(LogLevel.info,
              'Connected Bluetooth printer ${device.name} (${device.address})');
          _connectionController.add(ConnectionEvent(
              role: role,
              kind: ConnectionKind.bluetooth,
              address: device.address,
              status: ConnectionStatus.connected));
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
    // Ensure no further auto-reconnect attempts for this connection
    conn.autoReconnect = false;
    if (conn.tcpClient != null) {
      await conn.tcpClient!.close();
    }
    // Always ask native to disconnect the socket for Bluetooth, regardless of our cached flag.
    if (conn.device.type == PrinterType.bluetooth &&
        conn.device.address != null) {
      try {
        logger.add(
            LogLevel.info,
            'Disconnecting Bluetooth ${conn.device.address} for role ' +
                role.toString());
        await _channel.invokeMethod('disconnectBluetooth', {
          'address': conn.device.address,
        });
      } catch (e) {
        logger.add(LogLevel.warning,
            'Error invoking disconnectBluetooth: ' + e.toString());
      }
      _connectionController.add(ConnectionEvent(
          role: role,
          kind: ConnectionKind.bluetooth,
          address: conn.device.address,
          status: ConnectionStatus.disconnected));
    }
  }

  /// Sends [data] to the device associated with [role]. The data will
  /// be enqueued in the job queue, ensuring sequential processing and
  /// retries.
  void send(PosPrinterRole role, List<int> data) {
    _enqueue(role, data);
  }

  /// Like [send] but completes when the data has been delivered, or throws
  /// the last error once [maxRetries] retries are exhausted.
  Future<void> sendAndWait(PosPrinterRole role, List<int> data,
      {int maxRetries = 0}) {
    final completer = Completer<void>();
    if (!_enqueue(role, data,
        maxRetries: maxRetries, completer: completer)) {
      completer.completeError(
          StateError('Printer untuk role ${role.name} belum diatur'));
    }
    return completer.future;
  }

  bool _enqueue(PosPrinterRole role, List<int> data,
      {int? maxRetries, Completer<void>? completer}) {
    final conn = _connections[role];
    if (conn == null) {
      logger.add(LogLevel.error, 'No printer configured for role $role');
      return false;
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
    }, maxRetries: maxRetries, completer: completer);
    jobQueue.addJob(job);
    return true;
  }

  /// Disconnects and clears all devices.
  Future<void> dispose() async {
    final roles = List<PosPrinterRole>.from(_connections.keys);
    for (final role in roles) {
      await removeDevice(role);
    }
    await _eventSub?.cancel();
    _eventSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    await _connectionController.close();
  }

  /// Returns a snapshot of registered devices per role.
  Map<PosPrinterRole, PrinterDevice> get registeredDevices {
    final map = <PosPrinterRole, PrinterDevice>{};
    for (final e in _connections.entries) {
      map[e.key] = e.value.device;
    }
    return map;
  }

  /// Returns whether the device for [role] is currently connected.
  bool isRoleConnected(PosPrinterRole role) {
    final conn = _connections[role];
    if (conn == null) return false;
    if (conn.device.type == PrinterType.tcp) {
      // Last known reachability (probe or print job) of the network printer.
      return conn.tcpClient?.isConnected ?? false;
    } else {
      return conn.bluetoothConnected;
    }
  }
}

/// Public connection event model.
enum ConnectionKind { bluetooth, tcp }

enum ConnectionStatus { connected, disconnecting, disconnected }

class ConnectionEvent {
  ConnectionEvent({
    required this.role,
    required this.kind,
    required this.status,
    this.address,
  });

  final PosPrinterRole role;
  final ConnectionKind kind;
  final ConnectionStatus status;
  final String? address;

  @override
  String toString() =>
      'ConnectionEvent(role: ' +
      role.toString() +
      ', kind: ' +
      kind.toString() +
      ', status: ' +
      status.toString() +
      ', address: ' +
      (address ?? '') +
      ')';
}
