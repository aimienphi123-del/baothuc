import '../../models/rule/rule_model.dart';
import '../../models/task/task_model.dart';

abstract class RuleRepository {
  Future<List<RuleModel>> getRules();

  Future<RuleModel> addRule({
    required ReminderType reminderType,
    required String reminderTime,
    int? reminderIntervalDays,
    List<int>? reminderWeekdays,
  });

  Future<void> deleteRule(int id);
}
