import 'package:flutter/foundation.dart';
import 'package:picpak_open/app/data/models/device_settings.dart';

enum ConnectionState {
  disconnected,
  scanning,
  connecting,
  connected
}

enum TransferState {
  idle,
  uploading,
  downloading
}

@immutable
class DeviceSessionState {
  final ConnectionState connection;
  final TransferState transfer;

  final double progress;  //0-1

  final int? activeSlot;
  final List<int> availableSlots;

  final String deviceName;
  final int batteryPercent;
  final String firmware;

  final DeviceSettings settings;

  const DeviceSessionState({
    required this.connection,
    required this.transfer,
    required this.progress,
    required this.deviceName,
    required this.batteryPercent,
    required this.firmware,
    required this.availableSlots,
    required this.settings,
    this.activeSlot
  });

  bool get isConnected => connection == ConnectionState.connected;
  bool get isIdle => transfer == TransferState.idle;
  bool get isBusy => transfer != TransferState.idle;
  bool get canConnect => connection == ConnectionState.disconnected;
  bool get canDisconnect => isConnected && isIdle;
  bool get canTransfer => isConnected && isIdle;
  bool get hasSelectedSlot => activeSlot != null;
  bool get canDownload => hasSelectedSlot && canTransfer && hasImageInSlot(activeSlot!);

  String get statusText {
    switch (connection) {
      case ConnectionState.disconnected:
        return 'Disconnected';
      case ConnectionState.scanning:
        return 'Scanning';
      case ConnectionState.connecting:
        return 'Connecting';
      case ConnectionState.connected:
        switch (transfer) {
          case TransferState.idle:
            return 'Connected';
          case TransferState.uploading:
            return 'Uploading slot $activeSlot';
          case TransferState.downloading:
            return 'Downloading slot $activeSlot';
        }
    }
  }

  bool hasImageInSlot(int slot) {
    return availableSlots.contains(slot);
  }

  DeviceSessionState copyWith({
    ConnectionState? connection,
    TransferState? transfer,
    double? progress,
    int? activeSlot,
    List<int>? availableSlots,
    String? deviceName,
    int? batteryPercent,
    String? firmware,
    DeviceSettings? settings
  }) {
    return DeviceSessionState(
      connection: connection ?? this.connection,
      transfer: transfer ?? this.transfer,
      progress: progress ?? this.progress,
      activeSlot: activeSlot ?? this.activeSlot,
      availableSlots: availableSlots ?? this.availableSlots,
      deviceName: deviceName ?? this.deviceName,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      firmware: firmware ?? this.firmware,
      settings: settings ?? this.settings
    );
  }
}