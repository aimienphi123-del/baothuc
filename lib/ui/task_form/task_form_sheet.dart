import 'package:flutter/material.dart';

import '../../controllers/rule/rule_controller.dart';
import '../../controllers/task/task_controller.dart';
import '../../core/localization/app_locale_controller.dart';
import '../../core/localization/strings.dart';
import '../../models/rule/rule_model.dart';
import '../../models/task/task_model.dart';

const List<int> _weekdayOrder = [1, 2, 3, 4, 5, 6, 7]; // Mon..Sun

/// Add/edit sheet for a single task. The same form serves both:
/// [existingTask] null means "new task", non-null means "editing".
class TaskFormSheet extends StatefulWidget {
  final TaskController controller;
  final TaskType mode;
  final TaskModel? existingTask;
  final RuleController? ruleController;
  final AppLocaleController localeController;

  const TaskFormSheet({
    super.key,
    required this.controller,
    required this.mode,
    required this.localeController,
    this.existingTask,
    this.ruleController,
  });

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  late final RuleController _ruleController;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _customDaysController = TextEditingController(text: '2');
  final _formKey = GlobalKey<FormState>();

  DateTime? _dueDate;
  ReminderType _reminderType = ReminderType.none;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);
  Set<int> _selectedWeekdays = {1, 2, 3, 4, 5};

  bool get _isEditing => widget.existingTask != null;
  Strings get _s => Strings(widget.localeController.lang);

  @override
  void initState() {
    super.initState();
    _ruleController = widget.ruleController ?? RuleController();
    _ruleController.addListener(_onChanged);
    _ruleController.load();
    widget.localeController.addListener(_onChanged);

    final task = widget.existingTask;
    if (task != null) {
      _titleController.text = task.title;
      _descController.text = task.description ?? '';
      _dueDate = task.dueDate;
      _reminderType = task.reminderType;
      if (task.reminderTime != null) {
        final parts = task.reminderTime!.split(':');
        _reminderTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (task.reminderIntervalDays != null) {
        _customDaysController.text = task.reminderIntervalDays.toString();
      }
      if (task.reminderWeekdays != null) {
        _selectedWeekdays = task.reminderWeekdays!.toSet();
      }
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _ruleController.removeListener(_onChanged);
    widget.localeController.removeListener(_onChanged);
    if (widget.ruleController == null) _ruleController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) setState(() => _reminderTime = picked);
  }

  void _applyRule(RuleModel rule) {
    setState(() {
      _reminderType = rule.reminderType;
      final parts = rule.reminderTime.split(':');
      _reminderTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      if (rule.reminderIntervalDays != null) {
        _customDaysController.text = rule.reminderIntervalDays.toString();
      }
      if (rule.reminderWeekdays != null) {
        _selectedWeekdays = rule.reminderWeekdays!.toSet();
      }
    });
  }

  Future<void> _saveAsRule() async {
    if (_reminderType == ReminderType.none) return;
    await _ruleController.saveRule(
      reminderType: _reminderType,
      reminderTime: _formatTime(_reminderTime),
      reminderIntervalDays: _reminderType == ReminderType.everyNDays
          ? int.tryParse(_customDaysController.text)
          : null,
      reminderWeekdays: _reminderType == ReminderType.weekday
          ? _selectedWeekdays.toList()
          : null,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final reminderTime = _reminderType == ReminderType.none ? null : _formatTime(_reminderTime);
    final intervalDays = _reminderType == ReminderType.everyNDays
        ? int.tryParse(_customDaysController.text) ?? 1
        : null;
    final weekdays = _reminderType == ReminderType.weekday ? _selectedWeekdays.toList() : null;

    if (_isEditing) {
      final updated = widget.existingTask!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
        reminderType: _reminderType,
        reminderTime: reminderTime,
        reminderIntervalDays: intervalDays,
        reminderWeekdays: weekdays,
      );
      await widget.controller.editTask(updated);
    } else {
      await widget.controller.addTask(
        title: _titleController.text.trim(),
        description: _descController.text,
        type: widget.mode,
        dueDate: _dueDate,
        reminderType: _reminderType,
        reminderTime: reminderTime,
        reminderIntervalDays: intervalDays,
        reminderWeekdays: weekdays,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditing ? s.taskDetails : s.newTask,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: s.titleLabel),
                validator: (v) => (v == null || v.trim().isEmpty) ? s.titleRequired : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: s.notesLabel),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dueDate == null ? s.noDueDate : s.dueOn('${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}')),
                trailing: Wrap(children: [
                  if (_dueDate != null)
                    IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _dueDate = null)),
                  IconButton(icon: const Icon(Icons.event), onPressed: _pickDueDate),
                ]),
              ),
              const SizedBox(height: 8),
              Text(s.reminderLabel, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              DropdownButtonFormField<ReminderType>(
                value: _reminderType,
                items: [
                  DropdownMenuItem(value: ReminderType.none, child: Text(s.remNone)),
                  DropdownMenuItem(value: ReminderType.once, child: Text(s.remOnce)),
                  DropdownMenuItem(value: ReminderType.daily, child: Text(s.remDaily)),
                  DropdownMenuItem(value: ReminderType.everyNDays, child: Text(s.remEveryN)),
                  DropdownMenuItem(value: ReminderType.weekday, child: Text(s.remWeekday)),
                ],
                onChanged: (v) => setState(() => _reminderType = v ?? ReminderType.none),
              ),
              if (_reminderType != ReminderType.none) ...[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.atTime(_formatTime(_reminderTime))),
                  trailing: IconButton(icon: const Icon(Icons.access_time), onPressed: _pickReminderTime),
                ),
              ],
              if (_reminderType == ReminderType.everyNDays) ...[
                Row(
                  children: [
                    Text('${s.everyPrefix} '),
                    SizedBox(
                      width: 64,
                      child: TextFormField(
                        controller: _customDaysController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Text(' ${s.daysSuffix}'),
                  ],
                ),
              ],
              if (_reminderType == ReminderType.weekday) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: _weekdayOrder.map((d) {
                    final selected = _selectedWeekdays.contains(d);
                    return FilterChip(
                      label: Text(s.weekdayShort[d]!),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selectedWeekdays.add(d);
                        } else {
                          _selectedWeekdays.remove(d);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ],
              if (_ruleController.rules.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(s.applyRule, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: _ruleController.rules.map((r) {
                    return InputChip(
                      label: Text(_ruleLabel(s, r)),
                      onPressed: () => _applyRule(r),
                      onDeleted: () => _ruleController.deleteRule(r.id!),
                    );
                  }).toList(),
                ),
              ],
              if (_reminderType != ReminderType.none)
                TextButton(
                  onPressed: _saveAsRule,
                  child: Text(s.saveAsRule),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(_isEditing ? s.close : s.cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(onPressed: _save, child: Text(s.save)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ruleLabel(Strings s, RuleModel r) {
    switch (r.reminderType) {
      case ReminderType.once:
        return s.atTime(r.reminderTime);
      case ReminderType.daily:
        return '${s.remDaily} — ${s.atTime(r.reminderTime)}';
      case ReminderType.everyNDays:
        return '${s.everyPrefix} ${r.reminderIntervalDays} ${s.daysSuffix} — ${s.atTime(r.reminderTime)}';
      case ReminderType.weekday:
        final days = (r.reminderWeekdays ?? []).map((d) => s.weekdayShort[d]).join(',');
        return '$days — ${s.atTime(r.reminderTime)}';
      case ReminderType.none:
        return s.remNone;
    }
  }
}
