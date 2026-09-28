import '../../datasources/rule/rule_local_datasource.dart';
import '../../models/rule/rule_model.dart';
import '../../models/task/task_model.dart';
import 'rule_repository.dart';

class RuleRepositoryImpl implements RuleRepository {
  final RuleLocalDataSource _dataSource;

  RuleRepositoryImpl({RuleLocalDataSource? dataSource})
      : _dataSource = dataSource ?? RuleLocalDataSource();

  @override
  Future<List<RuleModel>> getRules() => _dataSource.getRules();

  @override
  Future<RuleModel> addRule({
    required ReminderType reminderType,
    required String reminderTime,
    int? reminderIntervalDays,
    List<int>? reminderWeekdays,
  }) {
    return _dataSource.insertRule(
      RuleModel(
        reminderType: reminderType,
        reminderTime: reminderTime,
        reminderIntervalDays: reminderIntervalDays,
        reminderWeekdays: reminderWeekdays,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteRule(int id) => _dataSource.deleteRule(id);
}
