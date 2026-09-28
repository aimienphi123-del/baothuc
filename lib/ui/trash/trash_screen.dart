import 'package:flutter/material.dart';

import '../../core/localization/app_locale_controller.dart';
import '../../core/localization/strings.dart';
import 'trash_controller.dart';

class TrashScreen extends StatefulWidget {
  final AppLocaleController localeController;
  final TrashController? controller;

  const TrashScreen({super.key, required this.localeController, this.controller});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late final TrashController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TrashController();
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

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.localeController.lang);
    return Scaffold(
      appBar: AppBar(title: Text(s.trashTitle)),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    s.trashCount(_controller.items.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: _controller.items.isEmpty
                      ? Center(child: Text(s.trashEmpty))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _controller.items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final task = _controller.items[index];
                            final daysLeft = 5 -
                                DateTime.now().difference(task.deletedAt!).inDays;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(task.title, overflow: TextOverflow.ellipsis),
                                        Text(
                                          s.daysLeft(daysLeft < 0 ? 0 : daysLeft),
                                          style: Theme.of(context).textTheme.labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: s.restore,
                                    icon: const Icon(Icons.restore),
                                    onPressed: () => _controller.restore(task.id!),
                                  ),
                                  IconButton(
                                    tooltip: s.deleteForever,
                                    icon: const Icon(Icons.close),
                                    onPressed: () => _controller.deleteForever(task.id!),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
