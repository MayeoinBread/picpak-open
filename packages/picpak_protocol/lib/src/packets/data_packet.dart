import 'dart:typed_data';

import 'package:picpak_protocol/src/packets/protocol_packet.dart';

class DataPacket {
  static ProtocolPacket create({
    required int imageNumber,
    required int packetIndex,
    required bool isLast,
    required Uint8List chunk
  }) {
    final packet = BytesBuilder();
    
    packet.addByte(0xAA);
    packet.addByte(0x01);

    // image id
    packet.addByte(imageNumber & 0xFF);
    packet.addByte((imageNumber >> 8) & 0xFF);

    // packet index
    packet.addByte(packetIndex & 0xFF);

    // is last
    packet.addByte(isLast ? 0x01 : 0x00);

    // payload length
    packet.addByte(chunk.length & 0xFF);
    packet.addByte((chunk.length >> 8) & 0xFF);

    packet.add(chunk);

    packet.addByte(0xFF);

    return ProtocolPacket(packet.toBytes());
  }
}