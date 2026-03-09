import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/features/summary/domain/providers/summary_provider.dart';
import 'package:local_vault/features/summary/presentation/widgets/empty_state.dart';
import 'package:local_vault/features/summary/presentation/widgets/summary_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummaries = ref.watch(summaryNotifierProvider);

    ref.listen(summaryNotifierProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('错误: ${next.error}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('本地记忆库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push(AppRoutes.save);
            },
          ),
        ],
      ),
      body: asyncSummaries.when(
        data: (summaries) {
          if (summaries.isEmpty) {
            return const EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(summaryNotifierProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                return SummaryCard(
                  summary: summaries[index],
                  onTap: () {
                    context.push(
                      AppRoutes.summaryDetail,
                      extra: summaries[index],
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
      ),
    );
  }
}
