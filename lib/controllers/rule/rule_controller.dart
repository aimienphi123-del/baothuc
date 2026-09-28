import 'package:flutter/foundation.dart';

import '../../models/rule/rule_model.dart';
import '../../models/task/task_model.dart';
import '../../repositories/rule/rule_repository.dart';
import '../../repositories/rule/rule_repository_impl.dart';

/// Holds the saved reminder rules and lets the task form save a new
/// one or apply/delete an existing one.
class RuleController extends ChangeNotifier {
  final RuleRepository _repository;

  RuleController({RuleRepository? repository})
      : _repository = repository ?? RuleRepositoryImpl();

  List<RuleModel> rules = [];
  bool isLoading = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    rules = await _repository.getRules();
    isLoading = false;
    notifyListeners();
  }

  Future<void> saveRule({
    required ReminderType reminderType,
    required String reminderTime,
    int? reminderIntervalDays,
    List<int>? reminderWeekdays,
  }) async {
    await _repository.addRule(
      reminderType: reminderType,
      reminderTime: reminderTime,
      reminderIntervalDays: reminderIntervalDays,
      reminderWeekdays: reminderWeekdays,
    );
    await load();
  }

  Future<void> deleteRule(int id) async {
    await _repository.deleteRule(id);
    await load();
  }
}
