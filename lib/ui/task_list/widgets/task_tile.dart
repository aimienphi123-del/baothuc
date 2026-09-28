import 'package:flutter/material.dart';

import '../../../core/localization/app_locale_controller.dart';
import '../../../core/localization/strings.dart';
import '../../../models/task/task_model.dart';

/// How a tile should leave the screen. Kept visually distinct on
/// purpose: completing something should read as "this is finished",
/// deleting it should read as "this is no longer here".
enum _ExitKind { complete, delete }

/// A single task's visual content plus its three signature motions:
/// a settled drop-in on first appearance, a small satisfying reaction
/// when marked done, and a distinct slide-away when deleted. Used for
/// both the list row and the grid card — [dense] switches the layout.
class TaskTile extends StatefulWidget {
  final TaskModel task;
  final bool dense;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final Widget? dragHandle;
  final AppLocaleController localeController;

  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDuplicate,
    required this.onDelete,
    required this.localeController,
    this.dense = false,
    this.dragHandle,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile>
    with TickerProviderStateMixin {
  // Entrance: runs once per tile identity (a fresh insert or a
  // restore/duplicate), never on ordinary rebuilds.
  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entranceOffset;

  // Exit: only started right before this tile is actually removed
  // from its list, so the removal itself never looks like a jump-cut.
  late final AnimationController _exitController;
  _ExitKind? _exitKind;

  // A quick press reaction before an important action, per the
  // "anticipation before action" rhythm — subtle, not a bounce.
  double _pressScale = 1.0;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _entranceOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceOffset = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckboxTap() async {
    final willBeDone = !widget.task.isDone;
    if (!willBeDone) {
      // Un-checking: no exit choreography needed, it simply reappears
      // in the active area on the next build.
      widget.onToggle(false);
      return;
    }
    setState(() => _pressScale = 0.97);
    await Future.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    setState(() => _pressScale = 1.0);
    // Give the checkmark a moment to register before the tile leaves.
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    await _runExit(_ExitKind.complete);
    widget.onToggle(true);
  }

  Future<void> _handleDeleteTap() async {
    setState(() => _pressScale = 0.97);
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    setState(() => _pressScale = 1.0);
    await _runExit(_ExitKind.delete);
    widget.onDelete();
  }

  Future<void> _runExit(_ExitKind kind) async {
    setState(() => _exitKind = kind);
    await _exitController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = widget.task;

    Widget content = _TaskContent(
      task: task,
      dense: widget.dense,
      onCheckboxTap: _handleCheckboxTap,
      onDuplicate: widget.onDuplicate,
      onDelete: _handleDeleteTap,
      dragHandle: widget.dragHandle,
      localeController: widget.localeController,
    );

    content = AnimatedScale(
      scale: _pressScale,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: content,
    );

    content = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: widget.onTap,
      child: content,
    );

    // Exit motion: completing drifts gently downward, deleting slides
    // sideways with a slight tilt — different enough to feel like two
    // different things happened, not one generic "item vanished".
    content = AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_exitController.value);
        Offset offset = Offset.zero;
        double rotation = 0;
        if (_exitKind == _ExitKind.complete) {
          offset = Offset(0, 10 * t);
        } else if (_exitKind == _ExitKind.delete) {
          offset = Offset(-24 * t, 0);
          rotation = -0.05 * t;
        }
        return Opacity(
          opacity: 1 - t,
          child: Transform.translate(
            offset: offset,
            child: Transform.rotate(angle: rotation, child: child),
          ),
        );
      },
      child: content,
    );

    return FadeTransition(
      opacity: _entranceOpacity,
      child: SlideTransition(position: _entranceOffset, child: content),
    );
  }
}

class _TaskContent extends StatelessWidget {
  final TaskModel task;
  final bool dense;
  final VoidCallback onCheckboxTap;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final Widget? dragHandle;
  final AppLocaleController localeController;

  const _TaskContent({
    required this.task,
    required this.dense,
    required this.onCheckboxTap,
    required this.onDuplicate,
    required this.onDelete,
    required this.dragHandle,
    required this.localeController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = task.isDone;

    final checkbox = _AnimatedCheckbox(isDone: task.isDone, onTap: onCheckboxTap);

    final title = Text(
      task.title,
      maxLines: dense ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: muted
            ? theme.disabledColor
            : theme.textTheme.bodyMedium?.color,
        decoration: muted ? TextDecoration.lineThrough : null,
      ),
    );

    final s = Strings(localeController.lang);
    final badges = _DueAndReminderBadges(task: task, s: s);

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.copy_outlined, size: 18),
          tooltip: s.isVi ? 'Sao chép' : 'Duplicate',
          onPressed: onDuplicate,
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          tooltip: s.isVi ? 'Xoá' : 'Delete',
          onPressed: onDelete,
          visualDensity: VisualDensity.compact,
        ),
        if (dragHandle != null) dragHandle!,
      ],
    );

    final container = Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(dense ? 12 : 10),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: dense
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [checkbox, actions],
                ),
                const SizedBox(height: 8),
                title,
                if (badges.hasContent) ...[
                  const SizedBox(height: 4),
                  badges,
                ],
              ],
            )
          : Row(
              children: [
                checkbox,
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      title,
                      if (badges.hasContent) ...[
                        const SizedBox(height: 4),
                        badges,
                      ],
                    ],
                  ),
                ),
                actions,
              ],
            ),
    );

    return container;
  }
}

/// The completion mark: a plain circle that fills and shows a small
/// check icon that scales in — restrained on purpose, per the
/// "avoid exaggerated bouncing" direction for this specific control.
class _AnimatedCheckbox extends StatelessWidget {
  final bool isDone;
  final VoidCallback onTap;

  const _AnimatedCheckbox({required this.isDone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? theme.colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: isDone
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: 1.5,
          ),
        ),
        child: AnimatedScale(
          scale: isDone ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary),
        ),
      ),
    );
  }
}

class _DueAndReminderBadges extends StatelessWidget {
  final TaskModel task;
  final Strings s;

  const _DueAndReminderBadges({required this.task, required this.s});

  bool get hasContent => task.dueDate != null || task.reminderType != ReminderType.none;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[];

    if (task.dueDate != null) {
      final daysUntil = task.dueDate!.difference(DateTime.now()).inDays;
      final (label, color) = _dueLabelAndColor(daysUntil, theme);
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event, size: 11, color: color),
              const SizedBox(width: 4),
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
            ],
          ),
        ),
      );
    }

    if (task.reminderType != ReminderType.none && task.reminderTime != null) {
      chips.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_outlined, size: 12, color: theme.colorScheme.outline),
            const SizedBox(width: 2),
            Text(task.reminderTime!, style: theme.textTheme.labelSmall),
          ],
        ),
      );
    }

    return Wrap(spacing: 6, runSpacing: 2, children: chips);
  }

  (String, Color) _dueLabelAndColor(int daysUntil, ThemeData theme) {
    if (daysUntil < 0) return (s.overdue(-daysUntil), theme.colorScheme.error);
    if (daysUntil == 0) return (s.today, theme.colorScheme.error);
    if (daysUntil == 1) return (s.tomorrow, theme.colorScheme.error);
    if (daysUntil <= 5) return (s.inDays(daysUntil), Colors.orange.shade800);
    return (s.inDays(daysUntil), theme.colorScheme.outline);
  }
}
