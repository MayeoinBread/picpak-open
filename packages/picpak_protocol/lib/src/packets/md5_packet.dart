import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'protocol_packet.dart';

class Md5Packet {
  static ProtocolPacket create({
    required int imageNumber,
    required Uint8List imageData
  }) {
    final digest = md5.convert(imageData);

    final packet = BytesBuilder();

    packet.addByte(0xAA);
    packet.addByte(0x04);

    packet.addByte(imageNumber & 0xFF);
    packet.addByte((imageNumber >> 8) & 0xFF);

    packet.addByte(0x00);

    packet.add(digest.bytes);

    packet.addByte(0xFF);

    return ProtocolPacket(packet.toBytes());
  }
}