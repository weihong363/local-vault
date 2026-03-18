import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:local_vault/core/config/memory_policy_config.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/summary_merge_models.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';
import 'package:local_vault/core/theme/memory_theme.dart';
import 'package:local_vault/core/theme/memory_theme_config.dart';
import 'package:local_vault/features/memory/presentation/pages/memory_merge_diff_page.dart';
import 'package:local_vault/features/summary/presentation/widgets/empty_state.dart';
import 'package:local_vault/l10n/app_localizations.dart';

/// Memory management page.
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
    final loc = AppLocalizations.of(context)!;
    final summariesState = ref.watch(summaryEntityNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.memoryManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAndCleanup,
            tooltip: loc.refreshAndCleanup,
          ),
        ],
      ),
      body: summariesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(loc.loadFailedMessage('$error')),
          ),
        ),
        data: (summaries) {
          final filtered = _filterSummaries(summaries);
          final counts = _buildTypeCounts(summaries);
          final hasEmptyState = filtered.isEmpty;

          return RefreshIndicator(
            onRefresh: _refreshAndCleanup,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: 3 + (hasEmptyState ? 1 : filtered.length),
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildOverviewCard(
                        context,
                        allSummaries: summaries,
                        filteredSummaries: filtered,
                      ),
                    );
                  case 1:
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildTypeFilter(context, counts),
                    );
                  case 2:
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildSearchBar(),
                    );
                  default:
                    if (hasEmptyState) {
                      return SizedBox(
                        height: 280,
                        child: EmptyState(message: _emptyMessage()),
                      );
                    }

                    final summary = filtered[index - 3];
                    return Padding(
                      key: ValueKey('memory-card-${summary.id}'),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMemoryCard(context, summary),
                    );
                }
              },
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
    final loc = AppLocalizations.of(context)!;
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
                label: loc.currentView,
                value: loc.itemCountLabel('${filteredSummaries.length}'),
              ),
              _MemoryStatChip(
                label: loc.allMemories,
                value: loc.itemCountLabel('${allSummaries.length}'),
              ),
              _MemoryStatChip(
                label: loc.searchFilter,
                value: _searchQuery.isEmpty ? loc.notFiltered : loc.filtered,
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
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.memoryType,
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
              showCheckmark: false,
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
    final loc = AppLocalizations.of(context)!;
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: loc.searchHint,
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
    final counts = {
      for (final type in MemoryType.values) type: 0,
    };

    for (final summary in summaries) {
      counts.update(summary.type, (value) => value + 1);
    }

    return counts;
  }

  Widget _buildMemoryCard(BuildContext context, SummaryEntity summary) {
    final loc = AppLocalizations.of(context)!;
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
                              label: loc.metaImportanceLabel(
                                '${(summary.importance * 100).toInt()}%',
                              ),
                              backgroundColor: _getImportanceColor(
                                context,
                                summary.importance,
                              ),
                            ),
                            _MemoryMetaChip(
                              label:
                                  loc.metaVisitsLabel('${summary.accessCount}'),
                            ),
                            _MemoryMetaChip(
                              label: loc.metaUpdatedLabel(
                                _formatDate(
                                    summary.updatedAt ?? summary.createdAt),
                              ),
                            ),
                            if (summary.lastAccessedAt != null)
                              _MemoryMetaChip(
                                label: loc.metaLastOpenedLabel(
                                  _formatDate(summary.lastAccessedAt!),
                                ),
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
    final loc = AppLocalizations.of(context)!;
    final canManualMerge = summary.type == MemoryType.fact;
    final canUpgradeToCore = summary.type == MemoryType.fact;
    final upgradeRecommended = summary.shouldUpgradeToCore;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          onPressed: () => _editMemory(summary),
          icon: const Icon(Icons.edit_outlined),
          label: Text(loc.editLabel),
        ),
        if (canUpgradeToCore)
          OutlinedButton.icon(
            onPressed: () => _upgradeToCore(summary),
            icon: const Icon(Icons.stars_rounded),
            label: Text(
              upgradeRecommended ? loc.promoteToCore : loc.setAsCore,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade700,
            ),
          ),
        if (canManualMerge)
          OutlinedButton.icon(
            onPressed: () => _mergeSimilarMemories(summary),
            icon: const Icon(Icons.merge_type),
            label: Text(loc.mergeSimilar),
          ),
        TextButton.icon(
          onPressed: () => _deleteMemory(summary),
          icon: const Icon(Icons.delete_outline),
          label: Text(loc.deleteLabel),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildImportanceSlider(BuildContext context, SummaryEntity summary) {
    final loc = AppLocalizations.of(context)!;
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
                loc.importanceScore,
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
    final loc = AppLocalizations.of(context)!;
    await ref.read(summaryEntityNotifierProvider.notifier).refresh();
    await ref
        .read(summaryEntityNotifierProvider.notifier)
        .applyForgettingCurve();
    await ref
        .read(summaryEntityNotifierProvider.notifier)
        .cleanupSessionMemories();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.refreshCleanupCompleted),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editMemory(SummaryEntity summary) async {
    await context.push(AppRoutes.save, extra: summary);
    if (!mounted) {
      return;
    }
    await ref.read(summaryEntityNotifierProvider.notifier).refresh();
  }

  Future<void> _upgradeToCore(SummaryEntity summary) async {
    final loc = AppLocalizations.of(context)!;
    final policy = sl<MemoryPolicyConfig>();
    final upgradeRecommended = summary.shouldUpgradeToCore;
    final reasonFuture = ref
        .read(summaryEntityNotifierProvider.notifier)
        .getFactUpgradeReason(summary.id);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => FutureBuilder<String?>(
        future: reasonFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState != ConnectionState.done;
          final reason = snapshot.data?.trim();

          return AlertDialog(
            title: Text(
              upgradeRecommended
                  ? loc.promoteToCoreMemory
                  : loc.setAsCoreMemory,
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.promotionDialogBody(summary.title),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.promotionStatsLine(
                      '${summary.accessCount}',
                      '${(summary.importance * 100).toInt()}%',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.shouldUpgradeToCore
                        ? loc.promotionThresholdMet
                        : loc.promotionThresholdNotMet,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.promotionThresholdLine(
                      '${policy.coreUpgrade.accessCountThreshold}',
                      '${(policy.coreUpgrade.importanceThreshold * 100).toInt()}%',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.generatingPromotionReason,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Text(
                      loc.promotionReason,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reason?.isNotEmpty == true
                            ? reason!
                            : loc.defaultPromotionReason,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(loc.cancelLabel),
              ),
              FilledButton(
                onPressed:
                    isLoading ? null : () => Navigator.pop(context, true),
                child: Text(
                  upgradeRecommended
                      ? loc.confirmPromotion
                      : loc.confirmSetAsCore,
                ),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(summaryEntityNotifierProvider.notifier).upgradeFactToCore(
          summary.id,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _expandedSummaryIds.remove(summary.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          upgradeRecommended ? loc.promotedToCoreMemory : loc.setAsCoreSuccess,
        ),
        backgroundColor: Colors.orange.shade700,
        action: SnackBarAction(
          label: loc.viewCore,
          textColor: Colors.white,
          onPressed: () {
            if (!mounted) {
              return;
            }
            setState(() {
              _selectedType = MemoryType.core;
            });
          },
        ),
      ),
    );
  }

  Future<void> _mergeSimilarMemories(SummaryEntity summary) async {
    final loc = AppLocalizations.of(context)!;
    final candidates = ref
        .read(summaryEntityNotifierProvider.notifier)
        .findMergeCandidates(summary);

    if (candidates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.noSimilarMemoriesFound)),
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
          primaryLabel: loc.currentFactMemory,
          secondaryLabel: loc.candidateFactMemory,
          similarity: selectedCandidate.similarity,
        ),
      ),
    );

    if (merged == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.mergeCompleted)),
      );
    }
  }

  Future<SummaryMergeCandidate?> _showMergeCandidatePicker(
    SummaryEntity summary,
    List<SummaryMergeCandidate> candidates,
  ) {
    final loc = AppLocalizations.of(context)!;
    return showDialog<SummaryMergeCandidate>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.chooseMemoryToCompare),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.mergeCandidateCount(summary.title, '${candidates.length}'),
              ),
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
                              loc.similarityWithContent(
                                '${(candidate.similarity * 100).toStringAsFixed(1)}%',
                                candidate.summary.content,
                              ),
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
            child: Text(loc.cancelLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMemory(SummaryEntity summary) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteMemory),
        content: Text(loc.deleteMemoryConfirm(summary.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.deleteLabel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(summaryEntityNotifierProvider.notifier)
          .deleteSummary(summary.id);
      final deleteState = ref.read(summaryEntityNotifierProvider);
      if (deleteState.hasError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc.deleteFailedMessage(
                  '${deleteState.error ?? loc.unknownError}',
                ),
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _expandedSummaryIds.remove(summary.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.deletedLabel),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _memoryTypeTitle(MemoryType type) {
    final loc = AppLocalizations.of(context)!;
    switch (type) {
      case MemoryType.fact:
        return loc.factMemories;
      case MemoryType.core:
        return loc.coreMemories;
      case MemoryType.session:
        return loc.sessionMemories;
    }
  }

  String _memoryTypeLabel(MemoryType type) {
    final loc = AppLocalizations.of(context)!;
    switch (type) {
      case MemoryType.fact:
        return loc.factMemoryLabel;
      case MemoryType.core:
        return loc.coreMemoryLabel;
      case MemoryType.session:
        return loc.sessionMemoryLabel;
    }
  }

  String _memoryTypeDescription(MemoryType type) {
    final loc = AppLocalizations.of(context)!;
    switch (type) {
      case MemoryType.fact:
        return loc.factMemoryDescription;
      case MemoryType.core:
        return loc.coreMemoryDescription;
      case MemoryType.session:
        return loc.sessionMemoryDescription;
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
    final loc = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) {
      return loc.relativeMinutesAgo('${diff.inMinutes.max(1)}');
    }
    if (diff.inHours < 24) {
      return loc.relativeHoursAgo('${diff.inHours}');
    }
    if (diff.inDays < 7) {
      return loc.relativeDaysAgo('${diff.inDays}');
    }
    return DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
        .format(date);
  }

  String _emptyMessage() {
    final loc = AppLocalizations.of(context)!;
    if (_searchQuery.isNotEmpty) {
      return loc.noMatchingMemories;
    }

    switch (_selectedType) {
      case MemoryType.fact:
        return loc.noFactMemoriesYet;
      case MemoryType.core:
        return loc.noCoreMemoriesYet;
      case MemoryType.session:
        return loc.noSessionMemoriesYet;
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
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = switch (type) {
      MemoryType.fact => colorScheme.primary,
      MemoryType.core => Colors.orange.shade700,
      MemoryType.session => Colors.teal.shade700,
    };
    final label = switch (type) {
      MemoryType.fact => loc.factMemoryLabel,
      MemoryType.core => loc.coreMemoryLabel,
      MemoryType.session => loc.sessionMemoryLabel,
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
