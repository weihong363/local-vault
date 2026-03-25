import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';
import 'package:local_vault/core/providers/template_entities_provider.dart';
import 'package:local_vault/core/services/storage_management_service.dart';
import 'package:local_vault/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class BackupDataPage extends ConsumerStatefulWidget {
  const BackupDataPage({super.key});

  @override
  ConsumerState<BackupDataPage> createState() => _BackupDataPageState();
}

class _BackupDataPageState extends ConsumerState<BackupDataPage> {
  late Future<List<BackupFileEntry>> _backupsFuture = _loadBackups();
  bool _isWorking = false;

  Future<List<BackupFileEntry>> _loadBackups() {
    return sl<StorageManagementService>().listBackups();
  }

  Future<void> _refresh() async {
    setState(() {
      _backupsFuture = _loadBackups();
    });
  }

  Future<void> _createBackup() async {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _isWorking = true;
    });

    try {
      final result = await sl<StorageManagementService>().createBackup();
      await Share.shareXFiles(
        <XFile>[XFile(result.file.path)],
        text: loc.shareBackupText,
        subject: loc.shareBackupSubject,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.backupCreatedMessage(result.file.path.split('/').last),
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.importFailedMessage('$error'))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _importBackup() async {
    final loc = AppLocalizations.of(context)!;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );

    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final selectedPath = picked.files.single.path;
    if (selectedPath == null || selectedPath.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.importFailedUnableReadSelectedFile)),
      );
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      final file = File(selectedPath);
      final preview = await sl<StorageManagementService>().previewBackup(file);
      if (!mounted) {
        return;
      }

      final formatter =
          DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
              .add_Hms();
      final exportedLabel = preview.exportedAt == null
          ? loc.unknownValue
          : formatter.format(preview.exportedAt!.toLocal());
      final confirmed = await _confirmAction(
        title: loc.importBackup,
        message: loc.backupImportPreviewMessage(
          '${preview.summaryCount}',
          '${preview.templateCount}',
          exportedLabel,
        ),
        confirmLabel: loc.importBackup,
      );
      if (confirmed != true) {
        return;
      }

      final result = await sl<StorageManagementService>().restoreBackup(file);
      await ref.read(summaryEntityNotifierProvider.notifier).refresh();
      await ref.read(templateEntityNotifierProvider.notifier).refresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.importFinishedMessage(
              '${result.summaryCount}',
              '${result.templateCount}',
            ),
          ),
        ),
      );
      await _refresh();
    } on FormatException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.invalidBackupFileFormat)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.failedToCreateBackupMessage('$error'))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _shareBackup(BackupFileEntry entry) async {
    final loc = AppLocalizations.of(context)!;
    await Share.shareXFiles(
      <XFile>[XFile(entry.file.path)],
      text: loc.shareBackupText,
      subject: loc.shareBackupSubject,
    );
  }

  Future<void> _restoreBackup(BackupFileEntry entry) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await _confirmAction(
      title: loc.restoreLabel,
      message: loc.restoreBackupMessage,
      confirmLabel: loc.restoreLabel,
    );
    if (confirmed != true) {
      return;
    }

    setState(() {
      _isWorking = true;
    });
    try {
      final result =
          await sl<StorageManagementService>().restoreBackup(entry.file);
      await ref.read(summaryEntityNotifierProvider.notifier).refresh();
      await ref.read(templateEntityNotifierProvider.notifier).refresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.restoreFinishedMessage(
              '${result.summaryCount}',
              '${result.templateCount}',
            ),
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.restoreFailedMessage('$error'))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _deleteBackup(BackupFileEntry entry) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await _confirmAction(
      title: loc.deleteLabel,
      message: loc.deleteBackupConfirmMessage(entry.fileName),
      confirmLabel: loc.deleteLabel,
    );
    if (confirmed != true) {
      return;
    }

    await sl<StorageManagementService>().deleteBackup(entry.file);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.backupDeleted)),
    );
    await _refresh();
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    final loc = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.backupData),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isWorking ? null : _refresh,
            tooltip: loc.refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<BackupFileEntry>>(
        future: _backupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(loc.failedToLoadBackupList('${snapshot.error}')),
              ),
            );
          }

          final backups = snapshot.data ?? const <BackupFileEntry>[];
          return RefreshIndicator(
            onRefresh: _isWorking ? () async {} : _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBackupOverviewCard(backups),
                const SizedBox(height: 16),
                if (backups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text(loc.noLocalBackupFilesYet)),
                  ),
                for (final entry in backups) _buildBackupCard(entry),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackupOverviewCard(List<BackupFileEntry> backups) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.localBackups,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.backupFilesAvailable('${backups.length}'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(loc.backupOverviewDescription),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _isWorking ? null : _createBackup,
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(
                    _isWorking ? loc.workingLabel : loc.createAndShareBackup,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isWorking ? null : _importBackup,
                  icon: const Icon(Icons.file_download_outlined),
                  label: Text(loc.importBackupData),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard(BackupFileEntry entry) {
    final loc = AppLocalizations.of(context)!;
    final formatter =
        DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
            .add_Hms();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.fileName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBackupMetaChip(formatter.format(entry.modifiedAt)),
                _buildBackupMetaChip(
                  StorageManagementService.formatBytes(entry.bytes),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: Text(loc.shareLabel),
                  onPressed: _isWorking ? null : () => _shareBackup(entry),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.restore_outlined),
                  label: Text(loc.restoreLabel),
                  onPressed: _isWorking ? null : () => _restoreBackup(entry),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: Text(loc.deleteLabel),
                  onPressed: _isWorking ? null : () => _deleteBackup(entry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupMetaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
