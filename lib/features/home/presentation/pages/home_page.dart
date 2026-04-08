import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/memory_runtime/repositories/state_repository.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';
import 'package:local_vault/features/home/presentation/pages/memory_processing_detail_page.dart';
import 'package:local_vault/features/home/presentation/presenters/memory_processing_presenter.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(summaryEntityNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('State overview'),
      ),
      body: summariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
        data: (summaries) {
          final stateRecords = sl<StateRepository>().getAllStateRecords();
          final dashboard = ref
              .watch(memoryProcessingPresenterProvider)
              .buildDashboard(summaries: summaries, stateRecords: stateRecords);

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(summaryEntityNotifierProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _panelHeader(
                  context,
                  title: 'Active events',
                  count: dashboard.activeEvents.length,
                ),
                ...dashboard.activeEvents.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.title),
                      subtitle: Text(item.preview, maxLines: 2),
                      trailing: Text(DateFormat('MM-dd HH:mm').format(item.createdAt)),
                      onTap: () => context.push(
                        AppRoutes.memoryProcessingDetail,
                        extra: MemoryProcessingDetailArgs(summaryId: item.id),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _panelHeader(
                  context,
                  title: 'Recent state updates',
                  count: dashboard.recentStateUpdates.length,
                ),
                ...dashboard.recentStateUpdates.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.key),
                      subtitle: Text(
                        '${item.topic} · ${item.classification} (${item.confidence.toStringAsFixed(2)})',
                      ),
                      trailing: Text(DateFormat('MM-dd HH:mm').format(item.updatedAt)),
                      onTap: () => context.push(
                        AppRoutes.memoryProcessingDetail,
                        extra: MemoryProcessingDetailArgs(
                          stateStorageKey: item.key,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _panelHeader(
                  context,
                  title: 'Pending / deferred memories',
                  count: dashboard.pendingOrDeferred.length,
                ),
                if (dashboard.pendingOrDeferred.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('No pending items'),
                    ),
                  ),
                ...dashboard.pendingOrDeferred.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.key),
                      subtitle: Text(
                        'deferred · ${item.reason}',
                        maxLines: 2,
                      ),
                      trailing: const Chip(label: Text('pending/deferred')),
                      onTap: () => context.push(
                        AppRoutes.memoryProcessingDetail,
                        extra: MemoryProcessingDetailArgs(
                          stateStorageKey: item.key,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _panelHeader(
    BuildContext context, {
    required String title,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          Chip(label: Text('$count')),
        ],
      ),
    );
  }
}
