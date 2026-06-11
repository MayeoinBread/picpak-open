import 'package:flutter/material.dart';
import 'package:picpak_open/transport/ble_manager.dart';

class BleService {
  BleService._internal();

  static final BleService instance = BleService._internal();

  final BleManager manager = BleManager();

  ValueNotifier<double> uploadProgress = ValueNotifier(0.0);
}