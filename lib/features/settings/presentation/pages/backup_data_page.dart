import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';
import 'package:local_vault/core/providers/template_entities_provider.dart';
import 'package:local_vault/core/services/storage_management_service.dart';
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
    setState(() {
      _isWorking = true;
    });

    try {
      final result = await sl<StorageManagementService>().createBackup();
      await Share.shareXFiles(
        <XFile>[XFile(result.file.path)],
        text:
            'Local Vault 数据备份\n摘要 ${result.summaryCount} 条，模板 ${result.templateCount} 个',
        subject: 'Local Vault Backup',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '备份已生成：${result.file.path.split('/').last}',
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建备份失败：$error')),
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
        const SnackBar(content: Text('导入失败：无法读取所选文件')),
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

      final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      final exportedLabel = preview.exportedAt == null
          ? '未知时间'
          : formatter.format(preview.exportedAt!.toLocal());
      final confirmed = await _confirmAction(
        title: '导入备份',
        message:
            '检测到备份文件包含 ${preview.summaryCount} 条摘要、${preview.templateCount} 个模板。\n'
            '导出时间：$exportedLabel\n\n'
            '导入后会覆盖当前摘要与模板数据，是否继续？',
        confirmLabel: '导入',
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
            '导入完成：${result.summaryCount} 条摘要，${result.templateCount} 个模板',
          ),
        ),
      );
      await _refresh();
    } on FormatException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入失败：备份文件格式不正确')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败：$error')),
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
    await Share.shareXFiles(
      <XFile>[XFile(entry.file.path)],
      text: 'Local Vault 数据备份',
      subject: 'Local Vault Backup',
    );
  }

  Future<void> _restoreBackup(BackupFileEntry entry) async {
    final confirmed = await _confirmAction(
      title: '恢复备份',
      message: '恢复后会覆盖当前摘要与模板数据，是否继续？',
      confirmLabel: '恢复',
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
            '恢复完成：${result.summaryCount} 条摘要，${result.templateCount} 个模板',
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复备份失败：$error')),
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
    final confirmed = await _confirmAction(
      title: '删除备份',
      message: '确定要删除备份 ${entry.fileName} 吗？',
      confirmLabel: '删除',
    );
    if (confirmed != true) {
      return;
    }

    await sl<StorageManagementService>().deleteBackup(entry.file);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('备份已删除')),
    );
    await _refresh();
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('备份数据'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isWorking ? null : _refresh,
            tooltip: '刷新',
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
                child: Text('读取备份列表失败：${snapshot.error}'),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('还没有本地备份文件')),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '本地备份',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当前有 ${backups.length} 个备份文件',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '创建备份后会生成 JSON 文件并弹出分享面板；也可以从外部选择备份文件导入恢复。',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _isWorking ? null : _createBackup,
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(_isWorking ? '处理中...' : '创建并分享备份'),
                ),
                OutlinedButton.icon(
                  onPressed: _isWorking ? null : _importBackup,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('导入备份数据'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard(BackupFileEntry entry) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
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
                  label: const Text('分享'),
                  onPressed: _isWorking ? null : () => _shareBackup(entry),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('恢复'),
                  onPressed: _isWorking ? null : () => _restoreBackup(entry),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
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
