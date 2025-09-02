import 'dart:async';
import 'dart:io';

import '../core/logging.dart';

/// Simple TCP client tailored for printers listening on port 9100. It
/// supports auto‑reconnect, write batching, timeouts and throughput
/// measurement.
class TcpClient {
  TcpClient(
    this.host,
    this.port,
    this.logger, {
    this.timeout = const Duration(seconds: 5),
    this.autoReconnect = true,
    this.maxRetries = 3,
  });

  final String host;
  final int port;
  final Logger logger;
  final Duration timeout;
  final bool autoReconnect;
  final int maxRetries;

  Socket? _socket;
  bool _connecting = false;
  int _bytesSent = 0;
  DateTime? _connectionStart;

  /// Connects to the remote host if not already connected.
  Future<void> connect() async {
    if (_socket != null) return;
    if (_connecting) {
      // Wait until current connection attempt completes.
      while (_connecting) {
        await Future.delayed(Duration(milliseconds: 50));
      }
      return;
    }
    _connecting = true;
    int attempt = 0;
    while (true) {
      try {
        logger.add(LogLevel.info, 'Connecting to $host:$port');
        final socket = await Socket.connect(host, port, timeout: timeout);
        _socket = socket;
        _bytesSent = 0;
        _connectionStart = DateTime.now();
        logger.add(LogLevel.info, 'Connected to $host:$port');
        // Listen for errors.
        socket.done.then((_) {
          logger.add(LogLevel.warning, 'Socket to $host:$port closed');
          _socket = null;
          if (autoReconnect) {
            logger.add(LogLevel.info, 'Attempting to reconnect to $host:$port');
            // Fire and forget reconnect.
            connect();
          }
        });
        break;
      } catch (e) {
        attempt++;
        logger.add(LogLevel.error,
            'Failed to connect to $host:$port (attempt $attempt): $e');
        if (attempt > maxRetries) {
          logger.add(LogLevel.error,
              'Max retries reached, giving up on connection to $host:$port');
          break;
        }
        final delayMs = 500 * (1 << (attempt - 1));
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    _connecting = false;
  }

  /// Sends [data] to the printer. Attempts to reconnect if the socket is
  /// disconnected and [autoReconnect] is true.
  Future<void> send(List<int> data) async {
    if (data.isEmpty) return;
    if (_socket == null) {
      if (autoReconnect) {
        await connect();
      } else {
        throw StateError('Socket not connected');
      }
    }
    if (_socket == null) {
      throw StateError('Unable to connect to $host:$port');
    }
    try {
      _socket!.add(data);
      await _socket!.flush();
      _bytesSent += data.length;
    } catch (e) {
      logger.add(LogLevel.error, 'Error writing to $host:$port: $e');
      _socket?.destroy();
      _socket = null;
      if (autoReconnect) {
        await connect();
        await send(data);
      } else {
        rethrow;
      }
    }
  }

  /// Closes the connection.
  Future<void> close() async {
    await _socket?.close();
    _socket = null;
  }

  /// Returns the average throughput in bytes per second since the
  /// connection was established. If not connected returns 0.
  double get throughput {
    if (_connectionStart == null || _bytesSent == 0) return 0;
    final elapsed = DateTime.now().difference(_connectionStart!).inSeconds;
    if (elapsed == 0) return 0;
    return _bytesSent / elapsed;
  }
}
