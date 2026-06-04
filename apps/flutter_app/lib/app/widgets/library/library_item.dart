import 'dart:typed_data';

import 'package:flutter_app/app/widgets/library/slot_metadata.dart';

class LibraryItem {
  final int slot;

  final bool exists;

  final Uint8List? thumbnailBytes;

  final SlotMetadata metadata;

  const LibraryItem({
    required this.slot,
    required this.exists,
    required this.thumbnailBytes,
    required this.metadata
  });

  LibraryItem copyWith({
    bool? exists,
    Uint8List? thumbnailBytes,
    SlotMetadata? metadata
  }) {
    return LibraryItem(
      slot: slot,
      exists: exists ?? this.exists,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      metadata: metadata ?? this.metadata
    );
  }
}