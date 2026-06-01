import 'dart:typed_data';

enum SlotContentType {
  empty,
  image,
  qr,
  postit,
}

class LibraryItem {
  final int slot;

  final bool exists;

  final Uint8List? thumbnail;

  final SlotContentType type;

  const LibraryItem({
    required this.slot,
    required this.exists,
    required this.thumbnail,
    required this.type,
  });

  LibraryItem copyWith({
    bool? exists,
    Uint8List? thumbnail,
    SlotContentType? type,
  }) {
    return LibraryItem(
      slot: slot,
      exists: exists ?? this.exists,
      thumbnail: thumbnail ?? this.thumbnail,
      type: type ?? this.type,
    );
  }
}