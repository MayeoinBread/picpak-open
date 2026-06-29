// import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleSession {
  BluetoothDevice? device;
  BluetoothCharacteristic? writeChar;

  bool get isConnected => device != null;
}