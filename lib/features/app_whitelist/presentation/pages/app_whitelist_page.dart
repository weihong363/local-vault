import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/features/app_whitelist/domain/providers/app_whitelist_provider.dart';
import 'package:local_vault/features/app_whitelist/models/app_info.dart';
import 'package:local_vault/l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context)!;
    final asyncWhitelist = ref.watch(appWhitelistProvider);
    final asyncInstalledApps = ref.watch(installedAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appAllowlist),
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
                hintText: loc.searchAppsHint,
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
              error: (error, stack) => Center(
                child: Text(loc.appWhitelistLoadFailed('$error')),
              ),
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
    final loc = AppLocalizations.of(context)!;
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
                    loc.selectedAppsCount('${whitelist.length}'),
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
                      tooltip: loc.clearAllowlistTooltip,
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
                          loc.gesturesActiveInAllApps,
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
                    label: loc.filterAll,
                    filter: _AppVisibilityFilter.all,
                  ),
                  _buildFilterChip(
                    label: loc.filterSelected,
                    filter: _AppVisibilityFilter.selected,
                  ),
                  _buildFilterChip(
                    label: loc.filterUnselected,
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
    final loc = AppLocalizations.of(context)!;
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
          _searchQuery.isEmpty ? loc.noAppsFound : loc.noMatchingAppsFound,
        _AppVisibilityFilter.selected => loc.noSelectedAppsYet,
        _AppVisibilityFilter.unselected => loc.noUnselectedApps,
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
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.clearAllowlistTitle),
        content: Text(loc.clearAllowlistMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancelLabel),
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
                SnackBar(content: Text(loc.allowlistCleared)),
              );
            },
            child: Text(loc.clearLabel),
          ),
        ],
      ),
    );
  }
}
