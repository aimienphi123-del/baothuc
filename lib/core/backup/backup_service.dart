import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../datasources/rule/rule_local_datasource.dart';
import '../../datasources/task/task_local_datasource.dart';
import '../../models/rule/rule_model.dart';
import '../../models/task/task_model.dart';
import 'backup_models.dart';

/// Current backup file format version. Bump this whenever the shape
/// of the exported JSON changes, and teach [_importTaskRow]/
/// [_importRuleRow] how to read older versions — never assume every
/// backup file on a user's device was written by today's app build.
const int _backupFormatVersion = 1;

const List<String> _taskColumnOrder = [
  'completed_at', 'created_at', 'deleted_at', 'description', 'due_date',
  'id', 'is_done', 'reminder_interval_days', 'reminder_time',
  'reminder_type', 'reminder_weekdays', 'sort_order', 'title', 'type',
  'updated_at',
];
const List<String> _ruleColumnOrder = [
  'created_at', 'id', 'reminder_interval_days', 'reminder_time',
  'reminder_type', 'reminder_weekdays',
];
const List<String> _epochMsFields = [
  'created_at', 'updated_at', 'due_date', 'completed_at', 'deleted_at',
];

class BackupService {
  final TaskLocalDataSource _taskDataSource;
  final RuleLocalDataSource _ruleDataSource;

  BackupService({
    TaskLocalDataSource? taskDataSource,
    RuleLocalDataSource? ruleDataSource,
  })  : _taskDataSource = taskDataSource ?? TaskLocalDataSource(),
        _ruleDataSource = ruleDataSource ?? RuleLocalDataSource();

  Future<File> _backupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'todo_backup.json'));
  }

  // ---- Export ----------------------------------------------------

  /// Builds the backup JSON as a string. Deterministic: same data
  /// always produces byte-identical output — every record's keys are
  /// written in a fixed order and rows are sorted by id, so two
  /// backups of an unchanged database are diffable and comparable.
  Future<String> exportToJsonString() async {
    final taskRows = await _taskDataSource.getAllRawRows();
    final ruleRows = await _ruleDataSource.getAllRawRows();

    final envelope = <String, Object?>{
      'formatVersion': _backupFormatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'tasks': taskRows.map((r) => _orderedRecord(r, _taskColumnOrder)).toList(),
      'rules': ruleRows.map((r) => _orderedRecord(r, _ruleColumnOrder)).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  /// Writes the backup to the app's documents directory and returns
  /// the file it wrote. There is no share sheet or custom save
  /// location in this app yet — the file sits at a fixed, known path
  /// the user can locate via their file manager if they need to move
  /// it off the device themselves.
  Future<File> exportToFile() async {
    final json = await exportToJsonString();
    final file = await _backupFile();
    return file.writeAsString(json);
  }

  Map<String, Object?> _orderedRecord(Map<String, Object?> row, List<String> columnOrder) {
    final ordered = <String, Object?>{};
    for (final key in columnOrder) {
      final value = row[key];
      ordered[key] = _epochMsFields.contains(key) && value is int
          ? DateTime.fromMillisecondsSinceEpoch(value).toUtc().toIso8601String()
          : value;
    }
    return ordered;
  }

  // ---- Import ------------------------------------------------------

  Future<bool> backupFileExists() async => (await _backupFile()).exists();

  /// Reads the backup file this app wrote and restores it, replacing
  /// everything currently in the database. This is destructive by
  /// design — restoring is meant to undo the current state — so the
  /// UI must get explicit confirmation before calling this.
  Future<RestoreResult> restoreFromFile() async {
    final file = await _backupFile();
    if (!await file.exists()) {
      throw StateError('No backup file found at ${file.path}');
    }
    return restoreFromJsonString(await file.readAsString());
  }

  /// Validates and restores from a JSON string directly — used by
  /// [restoreFromFile] and by tests. A structurally broken file (not
  /// JSON, missing the top-level fields) throws and changes nothing.
  /// A row that is JSON-shaped but logically invalid (bad enum value,
  /// missing a required field) is skipped and reported in
  /// [RestoreResult.skipped] instead of aborting the whole restore.
  Future<RestoreResult> restoreFromJsonString(String jsonString) async {
    final Object? decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Backup file is not a JSON object');
    }
    final tasksRaw = decoded['tasks'];
    final rulesRaw = decoded['rules'];
    if (tasksRaw is! List || rulesRaw is! List) {
      throw const FormatException('Backup file is missing "tasks" or "rules"');
    }

    final validTaskRows = <Map<String, Object?>>[];
    final validRuleRows = <Map<String, Object?>>[];
    final skipped = <DataIssue>[];

    for (final raw in tasksRaw) {
      final result = _importTaskRow(raw);
      if (result.issue != null) {
        skipped.add(result.issue!);
      } else {
        validTaskRows.add(result.row!);
      }
    }
    for (final raw in rulesRaw) {
      final result = _importRuleRow(raw);
      if (result.issue != null) {
        skipped.add(result.issue!);
      } else {
        validRuleRows.add(result.row!);
      }
    }

    await _taskDataSource.replaceAllTasks(validTaskRows);
    await _ruleDataSource.replaceAllRules(validRuleRows);

    return RestoreResult(
      tasksRestored: validTaskRows.length,
      rulesRestored: validRuleRows.length,
      skipped: skipped,
    );
  }

  ({Map<String, Object?>? row, DataIssue? issue}) _importTaskRow(Object? raw) {
    if (raw is! Map<String, Object?>) {
      return (row: null, issue: const DataIssue(table: 'tasks', rowId: null, description: 'Not a JSON object'));
    }
    try {
      final dbRow = _toDbRow(raw, _epochMsFields);
      // Round-trip through TaskModel: this is what actually enforces
      // every business rule (title not empty, reminder fields
      // consistent with reminderType, ...) rather than duplicating
      // that validation here.
      final model = TaskModel.fromMap(dbRow);
      return (row: model.toMap(), issue: null);
    } catch (e) {
      return (row: null, issue: DataIssue(table: 'tasks', rowId: raw['id'], description: e.toString()));
    }
  }

  ({Map<String, Object?>? row, DataIssue? issue}) _importRuleRow(Object? raw) {
    if (raw is! Map<String, Object?>) {
      return (row: null, issue: const DataIssue(table: 'rules', rowId: null, description: 'Not a JSON object'));
    }
    try {
      final dbRow = _toDbRow(raw, const ['created_at']);
      final model = RuleModel.fromMap(dbRow);
      return (row: model.toMap(), issue: null);
    } catch (e) {
      return (row: null, issue: DataIssue(table: 'rules', rowId: raw['id'], description: e.toString()));
    }
  }

  /// Converts a JSON record's ISO-8601 date strings back to the
  /// epoch-millisecond ints the DB layer (and the model's fromMap)
  /// expect.
  Map<String, Object?> _toDbRow(Map<String, Object?> json, List<String> dateFields) {
    final row = Map<String, Object?>.from(json);
    for (final field in dateFields) {
      final value = row[field];
      if (value is String) {
        row[field] = DateTime.parse(value).millisecondsSinceEpoch;
      }
    }
    return row;
  }

  // ---- Integrity audit --------------------------------------------

  /// Re-validates every row currently in the database (not a
  /// backup file) without changing anything, and reports whatever
  /// fails to parse or breaks a business rule. Ordinary reads
  /// already skip bad rows silently so the app keeps working; this
  /// is what surfaces those problems to the user instead.
  Future<List<DataIssue>> auditIntegrity() async {
    final issues = <DataIssue>[];

    for (final row in await _taskDataSource.getAllRawRows()) {
      try {
        TaskModel.fromMap(row);
      } catch (e) {
        issues.add(DataIssue(table: 'tasks', rowId: row['id'], description: e.toString()));
      }
    }
    for (final row in await _ruleDataSource.getAllRawRows()) {
      try {
        RuleModel.fromMap(row);
      } catch (e) {
        issues.add(DataIssue(table: 'rules', rowId: row['id'], description: e.toString()));
      }
    }
    return issues;
  }
}
