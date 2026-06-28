import 'dart:typed_data';

class DeviceSettings {
  int seconds = 3600;
  bool accelerometer = false;

  DeviceSettings({
    required this.seconds,
    required this.accelerometer
  });

  static DeviceSettings decodeSettings(List<int> data) {
    final seconds = ByteData.sublistView(
      Uint8List.fromList(data.sublist(3, 7))
    ).getUint32(0, Endian.little);

    final flags = data[7];

    final accelerometer = (flags & 0x01) != 0;

    return DeviceSettings(
      seconds: seconds,
      accelerometer: accelerometer
    );
  }

  Uint8List encodeSettings() {
    final seconds = ByteData(4)..setUint32(0, this.seconds, Endian.little);
    final flags = accelerometer ? 0x01 : 0x00;

    return Uint8List.fromList(
      [
        0xAA, 0x07, 0x00,
        ...seconds.buffer.asUint8List(),
        flags,
        0xFF
      ]
    );
  }
}