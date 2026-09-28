import 'package:flutter/material.dart';

import '../../controllers/rule/rule_controller.dart';
import '../../controllers/task/task_controller.dart';
import '../../core/localization/app_locale_controller.dart';
import '../../core/localization/strings.dart';
import '../../core/theme/theme_controller.dart';
import '../../models/task/task_model.dart';
import '../backup/backup_screen.dart';
import '../calendar/calendar_screen.dart';
import '../rules/rules_screen.dart';
import '../task_form/task_form_sheet.dart';
import '../trash/trash_screen.dart';
import 'widgets/task_tile.dart';

enum _ViewMode { list, grid }

class TaskListScreen extends StatefulWidget {
  final TaskController controller;
  final ThemeController themeController;
  final AppLocaleController localeController;
  final RuleController? ruleController;

  const TaskListScreen({
    super.key,
    required this.controller,
    required this.themeController,
    required this.localeController,
    this.ruleController,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TaskType _mode = TaskType.todo;
  _ViewMode _viewMode = _ViewMode.list;
  bool _completedExpanded = false;
  late final RuleController _ruleController;

  TaskController get _controller => widget.controller;
  Strings get _s => Strings(widget.localeController.lang);

  @override
  void initState() {
    super.initState();
    _ruleController = widget.ruleController ?? RuleController();
    _controller.addListener(_onChanged);
    widget.localeController.addListener(_onChanged);
    widget.themeController.addListener(_onChanged);
    _controller.load(type: _mode);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    widget.localeController.removeListener(_onChanged);
    widget.themeController.removeListener(_onChanged);
    if (widget.ruleController == null) _ruleController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _switchMode(TaskType mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _completedExpanded = false;
    });
    _controller.load(type: mode);
  }

  Future<void> _openTaskSheet({TaskModel? task}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskFormSheet(
        controller: _controller,
        mode: _mode,
        existingTask: task,
        ruleController: _ruleController,
        localeController: widget.localeController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _s;
    final active = _controller.tasks.where((t) => !t.isDone).toList();
    final done = _controller.tasks.where((t) => t.isDone).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        actions: [
          TextButton(
            onPressed: widget.localeController.toggle,
            child: Text(
              widget.localeController.lang.name.toUpperCase(),
              style: TextStyle(color: theme.appBarTheme.foregroundColor),
            ),
          ),
          IconButton(
            icon: Icon(widget.themeController.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: widget.themeController.toggle,
          ),
          IconButton(
            icon: const Icon(Icons.rule_outlined),
            tooltip: s.rulesTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RulesScreen(localeController: widget.localeController, controller: _ruleController)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: s.trashTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TrashScreen(localeController: widget.localeController)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: s.calendarTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CalendarScreen(localeController: widget.localeController)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_backup_restore_outlined),
            tooltip: s.backupTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BackupScreen(localeController: widget.localeController)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskSheet(),
        tooltip: s.addTask,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<TaskType>(
              segments: [
                ButtonSegment(value: TaskType.todo, label: Text(s.tabTodo)),
                ButtonSegment(value: TaskType.dont, label: Text(s.tabDont)),
              ],
              selected: {_mode},
              onSelectionChanged: (sel) => _switchMode(sel.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: _mode == TaskType.todo ? s.pending : s.holding,
                    value: active.length,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    label: _mode == TaskType.todo ? s.doneToday : s.heldToday,
                    value: done.length,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.view_list),
                  isSelected: _viewMode == _ViewMode.list,
                  onPressed: () => setState(() => _viewMode = _ViewMode.list),
                ),
                IconButton(
                  icon: const Icon(Icons.grid_view),
                  isSelected: _viewMode == _ViewMode.grid,
                  onPressed: () => setState(() => _viewMode = _ViewMode.grid),
                ),
              ],
            ),
          ),
          Expanded(
            child: _controller.status == TaskControllerStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    children: [
                      if (active.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text(s.emptyList)),
                        )
                      else if (_viewMode == _ViewMode.list)
                        _buildReorderableList(active)
                      else
                        _buildGrid(active),
                      if (done.isNotEmpty) _buildCompletedSection(done, s),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableList(List<TaskModel> active) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: active.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        final reordered = List.of(active);
        final moved = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, moved);
        _controller.reorderTasks(reordered.map((t) => t.id!).toList());
      },
      itemBuilder: (context, index) {
        final task = active[index];
        return Padding(
          key: ValueKey(task.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskTile(
            task: task,
            onTap: () => _openTaskSheet(task: task),
            onToggle: (v) => _controller.toggleDone(task.id!, v),
            onDuplicate: () => _controller.duplicateTask(task),
            onDelete: () => _controller.deleteTask(task.id!),
            localeController: widget.localeController,
            dragHandle: ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.drag_indicator, size: 18),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<TaskModel> active) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 128,
      ),
      itemCount: active.length,
      itemBuilder: (context, index) {
        final task = active[index];
        return TaskTile(
          key: ValueKey(task.id),
          task: task,
          dense: true,
          onTap: () => _openTaskSheet(task: task),
          onToggle: (v) => _controller.toggleDone(task.id!, v),
          onDuplicate: () => _controller.duplicateTask(task),
          onDelete: () => _controller.deleteTask(task.id!),
          localeController: widget.localeController,
        );
      },
    );
  }

  Widget _buildCompletedSection(List<TaskModel> done, Strings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _completedExpanded = !_completedExpanded),
          icon: AnimatedRotation(
            turns: _completedExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.expand_more, size: 18),
          ),
          label: Text(s.completed(done.length)),
        ),
        if (_completedExpanded)
          _viewMode == _ViewMode.grid
              ? _buildGrid(done)
              : Column(
                  children: done
                      .map(
                        (task) => Padding(
                          key: ValueKey(task.id),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TaskTile(
                            task: task,
                            onTap: () => _openTaskSheet(task: task),
                            onToggle: (v) => _controller.toggleDone(task.id!, v),
                            onDuplicate: () => _controller.duplicateTask(task),
                            onDelete: () => _controller.deleteTask(task.id!),
                            localeController: widget.localeController,
                          ),
                        ),
                      )
                      .toList(),
                ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;

  const _MetricCard({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text('$value', style: theme.textTheme.headlineSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
