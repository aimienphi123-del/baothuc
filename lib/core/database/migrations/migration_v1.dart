import 'package:sqflite/sqflite.dart';

import 'migration.dart';

/// Creates the initial schema: a single `tasks` table that holds
/// both To-do and To-don't items, distinguished by `type`.
class MigrationV1 implements Migration {
  @override
  int get version => 1;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL CHECK (type IN ('todo', 'dont')),
        is_done INTEGER NOT NULL DEFAULT 0 CHECK (is_done IN (0, 1)),
        due_date INTEGER,
        completed_at INTEGER,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    // Supports the default list view: active items in manual
    // order, which every screen in this app will query.
    await db.execute('''
      CREATE INDEX idx_tasks_is_done_sort_order
      ON tasks (is_done, sort_order);
    ''');

    // Supports filtering by To-do vs To-don't.
    await db.execute('''
      CREATE INDEX idx_tasks_type
      ON tasks (type);
    ''');
  }
}
