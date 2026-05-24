import 'dart:typed_data';

import 'package:picpak_protocol/src/packets/data_packet.dart';
import 'package:picpak_protocol/src/packets/md5_packet.dart';
import 'package:picpak_protocol/src/packets/protocol_packet.dart';

import 'chunking.dart';

class UploadSession {
  static List<ProtocolPacket> build({
    required Uint8List packedImageData,
    required int imageNumber
  }) {
    final packets = <ProtocolPacket>[];

    final chunks = Chunking.split(packedImageData);

    for (int i=0; i<chunks.length; i++) {
      packets.add(DataPacket.create(
        imageNumber: imageNumber,
        packetIndex: i,
        isLast: i == chunks.length - 1,
        chunk: chunks[i]
      ));
    }

    // packets.add(
    //   Md5Packet.create(imageNumber: imageNumber, imageData: packedImageData)
    // );

    return packets;
  }
}