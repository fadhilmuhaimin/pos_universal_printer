/// Stub implementation for BLE printing. iOS does not support Bluetooth
/// Serial Port Profile (SPP) unless devices are part of Apple’s MFi
/// programme【229364017025404†L45-L58】.  BLE support is planned for future
/// releases. All methods throw [UnimplementedError].
class BlePrinterStub {
  /// Throws [UnimplementedError] when attempting to scan for BLE printers.
  void scan() {
    throw UnimplementedError(
        'BLE scanning is not implemented. iOS only supports MFi devices【229364017025404†L45-L58】');
  }

  /// Throws [UnimplementedError] when attempting to connect to a BLE printer.
  void connect(String deviceId) {
    throw UnimplementedError(
        'BLE connect is not implemented. iOS only supports MFi devices【229364017025404†L45-L58】');
  }

  /// Throws [UnimplementedError] when attempting to send data to a BLE printer.
  void send(List<int> data) {
    throw UnimplementedError(
        'BLE send is not implemented. iOS only supports MFi devices【229364017025404†L45-L58】');
  }

  /// Throws [UnimplementedError] when attempting to disconnect from a BLE printer.
  void disconnect() {
    throw UnimplementedError(
        'BLE disconnect is not implemented. iOS only supports MFi devices【229364017025404†L45-L58】');
  }
}