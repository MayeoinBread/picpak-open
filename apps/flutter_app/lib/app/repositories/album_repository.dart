import 'package:flutter/foundation.dart';
import 'package:picpak_open/app/data/database/database_service.dart';
import 'package:uuid/uuid.dart';

class AlbumRepository {
  final db = DatabaseService.instance;

  Future<List<Album>> getAlbums() async {
    final database = await db.database;

    final rows = await database.query(
      'albums',
      orderBy: 'name'
    );

    return rows.map((row) {
      return Album(
        id: row['id'] as String,
        name: row['name'] as String
      );
    }).toList();
  }

  Future<Album> getDefaultAlbum() async {
    return await getAlbumById('default');    
  }

  Future<Album> getAlbumById(String id) async {
    final database = await db.database;

    final rows = await database.query(
      'albums',
      where: 'id = ?',
      whereArgs: [id]
    );

    return rows.map((row) {
      return Album(
        id: row['id'] as String,
        name: row['name'] as String
      );
    }).toList().first;
  }

  Future<String> createAlbum(String name) async {
    final database = await db.database;

    final id = const Uuid().v4();

    await database.transaction((txn) async {
      await txn.insert(
        'albums',
        {
          'id': id,
          'name': name
        }
      );

      for (int slot = 1; slot <=500; slot++) {
        await txn.insert(
          'slots',
          {
            'album_id': id,
            'slot': slot,
            'image_id': null,
            'metadata_json': '{}'
          }
        );
      }
    });

    return id;
  }

  Future<void> renameAlbum(String id, String name) async {
    final database = await db.database;

    await database.update(
      'albums',
      {
        'name': name
      },
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  Future <void> deleteAlbum(String id) async {
    if (id == 'default') {
      debugPrint("Can't delete default album!");
      return;
    }

    final database = await db.database;

    await database.delete(
      'albums',
      where: 'id = ?',
      whereArgs: [id]
    );
  }
}

class Album {
  final String id;
  final String name;

  const Album({
    required this.id,
    required this.name
  });
}