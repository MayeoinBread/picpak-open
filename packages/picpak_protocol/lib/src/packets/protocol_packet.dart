import 'dart:typed_data';

class ProtocolPacket {
  final int idx;
  final Uint8List bytes;

  ProtocolPacket({
    required this.idx,
    required this.bytes
  });
}