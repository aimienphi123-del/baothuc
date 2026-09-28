import 'package:flutter/foundation.dart';

import '../../models/task/task_model.dart';
import '../../repositories/task/task_repository.dart';
import '../../repositories/task/task_repository_impl.dart';

/// Holds what's currently in the trash. Purges anything past the
/// retention window as soon as [load] runs — there is no background
/// scheduler in this app, so "opening the trash screen" is the purge
/// trigger.
class TrashController extends ChangeNotifier {
  final TaskRepository _repository;

  TrashController({TaskRepository? repository})
      : _repository = repository ?? TaskRepositoryImpl();

  List<TaskModel> items = [];
  bool isLoading = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    await _repository.purgeExpiredTrash();
    items = await _repository.getTrashTasks();
    isLoading = false;
    notifyListeners();
  }

  Future<void> restore(int id) async {
    await _repository.restoreTask(id);
    await load();
  }

  Future<void> deleteForever(int id) async {
    await _repository.permanentlyDeleteTask(id);
    await load();
  }
}
