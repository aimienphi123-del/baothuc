import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations/migration_runner.dart';

/// Single point of access to the local SQLite database.
///
/// Opens (or creates) `app.db` and runs all pending migrations
/// through [MigrationRunner]. Nothing else in the app should call
/// `openDatabase` directly — everything goes through [database].
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static const String _dbName = 'app.db';

  Database? _db;
  final MigrationRunner _migrationRunner = MigrationRunner();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: currentDatabaseVersion,
      onCreate: (db, version) async {
        // Fresh install: run every migration from scratch.
        await _migrationRunner.run(db: db, fromVersion: 0, toVersion: version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Existing install: run only the migrations that are new.
        // sqflite already wraps onUpgrade in a transaction.
        await _migrationRunner.run(
          db: db,
          fromVersion: oldVersion,
          toVersion: newVersion,
        );
      },
      onDowngrade: (db, oldVersion, newVersion) async {
        // Should not happen in normal use — it would mean a newer
        // version of the app wrote this file and an older version
        // is now opening it. Fail loudly instead of silently
        // deleting or corrupting user data.
        throw StateError(
          'Database file is version $oldVersion, but this app build '
          'only supports up to version $newVersion. Update the app '
          'before opening this data again.',
        );
      },
    );
  }

  /// Closes the database. Only needed for tests or a future
  /// controlled reset (e.g. restoring from a backup); normal app
  /// operation never needs to call this.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
