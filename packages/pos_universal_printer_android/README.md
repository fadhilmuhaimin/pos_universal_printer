# pos_universal_printer_android

Android implementation for `pos_universal_printer`.

- Provides Bluetooth Classic (SPP/RFCOMM) and TCP (port 9100) connectivity.
- Requires Android 5.0+; targetSdk 31+ recommended.
- For Android 12+, request bluetoothScan and bluetoothConnect runtime permissions before scanning/connecting.

This package is not intended to be used directly; depend on `pos_universal_printer`.