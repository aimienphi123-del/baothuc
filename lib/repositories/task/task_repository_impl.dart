import '../../datasources/task/task_local_datasource.dart';
import '../../models/task/task_model.dart';
import 'task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource _dataSource;

  TaskRepositoryImpl({TaskLocalDataSource? dataSource})
      : _dataSource = dataSource ?? TaskLocalDataSource();

  @override
  Future<List<TaskModel>> getTasks({TaskType? type, bool? isDone}) {
    return _dataSource.getTasks(type: type, isDone: isDone);
  }

  @override
  Future<TaskModel> addTask({
    required String title,
    String? description,
    required TaskType type,
    DateTime? dueDate,
    ReminderType reminderType = ReminderType.none,
    String? reminderTime,
    int? reminderIntervalDays,
    List<int>? reminderWeekdays,
  }) {
    final now = DateTime.now();
    // New items default to sort_order 0. Combined with the DAO's
    // "sort_order ASC, created_at DESC" ordering, this naturally
    // puts new items at the top of their group without needing to
    // renumber every existing row on each insert.
    final task = TaskModel(
      title: title,
      description: description,
      type: type,
      dueDate: dueDate,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
      reminderType: reminderType,
      reminderTime: reminderTime,
      reminderIntervalDays: reminderIntervalDays,
      reminderWeekdays: reminderWeekdays,
    );
    return _dataSource.insertTask(task);
  }

  @override
  Future<void> editTask(TaskModel task) {
    return _dataSource.updateTask(task.copyWith(updatedAt: DateTime.now()));
  }

  @override
  Future<TaskModel> duplicateTask(TaskModel task) {
    final now = DateTime.now();
    // Built directly rather than via copyWith: a duplicate needs a
    // fresh id, createdAt and updatedAt, and always starts undone —
    // copyWith's job is preserving fields, not resetting them.
    return _dataSource.insertTask(
      TaskModel(
        title: task.title,
        description: task.description,
        type: task.type,
        isDone: false,
        dueDate: task.dueDate,
        sortOrder: task.sortOrder,
        createdAt: now,
        updatedAt: now,
        reminderType: task.reminderType,
        reminderTime: task.reminderTime,
        reminderIntervalDays: task.reminderIntervalDays,
        reminderWeekdays: task.reminderWeekdays,
      ),
    );
  }

  @override
  Future<void> toggleDone(int id, bool isDone) {
    return _dataSource.setDone(id, isDone);
  }

  @override
  Future<void> deleteTask(int id) {
    return _dataSource.softDeleteTask(id);
  }

  @override
  Future<void> restoreTask(int id) {
    return _dataSource.restoreTask(id);
  }

  @override
  Future<void> permanentlyDeleteTask(int id) {
    return _dataSource.deleteTask(id);
  }

  @override
  Future<List<TaskModel>> getTrashTasks() {
    return _dataSource.getTrashTasks();
  }

  @override
  Future<void> purgeExpiredTrash() {
    return _dataSource.purgeExpiredTrash();
  }

  @override
  Future<void> reorderTasks(List<int> orderedIds) {
    final idToSortOrder = <int, int>{
      for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
    };
    return _dataSource.updateSortOrders(idToSortOrder);
  }
}
