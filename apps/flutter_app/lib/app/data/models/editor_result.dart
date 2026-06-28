import 'dart:typed_data';

import 'package:picpak_open/app/widgets/library/slot_metadata.dart';

class EditorResult {
  final SlotMetadata metadata;
  final Uint8List? originalBytes;
  final Uint8List previewBytes;
  final Uint8List packedBytes;
  
  const EditorResult({
    required this.metadata,
    required this.originalBytes,
    required this.previewBytes,
    required this.packedBytes
  });
}