import 'package:flutter/material.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/services/storage_management_service.dart';

class StorageSpacePage extends StatefulWidget {
  const StorageSpacePage({super.key});

  @override
  State<StorageSpacePage> createState() => _StorageSpacePageState();
}

class _StorageSpacePageState extends State<StorageSpacePage> {
  late Future<StorageUsageSnapshot> _usageFuture = _loadUsage();

  Future<StorageUsageSnapshot> _loadUsage() {
    return sl<StorageManagementService>().inspectStorage();
  }

  Future<void> _refresh() async {
    setState(() {
      _usageFuture = _loadUsage();
    });
  }

  Future<void> _clearModelCache() async {
    final confirmed = await _confirmAction(
      title: '清理模型缓存',
      message: '这会删除本地模型推理缓存，不会删除摘要、模板或模型文件本身。',
    );
    if (confirmed != true) {
      return;
    }

    final result = await sl<StorageManagementService>().clearModelCache();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.deletedFileCount == 0
              ? '没有可清理的模型缓存'
              : '已清理 ${result.deletedFileCount} 个缓存文件，释放 ${StorageManagementService.formatBytes(result.releasedBytes)}',
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _clearBackups() async {
    final confirmed = await _confirmAction(
      title: '清理备份文件',
      message: '这会删除本地生成的备份文件，但不会影响当前数据库中的摘要和模板。',
    );
    if (confirmed != true) {
      return;
    }

    final result = await sl<StorageManagementService>().clearBackupFiles();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.deletedFileCount == 0
              ? '没有可清理的备份文件'
              : '已删除 ${result.deletedFileCount} 个备份文件，释放 ${StorageManagementService.formatBytes(result.releasedBytes)}',
        ),
      ),
    );
    await _refresh();
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
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
            child: const Text('继续'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('存储空间'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: '刷新',
          ),
        ],
      ),
      body: FutureBuilder<StorageUsageSnapshot>(
        future: _usageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('读取存储信息失败：${snapshot.error}'),
              ),
            );
          }

          final usage = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '当前总占用',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        StorageManagementService.formatBytes(usage.totalBytes),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${usage.summaryCount} 条摘要 · ${usage.templateCount} 个模板 · ${usage.backupFileCount} 个备份',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildUsageTile(
                title: '摘要数据库',
                subtitle: '${usage.summaryCount} 条摘要',
                bytes: usage.summaryBytes,
                icon: Icons.article_outlined,
              ),
              _buildUsageTile(
                title: '模板数据库',
                subtitle: '${usage.templateCount} 个模板',
                bytes: usage.templateBytes,
                icon: Icons.description_outlined,
              ),
              _buildUsageTile(
                title: '备份文件',
                subtitle: '${usage.backupFileCount} 个备份',
                bytes: usage.backupBytes,
                icon: Icons.backup_outlined,
              ),
              _buildUsageTile(
                title: '模型文件',
                subtitle: '内置模型占用',
                bytes: usage.modelBytes,
                icon: Icons.memory_outlined,
              ),
              _buildUsageTile(
                title: '模型缓存',
                subtitle: '推理缓存与中间文件',
                bytes: usage.modelCacheBytes,
                icon: Icons.auto_delete_outlined,
              ),
              const SizedBox(height: 24),
              const Text(
                '清理工具',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _clearModelCache,
                icon: const Icon(Icons.cleaning_services_outlined),
                label: const Text('清理模型缓存'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _clearBackups,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('清理本地备份文件'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUsageTile({
    required String title,
    required String subtitle,
    required int bytes,
    required IconData icon,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(StorageManagementService.formatBytes(bytes)),
    );
  }
}
