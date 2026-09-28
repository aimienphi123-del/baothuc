import 'package:sqflite/sqflite.dart';

import 'migration.dart';

/// Adds reminder configuration + soft-delete (trash) support to `tasks`,
/// and a `rules` table for saved, reusable reminder presets.
///
/// Non-destructive: only adds columns/tables, never touches existing data.
class MigrationV2 implements Migration {
  @override
  int get version => 2;

  @override
  Future<void> up(DatabaseExecutor db) async {
    // Reminder configuration. `reminder_type` mirrors TaskType's pattern:
    // stored as text, parsed defensively on read.
    await db.execute('''
      ALTER TABLE tasks ADD COLUMN reminder_type TEXT NOT NULL DEFAULT 'none'
        CHECK (reminder_type IN ('none','once','daily','everyNDays','weekday'));
    ''');
    await db.execute("ALTER TABLE tasks ADD COLUMN reminder_time TEXT;");
    await db.execute(
      "ALTER TABLE tasks ADD COLUMN reminder_interval_days INTEGER;",
    );
    // Comma-separated weekday numbers (1=Monday .. 7=Sunday), e.g. "1,2,3,4,5".
    await db.execute("ALTER TABLE tasks ADD COLUMN reminder_weekdays TEXT;");

    // Soft delete: a non-null deleted_at means the task is in the trash.
    await db.execute("ALTER TABLE tasks ADD COLUMN deleted_at INTEGER;");

    // Supports "list everything currently in the trash, newest-deleted
    // first" and the periodic purge query (deleted_at older than N days).
    await db.execute('''
      CREATE INDEX idx_tasks_deleted_at ON tasks (deleted_at);
    ''');

    // Saved reminder presets (e.g. "every 2 days at 22:00"), reusable
    // across tasks. Same reminder fields as a task, minus anything
    // task-specific.
    await db.execute('''
      CREATE TABLE rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reminder_type TEXT NOT NULL
          CHECK (reminder_type IN ('once','daily','everyNDays','weekday')),
        reminder_time TEXT,
        reminder_interval_days INTEGER,
        reminder_weekdays TEXT,
        created_at INTEGER NOT NULL
      );
    ''');
  }
}
