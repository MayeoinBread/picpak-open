import 'package:flutter/material.dart' hide ConnectionState;
import 'package:picpak_open/app/state/device_session_state.dart';

class DeviceSessionService extends ValueNotifier<DeviceSessionState> {

  DeviceSessionService._() : super(_initial);

  static final instance = DeviceSessionService._();

  static final DeviceSessionState _initial = DeviceSessionState(
    connection: ConnectionState.disconnected,
    transfer: TransferState.idle,
    progress: 0.0,
    deviceName: 'Not Connected',
    batteryPercent: 0,
    firmware: '-',
    availableSlots: const[]
  );

  DeviceSessionState get state => value;
  set state(DeviceSessionState newState) => value = newState;

  void update(DeviceSessionState Function(DeviceSessionState s) fn) {
    value = fn(value);
  }
}