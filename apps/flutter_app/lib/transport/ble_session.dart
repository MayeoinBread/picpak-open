import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

class BleSession {
  BluetoothDevice? device;
  BluetoothCharacteristic? writeChar;

  bool get isConnected => device != null;
}