import '../../core/database/app_database.dart';
import '../../models/rule/rule_model.dart';

/// Local persistence for [RuleModel]. Rules are few and small (a
/// handful of saved reminder presets), so no pagination or filtering
/// is needed — just list, insert, delete.
class RuleLocalDataSource {
  final AppDatabase _appDatabase;

  RuleLocalDataSource({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<RuleModel> insertRule(RuleModel rule) async {
    final db = await _appDatabase.database;
    final id = await db.insert('rules', rule.toMap());
    return RuleModel(
      id: id,
      reminderType: rule.reminderType,
      reminderTime: rule.reminderTime,
      reminderIntervalDays: rule.reminderIntervalDays,
      reminderWeekdays: rule.reminderWeekdays,
      createdAt: rule.createdAt,
    );
  }

  Future<void> deleteRule(int id) async {
    final db = await _appDatabase.database;
    final rowsAffected = await db.delete(
      'rules',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rowsAffected == 0) {
      throw StateError('No rule found with id $id to delete');
    }
  }

  /// Every rule row exactly as stored — for backup export and
  /// integrity auditing, same reasoning as
  /// [TaskLocalDataSource.getAllRawRows].
  Future<List<Map<String, Object?>>> getAllRawRows() async {
    final db = await _appDatabase.database;
    return db.query('rules', orderBy: 'id ASC');
  }

  /// Wipes every rule and replaces them with [rows], as one
  /// transaction.
  Future<void> replaceAllRules(List<Map<String, Object?>> rows) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await txn.delete('rules');
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert('rules', row);
      }
      await batch.commit(noResult: true);
    });
  }

  /// All saved rules, most recently created first. A row that fails
  /// to parse is skipped rather than failing the whole list.
  Future<List<RuleModel>> getRules() async {
    final db = await _appDatabase.database;
    final rows = await db.query('rules', orderBy: 'created_at DESC');
    final rules = <RuleModel>[];
    for (final row in rows) {
      try {
        rules.add(RuleModel.fromMap(row));
      } catch (_) {
        continue;
      }
    }
    return rules;
  }
}
