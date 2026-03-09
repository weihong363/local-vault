import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/features/app_whitelist/models/app_info.dart';
import 'package:local_vault/features/app_whitelist/domain/providers/app_whitelist_provider.dart';

class AppWhitelistPage extends ConsumerWidget {
  const AppWhitelistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWhitelist = ref.watch(appWhitelistProvider);
    final asyncInstalledApps = ref.watch(installedAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('应用白名单'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWhitelistInfo(asyncWhitelist),
          const Divider(height: 1),
          Expanded(
            child: asyncInstalledApps.when(
              data: (apps) => _buildAppList(context, ref, apps, asyncWhitelist),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('加载失败: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhitelistInfo(AsyncValue<List<AppInfo>> asyncWhitelist) {
    return asyncWhitelist.when(
      data: (whitelist) {
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '已选择 ${whitelist.length} 个应用',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (whitelist.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: whitelist.map((app) {
                    return Chip(
                      label: Text(app.appName),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {},
                    );
                  }).toList(),
                ),
              if (whitelist.isEmpty)
                Text(
                  '手势将在所有应用中生效',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildAppList(
    BuildContext context,
    WidgetRef ref,
    List<AppInfo> apps,
    AsyncValue<List<AppInfo>> asyncWhitelist,
  ) {
    final whitelist = asyncWhitelist.when(
      data: (list) => list,
      loading: () => <AppInfo>[],
      error: (_, __) => <AppInfo>[],
    );

    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final isSelected = whitelist.contains(app);
        
        return CheckboxListTile(
          title: Text(app.appName),
          subtitle: Text(app.packageName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          value: isSelected,
          onChanged: (_) {
            ref.read(appWhitelistProvider.notifier).toggleApp(app);
          },
        );
      },
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空白名单'),
        content: const Text('确定要清空应用白名单吗？手势将在所有应用中生效。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(appWhitelistProvider.notifier).clearWhitelist();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清空白名单')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
