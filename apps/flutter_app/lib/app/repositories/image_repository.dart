import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:picpak_open/app/data/database/database_service.dart';
import 'package:picpak_open/app/data/models/stored_image.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picpak_image/picpak_image.dart';
import 'package:uuid/uuid.dart';

class ImageRepository {
  final db = DatabaseService.instance;

  Future<StoredImage> importImage({
    required Uint8List originalBytes,
    required Uint8List thumbnailBytes,
    required PaletteFramebuffer framebuffer
  }) async {
    final id = const Uuid().v4();

    final appDir = await getApplicationSupportDirectory();

    final imageDir = Directory(join(appDir.path, 'images', id));
    await imageDir.create(recursive: true);

    final originalPath = join(imageDir.path, 'original.png');
    final thumbnailPath = join(imageDir.path, 'thumb.png');
    final processedPath = join(imageDir.path, 'processed.bin');

    await File(originalPath).writeAsBytes(originalBytes);
    await File(thumbnailPath).writeAsBytes(thumbnailBytes);

    final packed = FramebufferPacker.pack(framebuffer);
    await File(processedPath).writeAsBytes(packed);
    final deviceHash = sha256.convert(packed).toString();

    final sourceHash = sha256.convert(originalBytes).toString();

    final image = StoredImage(
      id: id,
      originalPath: originalPath,
      thumbnailPath: thumbnailPath,
      processedPath: processedPath,
      sourceHash: sourceHash,
      deviceHash: deviceHash
    );

    debugPrint('Original path: $originalPath');
    debugPrint('Thumbnail path: $thumbnailPath');

    final database = await db.database;

    await database.insert(
      'images', image.toMap()
    );

    return image;
  }

  Future<StoredImage?> getImage(
    String imageId
  ) async {
    final database = await db.database;
    final rows = await database.query(
      'images',
      where: 'id = ?',
      whereArgs: [imageId]
    );

    if (rows.isEmpty) return null;

    return StoredImage.fromMap(rows.first);
  }

  Future<Uint8List?> loadOriginalBytes(
    String imageId
  ) async {
    final image = await getImage(imageId);

    if (image == null) return null;

    return File(image.originalPath).readAsBytes();
  }

  Future<Uint8List?> loadProcessedBytes(
    String imageId
  ) async {
    final image = await getImage(imageId);

    if (image == null) return null;

    return File(image.processedPath).readAsBytes();
  }
}