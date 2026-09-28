import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../models/task/task_model.dart';

/// Local persistence for [TaskModel]. This is the only class in the
/// app that writes raw SQL against the `tasks` table.
class TaskLocalDataSource {
  final AppDatabase _appDatabase;

  TaskLocalDataSource({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  /// Inserts a new task and returns it with its assigned [TaskModel.id].
  Future<TaskModel> insertTask(TaskModel task) async {
    final db = await _appDatabase.database;
    final id = await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return task.copyWith(id: id);
  }

  /// Updates an existing task. Throws [ArgumentError] if it has no
  /// id — use [insertTask] for new tasks — and [StateError] if no
  /// row with that id exists anymore.
  Future<void> updateTask(TaskModel task) async {
    if (task.id == null) {
      throw ArgumentError('Cannot update a task with no id');
    }
    final db = await _appDatabase.database;
    final rowsAffected = await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    if (rowsAffected == 0) {
      throw StateError('No task found with id ${task.id} to update');
    }
  }

  /// Permanently deletes a task by id.
  Future<void> deleteTask(int id) async {
    final db = await _appDatabase.database;
    final rowsAffected = await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rowsAffected == 0) {
      throw StateError('No task found with id $id to delete');
    }
  }

  /// Fetches a single task by id, or null if it doesn't exist or
  /// its row is corrupted.
  Future<TaskModel?> getTaskById(int id) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'tasks',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TaskModel.fromMap(rows.first);
  }

  /// Fetches tasks, optionally filtered by [type] and/or [isDone],
  /// ordered for display (manual order, then newest first). Tasks
  /// currently in the trash are never included here — use
  /// [getTrashTasks] for those.
  ///
  /// A row that fails to parse is skipped rather than failing the
  /// whole query, so one corrupted row can never hide the rest of
  /// the user's valid data.
  Future<List<TaskModel>> getTasks({TaskType? type, bool? isDone}) async {
    final db = await _appDatabase.database;

    final whereClauses = <String>['deleted_at IS NULL'];
    final whereArgs = <Object?>[];
    if (type != null) {
      whereClauses.add('type = ?');
      whereArgs.add(type.toDbValue());
    }
    if (isDone != null) {
      whereClauses.add('is_done = ?');
      whereArgs.add(isDone ? 1 : 0);
    }

    final rows = await db.query(
      'tasks',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'sort_order ASC, created_at DESC',
    );

    final tasks = <TaskModel>[];
    for (final row in rows) {
      try {
        tasks.add(TaskModel.fromMap(row));
      } catch (_) {
        // Skip this corrupted row; a future integrity-audit phase
        // (Phase 4) can surface it instead of silently dropping it.
        continue;
      }
    }
    return tasks;
  }

  /// Every row exactly as stored, trashed tasks included — the raw
  /// form backup export and integrity auditing both need, since
  /// [TaskModel.fromMap] would throw away (or refuse to construct)
  /// exactly the rows an audit needs to see.
  Future<List<Map<String, Object?>>> getAllRawRows() async {
    final db = await _appDatabase.database;
    return db.query('tasks', orderBy: 'id ASC');
  }

  /// Wipes every task and replaces them with [rows], as one
  /// transaction — either the whole restore lands, or none of it
  /// does, so a failure partway through can never leave a mix of
  /// old and new data behind.
  Future<void> replaceAllTasks(List<Map<String, Object?>> rows) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await txn.delete('tasks');
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert('tasks', row);
      }
      await batch.commit(noResult: true);
    });
  }

  /// Atomically applies new `sort_order` values to several tasks at
  /// once — needed when the user drags to reorder the list. Runs
  /// inside a transaction so a partial failure never leaves the
  /// list in a half-reordered state.
  Future<void> updateSortOrders(Map<int, int> idToSortOrder) async {
    final db = await _appDatabase.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in idToSortOrder.entries) {
        batch.update(
          'tasks',
          {'sort_order': entry.value, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [entry.key],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Moves a task to the trash (soft delete) rather than removing it
  /// outright, then enforces the trash's 20-item cap by permanently
  /// deleting the oldest overflow, if any.
  Future<void> softDeleteTask(int id) async {
    final db = await _appDatabase.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rowsAffected = await db.update(
      'tasks',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (rowsAffected == 0) {
      throw StateError('No active task found with id $id to delete');
    }
    await _enforceTrashCap(db);
  }

  /// Takes a task back out of the trash.
  Future<void> restoreTask(int id) async {
    final db = await _appDatabase.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rowsAffected = await db.update(
      'tasks',
      {'deleted_at': null, 'updated_at': now},
      where: 'id = ? AND deleted_at IS NOT NULL',
      whereArgs: [id],
    );
    if (rowsAffected == 0) {
      throw StateError('No trashed task found with id $id to restore');
    }
  }

  /// Everything currently in the trash, most recently deleted first.
  Future<List<TaskModel>> getTrashTasks() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'tasks',
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    final tasks = <TaskModel>[];
    for (final row in rows) {
      try {
        tasks.add(TaskModel.fromMap(row));
      } catch (_) {
        continue;
      }
    }
    return tasks;
  }

  /// Permanently deletes anything that has been in the trash longer
  /// than [retention]. Call this on app start / when opening the
  /// trash screen — there is no background scheduler in this app.
  Future<void> purgeExpiredTrash({
    Duration retention = const Duration(days: 5),
  }) async {
    final db = await _appDatabase.database;
    final cutoff = DateTime.now().subtract(retention).millisecondsSinceEpoch;
    await db.delete(
      'tasks',
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoff],
    );
  }

  static const int _trashCap = 20;

  /// Keeps the trash at [_trashCap] items by permanently deleting the
  /// oldest overflow. Runs inside the same connection as the soft
  /// delete that triggered it.
  Future<void> _enforceTrashCap(DatabaseExecutor db) async {
    final overflow = await db.rawQuery(
      '''
      SELECT id FROM tasks
      WHERE deleted_at IS NOT NULL
      ORDER BY deleted_at DESC
      LIMIT -1 OFFSET ?
      ''',
      [_trashCap],
    );
    if (overflow.isEmpty) return;
    final ids = overflow.map((row) => row['id']).toList();
    await db.delete(
      'tasks',
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }

  /// Marks a task done/not-done and stamps `completed_at`
  /// accordingly, as one atomic write.
  Future<void> setDone(int id, bool isDone) async {
    final db = await _appDatabase.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rowsAffected = await db.update(
      'tasks',
      {
        'is_done': isDone ? 1 : 0,
        'completed_at': isDone ? now : null,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rowsAffected == 0) {
      throw StateError('No task found with id $id to update');
    }
  }
}
