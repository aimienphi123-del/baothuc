import 'package:flutter/material.dart';

import '../../controllers/rule/rule_controller.dart';
import '../../core/localization/app_locale_controller.dart';
import '../../core/localization/strings.dart';
import '../../models/rule/rule_model.dart';
import '../../models/task/task_model.dart';

class RulesScreen extends StatefulWidget {
  final AppLocaleController localeController;
  final RuleController? controller;

  const RulesScreen({super.key, required this.localeController, this.controller});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  late final RuleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? RuleController();
    _controller.addListener(_onChanged);
    _controller.load();
    widget.localeController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    widget.localeController.removeListener(_onChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  String _label(Strings s, RuleModel r) {
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

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.localeController.lang);
    return Scaffold(
      appBar: AppBar(title: Text(s.rulesTitle)),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(s.rulesNote, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 12),
                if (_controller.rules.isEmpty)
                  Center(child: Text(s.rulesEmpty))
                else
                  ..._controller.rules.map(
                    (r) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: Text(_label(s, r)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _controller.deleteRule(r.id!),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
