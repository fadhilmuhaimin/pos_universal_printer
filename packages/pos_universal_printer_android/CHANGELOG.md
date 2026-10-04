# Changelog

## 0.1.1

- Bluetooth connect falls back from secure SDP to insecure SDP and RFCOMM channel 1 (secure and insecure). Fixes label/sticker printers that only accept the host they were first paired with.
- Close stale and failed sockets before reconnecting.

## 0.1.0

- Initial Android implementation for `pos_universal_printer`.
- Bluetooth Classic (SPP) scanning/connection and TCP client.
