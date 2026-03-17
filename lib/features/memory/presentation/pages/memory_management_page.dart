import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';

/// 记忆管理页面
class MemoryManagementPage extends ConsumerStatefulWidget {
  const MemoryManagementPage({super.key});

  @override
  ConsumerState<MemoryManagementPage> createState() =>
      _MemoryManagementPageState();
}

class _MemoryManagementPageState extends ConsumerState<MemoryManagementPage> {
  MemoryType _selectedType = MemoryType.fact;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final summariesState = ref.watch(summaryEntityNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshAndCleanup(),
            tooltip: '刷新并清理',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildSearchBar(),
          Expanded(
            child: summariesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('加载失败: $error'),
              ),
              data: (summaries) {
                final filtered = _filterSummaries(summaries);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('暂无记忆'),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildMemoryCard(filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<MemoryType>(
        segments: const [
          ButtonSegment(
            value: MemoryType.fact,
            label: Text('事实'),
          ),
          ButtonSegment(
            value: MemoryType.core,
            label: Text('核心'),
          ),
          ButtonSegment(
            value: MemoryType.session,
            label: Text('会话'),
          ),
          ButtonSegment(
            value: MemoryType.template,
            label: Text('模板'),
          ),
        ],
        selected: {_selectedType},
        onSelectionChanged: (selection) {
          setState(() {
            _selectedType = selection.first;
          });
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: const InputDecoration(
          hintText: '搜索记忆...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  List<SummaryEntity> _filterSummaries(List<SummaryEntity> summaries) {
    var filtered = summaries.where((s) => s.type == _selectedType).toList();

    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.title.toLowerCase().contains(lowerQuery) ||
            s.content.toLowerCase().contains(lowerQuery) ||
            s.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    }

    return filtered;
  }

  Widget _buildMemoryCard(SummaryEntity summary) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(
          summary.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            _buildStatsRow(summary),
          ],
        ),
        children: [
          _buildMemoryActions(summary),
        ],
      ),
    );
  }

  Widget _buildStatsRow(SummaryEntity summary) {
    return Wrap(
      spacing: 8,
      children: [
        Chip(
          label: Text('重要性: ${(summary.importance * 100).toInt()}%'),
          backgroundColor: _getImportanceColor(summary.importance),
        ),
        Chip(
          label: Text('访问: ${summary.accessCount}'),
        ),
        if (summary.lastAccessedAt != null)
          Chip(
            label: Text(
              '最后访问: ${DateFormat.yMd().format(summary.lastAccessedAt!)}',
            ),
          ),
      ],
    );
  }

  Color _getImportanceColor(double importance) {
    if (importance >= 0.8) return Colors.green.withValues(alpha: 0.3);
    if (importance >= 0.5) return Colors.yellow.withValues(alpha: 0.3);
    return Colors.red.withValues(alpha: 0.3);
  }

  Widget _buildMemoryActions(SummaryEntity summary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImportanceSlider(summary),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('编辑'),
                onPressed: () => _editMemory(summary),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.merge_type),
                label: const Text('合并相似'),
                onPressed: () => _mergeSimilarMemories(summary),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('删除'),
                onPressed: () => _deleteMemory(summary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportanceSlider(SummaryEntity summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('重要性评分'),
        Slider(
          value: summary.importance,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          label: '${(summary.importance * 100).toInt()}%',
          onChanged: (value) async {
            await ref
                .read(summaryEntityNotifierProvider.notifier)
                .updateImportance(summary.id, value);
          },
        ),
      ],
    );
  }

  Future<void> _refreshAndCleanup() async {
    await ref.read(summaryEntityNotifierProvider.notifier).refresh();
    await ref
        .read(summaryEntityNotifierProvider.notifier)
        .applyForgettingCurve();
    await ref
        .read(summaryEntityNotifierProvider.notifier)
        .cleanupSessionMemories();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已刷新并清理'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editMemory(SummaryEntity summary) async {
    // TODO: 实现编辑功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能开发中')),
    );
  }

  Future<void> _mergeSimilarMemories(SummaryEntity summary) async {
    final similar = ref
        .read(summaryEntityNotifierProvider.notifier)
        .findSimilarMemories(summary);

    if (similar.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有找到相似的记忆')),
        );
      }
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('合并相似记忆'),
        content: Text('找到 ${similar.length} 条相似记忆，是否合并？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('合并'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final sim in similar) {
        await ref
            .read(summaryEntityNotifierProvider.notifier)
            .mergeMemories(summary.id, sim.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('合并完成')),
        );
      }
    }
  }

  Future<void> _deleteMemory(SummaryEntity summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${summary.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(summaryEntityNotifierProvider.notifier)
          .deleteSummary(summary.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
      }
    }
  }
}
