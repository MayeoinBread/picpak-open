import 'package:flutter/foundation.dart';
import 'package:flutter_app/app/state/device_session_state.dart';
import 'package:flutter_app/transport/ble_manager.dart';

class DashboardActions {
  static Future<void> connect({
    required BleManager ble,
    required void Function(DeviceSessionState Function(DeviceSessionState)) updateSession,
  }) async {
    
    updateSession( (s) => s.copyWith(connection: ConnectionState.scanning));
    
    final device = await ble.scanForDevice();
    
    if (device == null) {
      updateSession( (s) => s.copyWith(connection: ConnectionState.disconnected));
      return;
    }

    updateSession( (s) => s.copyWith(connection: ConnectionState.connecting));

    try {
      await ble.connect(device);
      updateSession( (s) => s.copyWith(
        connection: ConnectionState.connected,
        deviceName: device.platformName)
      );

      await ble.requestDeviceInfo();
      await ble.imageList();
    } catch (e) {
      updateSession( (s) => s.copyWith(connection: ConnectionState.disconnected));
      return;
    }
  }

  static Future<void> disconnect({
    required BleManager ble,
    required void Function(DeviceSessionState Function(DeviceSessionState)) updateSession,
  }) async {
    try {
      await ble.disconnect();
    } catch (_) {}

    updateSession((s) =>
      s.copyWith(
        connection: ConnectionState.disconnected,
        transfer: TransferState.idle,
        activeSlot: null,
        progress: 0
      )
    );
  }

  static Future<void> downloadSlot({
    required BleManager ble,
    required int? slot,
    required void Function(DeviceSessionState Function(DeviceSessionState)) updateSession
  }) async {
    // TODO some sort of warning/error handling here
    if (slot == null) {
      debugPrint("activeSlot is null");
      return;
    }

    updateSession((s) => s.copyWith(transfer: TransferState.downloading));
    ble.onDownloadComplete = () {
      updateSession((s) => s.copyWith(transfer: TransferState.idle));
    };
    await ble.getImageInSlot(slot);
  }
}