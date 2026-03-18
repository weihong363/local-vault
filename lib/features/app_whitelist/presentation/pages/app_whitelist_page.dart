import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/features/app_whitelist/domain/providers/app_whitelist_provider.dart';
import 'package:local_vault/features/app_whitelist/models/app_info.dart';

enum _AppVisibilityFilter {
  all,
  selected,
  unselected,
}

class AppWhitelistPage extends ConsumerStatefulWidget {
  const AppWhitelistPage({super.key});

  @override
  ConsumerState<AppWhitelistPage> createState() => _AppWhitelistPageState();
}

class _AppWhitelistPageState extends ConsumerState<AppWhitelistPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _AppVisibilityFilter _visibilityFilter = _AppVisibilityFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索应用...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildWhitelistInfo(asyncWhitelist, ref),
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

  Widget _buildWhitelistInfo(
    AsyncValue<List<AppInfo>> asyncWhitelist,
    WidgetRef ref,
  ) {
    return asyncWhitelist.when(
      data: (whitelist) {
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '已选择 ${whitelist.length} 个应用',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (whitelist.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                      onPressed: () => _showClearDialog(context, ref),
                      tooltip: '清空白名单',
                    ),
                  ],
                ],
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
                      onDeleted: () {
                        ref.read(appWhitelistProvider.notifier).toggleApp(app);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }).toList(),
                ),
              if (whitelist.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '手势将在所有应用中生效',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                    label: '全部',
                    filter: _AppVisibilityFilter.all,
                  ),
                  _buildFilterChip(
                    label: '已选择',
                    filter: _AppVisibilityFilter.selected,
                  ),
                  _buildFilterChip(
                    label: '未选择',
                    filter: _AppVisibilityFilter.unselected,
                  ),
                ],
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

    final filteredApps = _searchQuery.isEmpty
        ? apps
        : apps.where((app) {
            final lowerQuery = _searchQuery.toLowerCase();
            return app.appName.toLowerCase().contains(lowerQuery) ||
                app.packageName.toLowerCase().contains(lowerQuery);
          }).toList();

    final visibleApps = filteredApps.where((app) {
      switch (_visibilityFilter) {
        case _AppVisibilityFilter.all:
          return true;
        case _AppVisibilityFilter.selected:
          return whitelist.contains(app);
        case _AppVisibilityFilter.unselected:
          return !whitelist.contains(app);
      }
    }).toList()
      ..sort((a, b) {
        final aSelected = whitelist.contains(a);
        final bSelected = whitelist.contains(b);
        if (aSelected != bSelected) {
          return aSelected ? -1 : 1;
        }
        return a.appName.toLowerCase().compareTo(b.appName.toLowerCase());
      });

    if (visibleApps.isEmpty) {
      final emptyTitle = switch (_visibilityFilter) {
        _AppVisibilityFilter.all =>
          _searchQuery.isEmpty ? '没有找到应用' : '没有找到匹配的应用',
        _AppVisibilityFilter.selected => '还没有已选择的应用',
        _AppVisibilityFilter.unselected => '没有未选择的应用',
      };

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.apps_outlined : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: visibleApps.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: Colors.grey[200],
      ),
      itemBuilder: (context, index) {
        final app = visibleApps[index];
        final isSelected = whitelist.contains(app);

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.android,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
              size: 28,
            ),
          ),
          title: Text(
            app.appName,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            app.packageName,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                )
              : null,
          onTap: () {
            ref.read(appWhitelistProvider.notifier).toggleApp(app);
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required _AppVisibilityFilter filter,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: _visibilityFilter == filter,
      onSelected: (selected) {
        if (!selected) return;
        setState(() {
          _visibilityFilter = filter;
        });
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(appWhitelistProvider.notifier).clearWhitelist();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清空白名单')),
              );
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}
