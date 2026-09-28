import 'package:flutter/material.dart';

import '../../core/calendar/lunar_calendar.dart';
import '../../core/localization/app_locale_controller.dart';
import '../../core/localization/strings.dart';

/// A standalone month calendar — deliberately not wired to tasks at
/// all, so it can't clutter or interfere with the task list.
///
/// The lunar date shown under each day comes from a real solar-to-
/// lunar conversion (see [LunarCalendar]), not a placeholder.
class CalendarScreen extends StatefulWidget {
  final AppLocaleController localeController;

  const CalendarScreen({super.key, required this.localeController});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    widget.localeController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    widget.localeController.removeListener(_onChanged);
    super.dispose();
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.localeController.lang);
    final now = DateTime.now();
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final startWeekday = (_visibleMonth.weekday - 1) % 7; // Mon=0..Sun=6
    final monthLabel = s.isVi
        ? 'Tháng ${_visibleMonth.month}/${_visibleMonth.year}'
        : '${_monthNameEn(_visibleMonth.month)} ${_visibleMonth.year}';

    return Scaffold(
      appBar: AppBar(title: Text(s.calendarTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shiftMonth(-1)),
                Text(monthLabel, style: Theme.of(context).textTheme.titleMedium),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shiftMonth(1)),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var d = 1; d <= 7; d++)
                  Center(
                    child: Text(
                      s.weekdayShort[d]!,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                for (var i = 0; i < startWeekday; i++) const SizedBox.shrink(),
                for (var day = 1; day <= daysInMonth; day++)
                  _buildDayCell(context, day, now),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              s.calendarNote,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, int day, DateTime now) {
    final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    final lunar = LunarCalendar.solarToLunar(date);
    // On the 1st of a lunar month, show "1/M" so it's clear which
    // lunar month is starting — the convention real lunar calendars
    // use, since otherwise every month restarts at "1" identically.
    final lunarLabel = lunar.day == 1
        ? '${lunar.day}/${lunar.month}${lunar.isLeapMonth ? 'n' : ''}'
        : '${lunar.day}';
    return _DayCell(
      day: day,
      lunarLabel: lunarLabel,
      isToday: _visibleMonth.year == now.year &&
          _visibleMonth.month == now.month &&
          day == now.day,
    );
  }

  String _monthNameEn(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final String lunarLabel;
  final bool isToday;

  const _DayCell({required this.day, required this.lunarLabel, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isToday ? theme.colorScheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$day', style: theme.textTheme.bodyMedium),
          Text(lunarLabel, style: theme.textTheme.labelSmall?.copyWith(color: theme.disabledColor)),
        ],
      ),
    );
  }
}
