import 'package:flutter/material.dart';

import '../../core/backup/backup_models.dart';
import '../../core/backup/backup_service.dart';
import '../../core/localization/app_locale_controller.dart';
import '../../core/localization/strings.dart';

class BackupScreen extends StatefulWidget {
  final AppLocaleController localeController;
  final BackupService? service;

  const BackupScreen({super.key, required this.localeController, this.service});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late final BackupService _service;
  bool _busy = false;

  Strings get _s => Strings(widget.localeController.lang);

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? BackupService();
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final file = await _service.exportToFile();
      _showMessage(_s.exportSuccess(file.path));
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final s = _s;
    if (!await _service.backupFileExists()) {
      _showMessage(s.noBackupFile);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.restoreConfirmTitle),
        content: Text(s.restoreConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(s.confirm)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final result = await _service.restoreFromFile();
      final message = StringBuffer(s.restoreSuccess(result.tasksRestored, result.rulesRestored));
      if (result.hadSkippedRows) {
        message.write('\n${s.skippedRows(result.skipped.length)}');
      }
      _showMessage(message.toString());
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _audit() async {
    setState(() => _busy = true);
    List<DataIssue> issues = [];
    try {
      issues = await _service.auditIntegrity();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    final s = _s;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(issues.isEmpty ? s.noIssuesFound : s.issuesFound(issues.length)),
        content: issues.isEmpty
            ? null
            : SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: issues.map((i) => Text('• $i')).toList(),
                ),
              ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      appBar: AppBar(title: Text(s.backupTitle)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Opacity(
          opacity: _busy ? 0.5 : 1,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: Text(s.exportBackup),
                onTap: _export,
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(s.restoreBackup),
                onTap: _restore,
              ),
              ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(s.checkIntegrity),
                onTap: _audit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
