import 'package:flutter/foundation.dart';

import '../../models/task/task_model.dart';
import '../../repositories/task/task_repository.dart';
import '../../repositories/task/task_repository_impl.dart';

enum TaskControllerStatus { initial, loading, ready, error }

/// Holds the task list currently shown on screen and exposes every
/// business workflow (add/edit/toggle/delete/reorder) the UI can
/// trigger. Contains no rendering code — [ChangeNotifier] is part
/// of the Flutter SDK itself, so this adds no new dependency.
class TaskController extends ChangeNotifier {
  final TaskRepository _repository;

  TaskController({TaskRepository? repository})
      : _repository = repository ?? TaskRepositoryImpl();

  TaskControllerStatus status = TaskControllerStatus.initial;
  List<TaskModel> tasks = [];
  String? errorMessage;

  TaskType? _typeFilter;
  bool? _isDoneFilter;

  /// Loads (or reloads) the list under the given filter. Passing no
  /// filter values keeps the previously used ones.
  Future<void> load({TaskType? type, bool? isDone}) async {
    _typeFilter = type;
    _isDoneFilter = isDone;
    status = TaskControllerStatus.loading;
    notifyListeners();

    try {
      tasks = await _repository.getTasks(type: _typeFilter, isDone: _isDoneFilter);
      status = TaskControllerStatus.ready;
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      status = TaskControllerStatus.error;
    }
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    String? description,
    required TaskType type,
    DateTime? dueDate,
    ReminderType reminderType = ReminderType.none,
    String? reminderTime,
    int? reminderIntervalDays,
    List<int>? reminderWeekdays,
  }) async {
    await _repository.addTask(
      title: title,
      description: description,
      type: type,
      dueDate: dueDate,
      reminderType: reminderType,
      reminderTime: reminderTime,
      reminderIntervalDays: reminderIntervalDays,
      reminderWeekdays: reminderWeekdays,
    );
    await _refresh();
  }

  Future<void> editTask(TaskModel task) async {
    await _repository.editTask(task);
    await _refresh();
  }

  Future<void> duplicateTask(TaskModel task) async {
    await _repository.duplicateTask(task);
    await _refresh();
  }

  Future<void> toggleDone(int id, bool isDone) async {
    await _repository.toggleDone(id, isDone);
    await _refresh();
  }

  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    await _refresh();
  }

  Future<void> reorderTasks(List<int> orderedIds) async {
    await _repository.reorderTasks(orderedIds);
    await _refresh();
  }

  /// Re-fetches the current filter's list after a mutation. Simple
  /// reload rather than in-memory patching — correct by
  /// construction, and plenty fast at the data volumes a personal
  /// to-do list has. Worth revisiting only if a real slowdown shows
  /// up later.
  Future<void> _refresh() => load(type: _typeFilter, isDone: _isDoneFilter);
}
