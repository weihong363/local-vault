import 'package:flutter/material.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/services/storage_management_service.dart';
import 'package:local_vault/l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context)!;
    final confirmed = await _confirmAction(
      title: loc.clearModelCache,
      message: loc.clearModelCacheMessage,
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
              ? loc.noModelCacheFilesToClear
              : loc.clearedModelCacheResult(
                  '${result.deletedFileCount}',
                  StorageManagementService.formatBytes(result.releasedBytes),
                ),
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _clearBackups() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await _confirmAction(
      title: loc.clearBackupFiles,
      message: loc.clearBackupFilesMessage,
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
              ? loc.noBackupFilesToClear
              : loc.deletedBackupFilesResult(
                  '${result.deletedFileCount}',
                  StorageManagementService.formatBytes(result.releasedBytes),
                ),
        ),
      ),
    );
    await _refresh();
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
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
            child: Text(loc.continueLabel),
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
        title: Text(loc.storageSpace),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: loc.refresh,
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
                child: Text(loc.failedToReadStorageUsage('${snapshot.error}')),
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
                      Text(
                        loc.totalStorageUsed,
                        style: const TextStyle(
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
                        loc.storageOverviewCounts(
                          '${usage.summaryCount}',
                          '${usage.templateCount}',
                          '${usage.backupFileCount}',
                        ),
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
                title: loc.summaryDatabase,
                subtitle: loc.summaryDatabaseSubtitle('${usage.summaryCount}'),
                bytes: usage.summaryBytes,
                icon: Icons.article_outlined,
              ),
              _buildUsageTile(
                title: loc.templateDatabase,
                subtitle:
                    loc.templateDatabaseSubtitle('${usage.templateCount}'),
                bytes: usage.templateBytes,
                icon: Icons.description_outlined,
              ),
              _buildUsageTile(
                title: loc.backupFiles,
                subtitle: loc.backupFilesSubtitle('${usage.backupFileCount}'),
                bytes: usage.backupBytes,
                icon: Icons.backup_outlined,
              ),
              _buildUsageTile(
                title: loc.modelFile,
                subtitle: loc.bundledModelFootprint,
                bytes: usage.modelBytes,
                icon: Icons.memory_outlined,
              ),
              _buildUsageTile(
                title: loc.modelCache,
                subtitle: loc.inferenceCacheAndIntermediateFiles,
                bytes: usage.modelCacheBytes,
                icon: Icons.auto_delete_outlined,
              ),
              const SizedBox(height: 24),
              Text(
                loc.cleanupTools,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _clearModelCache,
                icon: const Icon(Icons.cleaning_services_outlined),
                label: Text(loc.clearModelCache),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _clearBackups,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(loc.clearLocalBackupFiles),
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
