import 'dart:async';
import 'dart:io';

import '../core/logging.dart';

/// TCP client for network (WiFi/LAN) printers listening on port 9100.
///
/// Uses a connection-per-job model: every [send] opens a fresh socket, writes
/// the payload, flushes and closes it. Many WiFi printer modules accept only a
/// single TCP connection and silently drop idle ones (power saving, roaming,
/// router timeouts). Holding one long-lived socket therefore leads to
/// half-open connections that report "connected" while data is lost, and
/// lingering sockets that block new connections. Opening per job avoids both.
///
/// [isConnected] reflects the last known reachability (probe or send). While
/// the printer is unreachable a background probe runs every [probeInterval]
/// so the state recovers once the printer wakes up.
class TcpClient {
  TcpClient(
    this.host,
    this.port,
    this.logger, {
    this.timeout = const Duration(seconds: 4),
    this.maxRetries = 2,
    this.probeInterval = const Duration(seconds: 10),
    this.onConnectionChanged,
  });

  final String host;
  final int port;
  final Logger logger;

  /// Timeout for establishing a TCP connection.
  final Duration timeout;

  /// Extra connection attempts per [send]/[connect] (WiFi modules may need a
  /// moment to wake from power saving).
  final int maxRetries;

  /// Interval of background reachability probes while disconnected.
  final Duration probeInterval;
  final void Function(bool connected)? onConnectionChanged;

  bool _connected = false;
  bool _closed = false;
  Timer? _probeTimer;
  Future<void> _lock = Future.value();
  int _bytesSent = 0;
  DateTime? _connectionStart;

  /// Last known reachability of the printer.
  bool get isConnected => _connected;

  /// Checks that the printer accepts connections (opens and closes a socket).
  /// Does not throw; returns the reachability and updates [isConnected].
  Future<bool> connect() => _synchronized(() async {
        if (_closed) return false;
        try {
          final socket = await _open();
          await _closeSocket(socket);
          _setConnected(true);
          return true;
        } catch (e) {
          logger.add(LogLevel.error, 'Printer $host:$port unreachable: $e');
          _setConnected(false);
          return false;
        }
      });

  /// Sends [data] to the printer over a fresh connection. Throws if the
  /// printer cannot be reached or the write fails.
  Future<void> send(List<int> data) => _synchronized(() async {
        if (data.isEmpty) return;
        if (_closed) throw StateError('TCP client for $host:$port is closed');
        Socket socket;
        try {
          socket = await _open();
        } catch (e) {
          _setConnected(false);
          throw SocketException(
              'Printer $host:$port tidak dapat dihubungi: ${_describe(e)}');
        }
        try {
          socket.add(data);
          await socket.flush();
        } catch (e) {
          socket.destroy();
          _setConnected(false);
          throw SocketException(
              'Gagal mengirim data ke printer $host:$port: ${_describe(e)}');
        }
        _bytesSent += data.length;
        _setConnected(true);
        // Data is flushed; a failure while closing must not trigger a retry
        // (that would print the job twice).
        await _closeSocket(socket);
      });

  /// Stops background probing. The client cannot be used afterwards.
  Future<void> close() async {
    _closed = true;
    _probeTimer?.cancel();
    _probeTimer = null;
    if (_connected) {
      _connected = false;
      try {
        onConnectionChanged?.call(false);
      } catch (_) {}
    }
  }

  /// Average throughput in bytes per second since the first successful
  /// connection. Returns 0 when nothing was sent.
  double get throughput {
    if (_connectionStart == null || _bytesSent == 0) return 0;
    final elapsed = DateTime.now().difference(_connectionStart!).inSeconds;
    if (elapsed == 0) return 0;
    return _bytesSent / elapsed;
  }

  Future<Socket> _open() async {
    int attempt = 0;
    while (true) {
      try {
        final socket = await Socket.connect(host, port, timeout: timeout);
        try {
          socket.setOption(SocketOption.tcpNoDelay, true);
        } catch (_) {}
        // Errors after the job is done are handled by _closeSocket; avoid
        // unhandled async errors from the done future.
        socket.done.catchError((_) {});
        _connectionStart ??= DateTime.now();
        return socket;
      } catch (e) {
        attempt++;
        logger.add(LogLevel.warning,
            'Connect $host:$port failed (attempt $attempt): ${_describe(e)}');
        if (attempt > maxRetries || _closed) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  /// Graceful close: send FIN, then wait (bounded) until the printer closes
  /// its side too, so the next job does not hit a single-connection printer
  /// that is still busy with the previous connection.
  Future<void> _closeSocket(Socket socket) async {
    try {
      final peerClosed = socket
          .listen(null, cancelOnError: true)
          .asFuture<void>()
          .catchError((_) {});
      await socket.close().timeout(const Duration(seconds: 2));
      await peerClosed.timeout(const Duration(milliseconds: 1500));
    } catch (_) {
      // ignore
    } finally {
      socket.destroy();
    }
  }

  void _setConnected(bool value) {
    if (_closed) return;
    if (value) {
      _probeTimer?.cancel();
      _probeTimer = null;
    } else {
      _probeTimer ??= Timer.periodic(probeInterval, (_) => connect());
    }
    if (_connected == value) return;
    _connected = value;
    logger.add(
        value ? LogLevel.info : LogLevel.warning,
        value
            ? 'Printer $host:$port reachable'
            : 'Printer $host:$port unreachable');
    try {
      onConnectionChanged?.call(value);
    } catch (_) {}
  }

  /// Runs [action] after any in-flight operation, so probes and jobs never
  /// open concurrent connections to a single-connection printer.
  Future<T> _synchronized<T>(Future<T> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Human readable error without the misleading local port that Dart adds
  /// to SocketException messages.
  static String _describe(Object e) {
    if (e is SocketException) {
      final os = e.osError;
      final msg =
          (os != null && os.message.isNotEmpty) ? os.message : e.message;
      final code = os?.errorCode;
      if (code == 111 || code == 61 || msg.contains('refused')) {
        return 'koneksi ditolak printer (port sibuk/salah)';
      }
      if (code == 110 ||
          code == 60 ||
          msg.toLowerCase().contains('timed out')) {
        return 'printer tidak merespons (timeout)';
      }
      if (code == 113 || code == 65 || code == 101 || code == 51) {
        return 'printer tidak ditemukan di jaringan';
      }
      return msg;
    }
    return e.toString();
  }
}
