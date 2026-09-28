import '../task/task_model.dart';

/// A saved, reusable reminder preset (e.g. "every 2 days at 22:00"),
/// so the user doesn't have to reconfigure the same reminder by hand
/// every time. Shares its reminder fields' shape with [TaskModel].
class RuleModel {
  final int? id;
  final ReminderType reminderType;
  final String reminderTime;
  final int? reminderIntervalDays;
  final List<int>? reminderWeekdays;
  final DateTime createdAt;

  RuleModel({
    this.id,
    required this.reminderType,
    required this.reminderTime,
    this.reminderIntervalDays,
    this.reminderWeekdays,
    required this.createdAt,
  }) {
    if (reminderType == ReminderType.none) {
      throw ArgumentError('A rule must have a real reminder type');
    }
    if (reminderType == ReminderType.everyNDays &&
        (reminderIntervalDays == null || reminderIntervalDays! < 1)) {
      throw ArgumentError(
        'reminderIntervalDays must be a positive number for ReminderType.everyNDays',
      );
    }
    if (reminderType == ReminderType.weekday &&
        (reminderWeekdays == null || reminderWeekdays!.isEmpty)) {
      throw ArgumentError(
        'reminderWeekdays must be non-empty for ReminderType.weekday',
      );
    }
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'reminder_type': reminderType.toDbValue(),
      'reminder_time': reminderTime,
      'reminder_interval_days': reminderIntervalDays,
      'reminder_weekdays': reminderWeekdays?.join(','),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory RuleModel.fromMap(Map<String, Object?> map) {
    final rawType = map['reminder_type'];
    final rawTime = map['reminder_time'];
    final rawCreatedAt = map['created_at'];
    final rawWeekdays = map['reminder_weekdays'];

    if (rawType is! String) {
      throw const FormatException('Rule row missing a valid "reminder_type"');
    }
    if (rawTime is! String) {
      throw const FormatException('Rule row missing a valid "reminder_time"');
    }
    if (rawCreatedAt is! int) {
      throw const FormatException('Rule row missing a valid "created_at"');
    }

    return RuleModel(
      id: map['id'] as int?,
      reminderType: ReminderType.fromDbValue(rawType),
      reminderTime: rawTime,
      reminderIntervalDays: map['reminder_interval_days'] as int?,
      reminderWeekdays: (rawWeekdays is String && rawWeekdays.isNotEmpty)
          ? rawWeekdays.split(',').map(int.parse).toList()
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(rawCreatedAt),
    );
  }
}
