import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_universal_printer/src/core/logging.dart';
import 'package:pos_universal_printer/src/net/tcp_client.dart';

/// Fake WiFi printer: accepts one connection at a time and records payloads.
Future<(ServerSocket, List<List<int>>, List<int>)> fakePrinter(
    [int port = 0]) async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
  final jobs = <List<int>>[];
  final active = <int>[0, 0]; // [current, max concurrent]
  server.listen((s) {
    active[0]++;
    if (active[0] > active[1]) active[1] = active[0];
    final buf = <int>[];
    s.listen(buf.addAll, onDone: () {
      active[0]--;
      if (buf.isNotEmpty) jobs.add(buf);
      s.destroy();
    });
  });
  return (server, jobs, active);
}

void main() {
  test('each job uses its own connection, never concurrent', () async {
    final (server, jobs, active) = await fakePrinter();
    final c = TcpClient('127.0.0.1', server.port, Logger());
    expect(await c.connect(), isTrue);
    expect(c.isConnected, isTrue);
    await Future.wait([
      c.send([1, 2, 3]),
      c.send([4, 5]),
      c.send([6])
    ]);
    await Future.delayed(const Duration(milliseconds: 200));
    expect(jobs, [
      [1, 2, 3],
      [4, 5],
      [6]
    ]);
    expect(active[1], 1);
    await c.close();
    await server.close();
  });

  test('unreachable printer reports error and recovers via probe', () async {
    final tmp = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = tmp.port;
    await tmp.close();
    final events = <bool>[];
    final c = TcpClient('127.0.0.1', port, Logger(),
        maxRetries: 0,
        timeout: const Duration(milliseconds: 500),
        probeInterval: const Duration(milliseconds: 300),
        onConnectionChanged: events.add);
    expect(await c.connect(), isFalse);
    await expectLater(c.send([1]), throwsA(isA<SocketException>()));
    final (server, jobs, _) = await fakePrinter(port);
    await Future.delayed(const Duration(milliseconds: 900));
    expect(c.isConnected, isTrue);
    expect(events.last, isTrue);
    await c.send([9]);
    await Future.delayed(const Duration(milliseconds: 200));
    expect(jobs, [
      [9]
    ]);
    await c.close();
    expect(c.isConnected, isFalse);
    await server.close();
  });
}
