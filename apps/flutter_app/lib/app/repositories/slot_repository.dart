import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:picpak_open/app/data/database/database_service.dart';
import 'package:picpak_open/app/widgets/library/library_item.dart';
import 'package:picpak_open/app/widgets/library/slot_metadata.dart';

class SlotRepository {
  final db = DatabaseService.instance;

  Future<void> saveSlot({
    required int slot,
    required String? imageId,
    required SlotMetadata metadata
  }) async {
    final database = await db.database;

    await database.update(
      'slots',
      {
        'image_id': imageId,
        'metadata_json': jsonEncode(metadata.toJson())
      },
      where: 'slot = ?',
      whereArgs: [slot]
    );
  }

  Future<List<LibraryItem>> loadLibrary() async {
    final database = await db.database;

    final slotRows = await database.query('slots', orderBy: 'slot');

    final items = <LibraryItem>[];

    for (final row in slotRows) {
      final slot = row['slot'] as int;

      final metadata = SlotMetadata.fromJson(jsonDecode(row['metadata_json'] as String));

      Uint8List? thumbnailBytes;
      bool exists = false;

      final imageId = row['image_id'] as String?;
      
      if (imageId != null) {
        final imageRows = await database.query(
          'images', where: 'id = ?', whereArgs: [imageId]
        );

        if (imageRows.isNotEmpty) {
          final thumbPath = imageRows.first['thumbnail_path'] as String;
          final file = File(thumbPath);
          if (await file.exists()) {
            thumbnailBytes = await file.readAsBytes();
            exists = true;
          }
        }
      }

      items.add(LibraryItem(slot: slot, exists: exists, thumbnailBytes: thumbnailBytes, metadata: metadata));
    }

    return items;
  }
}