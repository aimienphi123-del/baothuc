import '../../models/task/task_model.dart';

/// Data-access contract used by the application layer. The
/// controller depends only on this interface, never on
/// [TaskLocalDataSource] directly — that seam is what lets the
/// persistence implementation change later without touching state
/// or UI code.
abstract class TaskRepository {
  Future<List<TaskModel>> getTasks({TaskType? type, bool? isDone});

  Future<TaskModel> addTask({
    required String title,
    String? description,
    required TaskType type,
    DateTime? dueDate,
    required ReminderType reminderType,
    String? reminderTime,
    int? reminderIntervalDays,
    List<int>? reminderWeekdays,
  });

  Future<void> editTask(TaskModel task);

  Future<TaskModel> duplicateTask(TaskModel task);

  Future<void> toggleDone(int id, bool isDone);

  /// Moves a task to the trash. Use [permanentlyDeleteTask] to remove
  /// it for good, or [restoreTask] to bring it back.
  Future<void> deleteTask(int id);

  Future<void> restoreTask(int id);

  Future<void> permanentlyDeleteTask(int id);

  Future<List<TaskModel>> getTrashTasks();

  /// Removes anything that has been in the trash longer than the
  /// app's retention window. Call this when the trash screen opens.
  Future<void> purgeExpiredTrash();

  /// Persists a new manual display order. [orderedIds] must list
  /// every id in the desired top-to-bottom order.
  Future<void> reorderTasks(List<int> orderedIds);
}
