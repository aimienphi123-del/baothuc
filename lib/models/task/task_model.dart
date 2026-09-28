/// The two kinds of item this app manages. A To-do is something the
/// user intends to do; a To-don't is something the user explicitly
/// intends not to do. Both share the same fields and lifecycle —
/// this enum is the only distinction between them.
enum TaskType {
  todo,
  dont;

  String toDbValue() => name;

  static TaskType fromDbValue(String value) {
    switch (value) {
      case 'todo':
        return TaskType.todo;
      case 'dont':
        return TaskType.dont;
      default:
        throw FormatException('Unknown task type in database: "$value"');
    }
  }
}

/// How a task's reminder repeats. [none] means no reminder is set.
enum ReminderType {
  none,
  once,
  daily,
  everyNDays,
  weekday;

  String toDbValue() => name;

  static ReminderType fromDbValue(String? value) {
    switch (value) {
      case null:
      case 'none':
        return ReminderType.none;
      case 'once':
        return ReminderType.once;
      case 'daily':
        return ReminderType.daily;
      case 'everyNDays':
        return ReminderType.everyNDays;
      case 'weekday':
        return ReminderType.weekday;
      default:
        throw FormatException('Unknown reminder type in database: "$value"');
    }
  }
}

/// A single task row, covering both To-do and To-don't items.
///
/// [id] is null for a task that has not been persisted yet.
/// A non-null [deletedAt] means the task is sitting in the trash rather
/// than being permanently gone.
class TaskModel {
  final int? id;
  final String title;
  final String? description;
  final TaskType type;
  final bool isDone;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final ReminderType reminderType;
  // Stored as "HH:mm" (24h), e.g. "22:00". Null when reminderType is none.
  final String? reminderTime;
  // Only meaningful when reminderType is everyNDays.
  final int? reminderIntervalDays;
  // ISO-8601 weekday numbers (1=Monday .. 7=Sunday). Only meaningful when
  // reminderType is weekday.
  final List<int>? reminderWeekdays;

  TaskModel({
    this.id,
    required this.title,
    this.description,
    required this.type,
    this.isDone = false,
    this.dueDate,
    this.completedAt,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.reminderType = ReminderType.none,
    this.reminderTime,
    this.reminderIntervalDays,
    this.reminderWeekdays,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'Title must not be empty');
    }
    if (reminderType != ReminderType.none && reminderTime == null) {
      throw ArgumentError(
        'reminderTime is required whenever reminderType is not none',
      );
    }
    if (reminderType == ReminderType.everyNDays &&
        (reminderIntervalDays == null || reminderIntervalDays! < 1)) {
      throw ArgumentError(
        'reminderIntervalDays must be a positive number for reminderType.everyNDays',
      );
    }
    if (reminderType == ReminderType.weekday &&
        (reminderWeekdays == null || reminderWeekdays!.isEmpty)) {
      throw ArgumentError(
        'reminderWeekdays must be non-empty for reminderType.weekday',
      );
    }
  }

  bool get isInTrash => deletedAt != null;

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    TaskType? type,
    bool? isDone,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? sortOrder,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    ReminderType? reminderType,
    String? reminderTime,
    int? reminderIntervalDays,
    List<int>? reminderWeekdays,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      isDone: isDone ?? this.isDone,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      reminderType: reminderType ?? this.reminderType,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderIntervalDays: reminderIntervalDays ?? this.reminderIntervalDays,
      reminderWeekdays: reminderWeekdays ?? this.reminderWeekdays,
    );
  }

  /// Serializes to a row map suitable for `sqflite` insert/update.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'type': type.toDbValue(),
      'is_done': isDone ? 1 : 0,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'sort_order': sortOrder,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
      'reminder_type': reminderType.toDbValue(),
      'reminder_time': reminderTime,
      'reminder_interval_days': reminderIntervalDays,
      'reminder_weekdays': reminderWeekdays?.join(','),
    };
  }

  /// Deserializes a row map read back from `sqflite`.
  ///
  /// Throws [FormatException] on a structurally invalid row (bad
  /// type value, missing required field), so the data-source layer
  /// can decide to skip just this one row instead of failing an
  /// entire query.
  factory TaskModel.fromMap(Map<String, Object?> map) {
    final rawTitle = map['title'];
    final rawType = map['type'];
    final rawCreatedAt = map['created_at'];
    final rawUpdatedAt = map['updated_at'];

    if (rawTitle is! String) {
      throw const FormatException('Task row missing a valid "title"');
    }
    if (rawType is! String) {
      throw const FormatException('Task row missing a valid "type"');
    }
    if (rawCreatedAt is! int) {
      throw const FormatException('Task row missing a valid "created_at"');
    }
    if (rawUpdatedAt is! int) {
      throw const FormatException('Task row missing a valid "updated_at"');
    }

    final rawDueDate = map['due_date'];
    final rawCompletedAt = map['completed_at'];
    final rawDeletedAt = map['deleted_at'];
    final rawWeekdays = map['reminder_weekdays'];

    return TaskModel(
      id: map['id'] as int?,
      title: rawTitle,
      description: map['description'] as String?,
      type: TaskType.fromDbValue(rawType),
      isDone: (map['is_done'] as int? ?? 0) == 1,
      dueDate: rawDueDate is int
          ? DateTime.fromMillisecondsSinceEpoch(rawDueDate)
          : null,
      completedAt: rawCompletedAt is int
          ? DateTime.fromMillisecondsSinceEpoch(rawCompletedAt)
          : null,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(rawCreatedAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(rawUpdatedAt),
      deletedAt: rawDeletedAt is int
          ? DateTime.fromMillisecondsSinceEpoch(rawDeletedAt)
          : null,
      reminderType: ReminderType.fromDbValue(map['reminder_type'] as String?),
      reminderTime: map['reminder_time'] as String?,
      reminderIntervalDays: map['reminder_interval_days'] as int?,
      reminderWeekdays: (rawWeekdays is String && rawWeekdays.isNotEmpty)
          ? rawWeekdays.split(',').map(int.parse).toList()
          : null,
    );
  }
}
