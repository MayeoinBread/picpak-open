enum SlotContentType {
  empty,
  image,
  qr,
  postit,
  generated
}

enum SlotSyncState {
  clean,
  modified,
  pendingUpload,
  uploading,
  failed
}

class SlotMetadata {
  final SlotContentType type;
  final SlotSyncState syncState;

  final String? text;
  final String? qrData;

  const SlotMetadata({
    required this.type,
    this.syncState = SlotSyncState.clean,
    this.text,
    this.qrData
  });

  SlotMetadata copyWith({
    SlotContentType? type,
    SlotSyncState? syncState,
    String? text,
    String? qrData,
    DateTime? updatedAt
  }) {
    return SlotMetadata(
      type: type ?? this.type,
      syncState: syncState ?? this.syncState,
      text: text ?? this.text,
      qrData: qrData ?? this.qrData
    );
  }
}