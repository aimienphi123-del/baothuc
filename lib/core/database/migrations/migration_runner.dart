import 'package:sqflite/sqflite.dart';

import 'migration.dart';
import 'migration_v1.dart';
import 'migration_v2.dart';

/// Ordered list of every migration this app has ever shipped.
///
/// To add a schema change: write a new `MigrationVN` class and
/// append it here. Never edit a migration that has already been
/// released — schema history must stay immutable.
final List<Migration> allMigrations = [
  MigrationV1(),
  MigrationV2(),
];

/// The current schema version, derived from [allMigrations].
/// Pass this to `openDatabase(version: ...)`.
int get currentDatabaseVersion => allMigrations.last.version;

/// Applies every migration whose version is greater than
/// [fromVersion] and less than or equal to [toVersion], strictly in
/// order.
class MigrationRunner {
  Future<void> run({
    required DatabaseExecutor db,
    required int fromVersion,
    required int toVersion,
  }) async {
    final pending = allMigrations
        .where((m) => m.version > fromVersion && m.version <= toVersion)
        .toList()
      ..sort((a, b) => a.version.compareTo(b.version));

    for (final migration in pending) {
      await migration.up(db);
    }
  }
}
