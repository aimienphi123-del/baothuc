import 'package:sqflite/sqflite.dart';

/// Represents a single, versioned schema migration.
///
/// Each migration knows only how to move the database forward by
/// exactly one version (from [version] - 1 to [version]). The
/// [MigrationRunner] is responsible for ordering and applying them.
abstract class Migration {
  /// The database version this migration produces.
  int get version;

  /// Applies this migration's schema changes.
  ///
  /// If this throws, the caller's transaction is rolled back, so
  /// the database is left exactly as it was before the attempt.
  Future<void> up(DatabaseExecutor db);
}
