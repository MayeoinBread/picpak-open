import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:picpak_open/app/data/database/database_service.dart';
import 'package:picpak_open/app/data/models/stored_image.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageRepository {
  final db = DatabaseService.instance;

  Future<StoredImage> storeImage({
    required Uint8List? originalBytes,
    required Uint8List thumbnailBytes,
    required Uint8List packedBytes
  }) async {
    final id = const Uuid().v4();

    final appDir = await getApplicationSupportDirectory();

    final imageDir = Directory(join(appDir.path, 'images', id));
    await imageDir.create(recursive: true);

    final thumbnailPath = join(imageDir.path, 'thumb.png');
    final processedPath = join(imageDir.path, 'processed.bin');

    String originalPath = "N/A";
    String sourceHash = "N/A";
    if (originalBytes != null) {
      originalPath = join(imageDir.path, 'original.png');
      await File(originalPath).writeAsBytes(originalBytes);
      sourceHash = md5.convert(originalBytes).toString();
    }
    await File(thumbnailPath).writeAsBytes(thumbnailBytes);

    await File(processedPath).writeAsBytes(packedBytes);
    final deviceHash = md5.convert(packedBytes).toString();

    final image = StoredImage(
      id: id,
      originalPath: originalPath,
      thumbnailPath: thumbnailPath,
      processedPath: processedPath,
      sourceHash: sourceHash,
      deviceHash: deviceHash
    );

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

    if (image.originalPath == "N/A") return null;

    return File(image.originalPath).readAsBytes();
  }

  Future<Uint8List?> loadProcessedBytes(
    String imageId
  ) async {
    final image = await getImage(imageId);

    if (image == null) return null;

    return File(image.processedPath).readAsBytes();
  }

  Future<int> cleanupUnusedImages() async {
    final database = await db.database;

    final rows = await database.query(
      'slots',
      columns: ['image_id']
    );

    final referenceIds = rows.map((e) => e['image_id'] as String?).whereType<String>().toSet();

    final appDir = await getApplicationSupportDirectory();
    final imagesDir = Directory(join(appDir.path, 'images'));

    if (!await imagesDir.exists()) return 0;

    int deleted = 0;

    await for (final entity in imagesDir.list()) {
      if (entity is! Directory) continue;

      final id = basename(entity.path);
      if (!referenceIds.contains(id)) {
        await entity.delete(recursive: true);

        await database.delete(
          'images',
          where: 'id = ?',
          whereArgs: [id]
        );

        deleted++;
      }
    }

    return deleted;
  }
}