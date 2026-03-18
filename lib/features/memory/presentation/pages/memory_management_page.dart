import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/summary_merge_models.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';
import 'package:local_vault/core/theme/memory_theme.dart';
import 'package:local_vault/core/theme/memory_theme_config.dart';
import 'package:local_vault/features/memory/presentation/pages/memory_merge_diff_page.dart';
import 'package:local_vault/features/summary/presentation/widgets/empty_state.dart';

/// 记忆管理页面
class MemoryManagementPage extends ConsumerStatefulWidget {
  const MemoryManagementPage({super.key});

  @override
  ConsumerState<MemoryManagementPage> createState() =>
      _MemoryManagementPageState();
}

class _MemoryManagementPageState extends ConsumerState<MemoryManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedSummaryIds = <String>{};

  MemoryType _selectedType = MemoryType.fact;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summariesState = ref.watch(summaryEntityNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAndCleanup,
            tooltip: '刷新并清理',
          ),
        ],
      ),
      body: summariesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('加载失败: $error'),
          ),
        ),
        data: (summaries) {
          final filtered = _filterSummaries(summaries);
          final counts = _buildTypeCounts(summaries);

          return RefreshIndicator(
            onRefresh: _refreshAndCleanup,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildOverviewCard(
                  context,
                  allSummaries: summaries,
                  filteredSummaries: filtered,
                ),
                const SizedBox(height: 16),
                _buildTypeFilter(context, counts),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 20),
                if (filtered.isEmpty)
                  SizedBox(
                    height: 280,
                    child: EmptyState(message: _emptyMessage()),
                  )
                else
                  ...filtered.map(
                    (summary) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMemoryCard(context, summary),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context, {
    required List<SummaryEntity> allSummaries,
    required List<SummaryEntity> filteredSummaries,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _memoryTypeColor(context, _selectedType);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _memoryTypeIcon(_selectedType),
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _memoryTypeTitle(_selectedType),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _memoryTypeDescription(_selectedType),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MemoryStatChip(
                label: '当前分类',
                value: '${filteredSummaries.length} 条',
              ),
              _MemoryStatChip(
                label: '全部记忆',
                value: '${allSummaries.length} 条',
              ),
              _MemoryStatChip(
                label: '搜索状态',
                value: _searchQuery.isEmpty ? '未筛选' : '已筛选',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter(
    BuildContext context,
    Map<MemoryType, int> counts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '记忆类型',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MemoryType.values.map((type) {
            final isSelected = _selectedType == type;
            final accentColor = _memoryTypeColor(context, type);

            return ChoiceChip(
              label: Text('${_memoryTypeLabel(type)} ${counts[type] ?? 0}'),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedType = type;
                });
              },
              avatar: Icon(
                _memoryTypeIcon(type),
                size: 18,
                color: isSelected
                    ? accentColor
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              selectedColor: accentColor.withValues(alpha: 0.12),
              side: BorderSide(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.25)
                    : Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.45),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '搜索标题、内容或标签...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim();
        });
      },
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

    filtered.sort((a, b) {
      final left = a.updatedAt ?? a.createdAt;
      final right = b.updatedAt ?? b.createdAt;
      return right.compareTo(left);
    });

    return filtered;
  }

  Map<MemoryType, int> _buildTypeCounts(List<SummaryEntity> summaries) {
    return {
      for (final type in MemoryType.values)
        type: summaries.where((summary) => summary.type == type).length,
    };
  }

  Widget _buildMemoryCard(BuildContext context, SummaryEntity summary) {
    final isExpanded = _expandedSummaryIds.contains(summary.id);
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _memoryTypeColor(context, summary.type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? accentColor.withValues(alpha: 0.28)
              : colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSummaryIds.remove(summary.id);
                } else {
                  _expandedSummaryIds.add(summary.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accentColor.withValues(alpha: 0.14),
                    child: Text(
                      summary.title.isNotEmpty
                          ? summary.title.characters.first
                          : '?',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                summary.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _MemoryTypeBadge(type: summary.type),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          summary.content,
                          maxLines: isExpanded ? 5 : 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MemoryMetaChip(
                              label:
                                  '重要性 ${(summary.importance * 100).toInt()}%',
                              backgroundColor: _getImportanceColor(
                                context,
                                summary.importance,
                              ),
                            ),
                            _MemoryMetaChip(
                              label: '访问 ${summary.accessCount}',
                            ),
                            _MemoryMetaChip(
                              label:
                                  '更新 ${_formatDate(summary.updatedAt ?? summary.createdAt)}',
                            ),
                            if (summary.lastAccessedAt != null)
                              _MemoryMetaChip(
                                label:
                                    '最近访问 ${_formatDate(summary.lastAccessedAt!)}',
                              ),
                          ],
                        ),
                        if (summary.tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: summary.tags
                                .take(isExpanded ? summary.tags.length : 4)
                                .map(
                                  (tag) => _MemoryTagChip(label: tag),
                                )
                                .toList(growable: false),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          Divider(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          _buildImportanceSlider(context, summary),
                          const SizedBox(height: 16),
                          _buildMemoryActions(summary),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getImportanceColor(BuildContext context, double importance) {
    return MemoryTheme.importanceColor(
      context,
      importance,
      config: sl<MemoryThemeConfig>(),
    );
  }

  Widget _buildMemoryActions(SummaryEntity summary) {
    final canManualMerge = summary.type == MemoryType.fact;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          onPressed: () => _editMemory(summary),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('编辑'),
        ),
        if (canManualMerge)
          OutlinedButton.icon(
            onPressed: () => _mergeSimilarMemories(summary),
            icon: const Icon(Icons.merge_type),
            label: const Text('合并相似'),
          ),
        TextButton.icon(
          onPressed: () => _deleteMemory(summary),
          icon: const Icon(Icons.delete_outline),
          label: const Text('删除'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildImportanceSlider(BuildContext context, SummaryEntity summary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '重要性评分',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                '${(summary.importance * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
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
      ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能开发中')),
    );
  }

  Future<void> _mergeSimilarMemories(SummaryEntity summary) async {
    final candidates = ref
        .read(summaryEntityNotifierProvider.notifier)
        .findMergeCandidates(summary);

    if (candidates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有找到相似的记忆')),
        );
      }
      return;
    }

    if (!mounted) return;

    final selectedCandidate =
        await _showMergeCandidatePicker(summary, candidates);
    if (!mounted || selectedCandidate == null) {
      return;
    }

    final merged = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MemoryMergeDiffPage(
          primarySummary: summary,
          secondarySummary: selectedCandidate.summary,
          primaryLabel: '当前事实记忆',
          secondaryLabel: '候选事实记忆',
          similarity: selectedCandidate.similarity,
        ),
      ),
    );

    if (merged == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('合并完成')),
      );
    }
  }

  Future<SummaryMergeCandidate?> _showMergeCandidatePicker(
    SummaryEntity summary,
    List<SummaryMergeCandidate> candidates,
  ) {
    return showDialog<SummaryMergeCandidate>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择要比较的记忆'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('“${summary.title}” 找到 ${candidates.length} 条可合并候选'),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: SingleChildScrollView(
                  child: Column(
                    children: candidates
                        .map(
                          (candidate) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(candidate.summary.title),
                            subtitle: Text(
                              '相似度 ${(candidate.similarity * 100).toStringAsFixed(1)}% · '
                              '${candidate.summary.content}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(context, candidate),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
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
        setState(() {
          _expandedSummaryIds.remove(summary.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('删除成功'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _memoryTypeTitle(MemoryType type) {
    switch (type) {
      case MemoryType.fact:
        return '事实记忆';
      case MemoryType.core:
        return '核心记忆';
      case MemoryType.session:
        return '会话记忆';
    }
  }

  String _memoryTypeLabel(MemoryType type) {
    switch (type) {
      case MemoryType.fact:
        return '事实';
      case MemoryType.core:
        return '核心';
      case MemoryType.session:
        return '会话';
    }
  }

  String _memoryTypeDescription(MemoryType type) {
    switch (type) {
      case MemoryType.fact:
        return '适合长期保留的普通事实和稳定信息。';
      case MemoryType.core:
        return '最关键的长期记忆，不参与普通遗忘衰减。';
      case MemoryType.session:
        return '来自近期交互的临时上下文，适合快速整理。';
    }
  }

  IconData _memoryTypeIcon(MemoryType type) {
    switch (type) {
      case MemoryType.fact:
        return Icons.lightbulb_outline;
      case MemoryType.core:
        return Icons.stars_rounded;
      case MemoryType.session:
        return Icons.forum_outlined;
    }
  }

  Color _memoryTypeColor(BuildContext context, MemoryType type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case MemoryType.fact:
        return colorScheme.primary;
      case MemoryType.core:
        return Colors.orange.shade700;
      case MemoryType.session:
        return Colors.teal.shade700;
    }
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes.max(1)} 分钟前';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    }
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _emptyMessage() {
    if (_searchQuery.isNotEmpty) {
      return '没有匹配的记忆';
    }

    switch (_selectedType) {
      case MemoryType.fact:
        return '暂无事实记忆';
      case MemoryType.core:
        return '暂无核心记忆';
      case MemoryType.session:
        return '暂无会话记忆';
    }
  }
}

class _MemoryStatChip extends StatelessWidget {
  const _MemoryStatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _MemoryTypeBadge extends StatelessWidget {
  const _MemoryTypeBadge({
    required this.type,
  });

  final MemoryType type;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = switch (type) {
      MemoryType.fact => colorScheme.primary,
      MemoryType.core => Colors.orange.shade700,
      MemoryType.session => Colors.teal.shade700,
    };
    final label = switch (type) {
      MemoryType.fact => '事实',
      MemoryType.core => '核心',
      MemoryType.session => '会话',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _MemoryMetaChip extends StatelessWidget {
  const _MemoryMetaChip({
    required this.label,
    this.backgroundColor,
  });

  final String label;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final color =
        backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHigh;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _MemoryTagChip extends StatelessWidget {
  const _MemoryTagChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$label',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

extension on int {
  int max(int other) => this > other ? this : other;
}
