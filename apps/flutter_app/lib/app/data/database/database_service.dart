import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();

  DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    sqfliteFfiInit();

    final dir = await getApplicationSupportDirectory();

    final dbPath = join(dir.path, 'picpak.db');

    _db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            '''
            CREATE TABLE images(
              id TEXT PRIMARY KEY,
              original_path TEXT NOT NULL,
              thumbnail_path TEXT NOT NULL,
              processed_path TEXT NOT NULL,
              source_hash TEXT NOT NULL,
              device_hash TEXT NOT NULL
            )
            '''
          );

          await db.execute(
            '''
            CREATE TABLE slots(
              slot INTEGER PRIMARY KEY,
              image_id TEXT,
              metadata_json TEXT NOT NULL
            )
            '''
          );

          for (int i=1; i<=500; i++) {
            await db.insert(
              'slots',
              {
                'slot': i,
                'image_id': null,
                'metadata_json': '{}'
              }
            );
          }
        }
      )
    );

    return _db!;
  }
}