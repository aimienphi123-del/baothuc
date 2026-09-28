/// One problem found while validating a backup file or auditing the
/// live database. Never fatal by itself — the caller decides what to
/// do (skip the row, show a warning, etc).
class DataIssue {
  final String table; // "tasks" or "rules"
  final Object? rowId; // null if the id itself couldn't be read
  final String description;

  const DataIssue({required this.table, required this.rowId, required this.description});

  @override
  String toString() => '[$table${rowId != null ? ' #$rowId' : ''}] $description';
}

/// What happened when importing a backup file.
class RestoreResult {
  final int tasksRestored;
  final int rulesRestored;
  final List<DataIssue> skipped;

  const RestoreResult({
    required this.tasksRestored,
    required this.rulesRestored,
    required this.skipped,
  });

  bool get hadSkippedRows => skipped.isNotEmpty;
}
