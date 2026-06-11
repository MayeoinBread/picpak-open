class StoredImage {
  final String id;

  final String originalPath;
  final String thumbnailPath;
  final String processedPath;

  final String sourceHash;
  final String deviceHash;

  const StoredImage({
    required this.id,
    required this.originalPath,
    required this.thumbnailPath,
    required this.processedPath,
    required this.sourceHash,
    required this.deviceHash
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'original_path': originalPath,
      'thumbnail_path': thumbnailPath,
      'processed_path': processedPath,
      'source_hash': sourceHash,
      'device_hash': deviceHash
    };
  }

  factory StoredImage.fromMap(Map<String, dynamic> map) {
    return StoredImage(
      id: map['id'],
      originalPath: map['original_path'],
      thumbnailPath: map['thumbnail_path'],
      processedPath: map['processed_path'],
      sourceHash: map['source_hash'],
      deviceHash: map['device_hash']
    );
  }
}