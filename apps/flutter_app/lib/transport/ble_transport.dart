import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:picpak_protocol/picpak_protocol.dart';

class BleTransport {
  Future<void> sendImage({
    required BluetoothDevice device,
    required List<ProtocolPacket> packets,
    Function(double progress)? onProgress,
  }) async {
    final services = await device.discoverServices();

    BluetoothCharacteristic? characteristic;

    for (final s in services) {
      if (s.uuid.toString() == ProtocolConstants.serviceUuid) {
        for (final c in s.characteristics) {
          if (c.uuid.toString() == ProtocolConstants.characteristicUuid) {
            characteristic = c;
            break;
          }
        }
      }
    }

    if (characteristic == null) {
      throw Exception("Characteristic not found");
    }

    await characteristic.setNotifyValue(true);

    final total = packets.length;

    for (int i=0; i<total; i++) {
      final packet = packets[i].bytes;

      await characteristic.write(packet, withoutResponse: false);

      if (onProgress != null && i % 10 == 0) {
        onProgress(i / total);
      }
    }

    onProgress?.call(1.0);
  }

  Future<void> sendMd5Trigger({
    required BluetoothDevice device,
    required int imageNumber,
    required Uint8List imageData
  }) async {
    final services = await device.discoverServices();

    BluetoothCharacteristic? characteristic;

    for (final s in services) {
      if (s.uuid.toString() == ProtocolConstants.serviceUuid) {
        for (final c in s.characteristics) {
          if (c.uuid.toString() == ProtocolConstants.characteristicUuid) {
            characteristic = c;
            break;
          }
        }
      }
    }

    if (characteristic == null) {
      throw Exception("Characteristic not found");
    }

    final packet = Md5Packet.create(imageNumber: imageNumber, imageData: imageData);

    await characteristic.write(packet.bytes, withoutResponse: false);
  }
}