import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/summary_merge_models.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';

class MemoryMergeDiffPage extends ConsumerStatefulWidget {
  const MemoryMergeDiffPage({
    super.key,
    required this.primarySummary,
    required this.secondarySummary,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.similarity,
  });

  final SummaryEntity primarySummary;
  final SummaryEntity secondarySummary;
  final String primaryLabel;
  final String secondaryLabel;
  final double? similarity;

  @override
  ConsumerState<MemoryMergeDiffPage> createState() =>
      _MemoryMergeDiffPageState();
}

class _MemoryMergeDiffPageState extends ConsumerState<MemoryMergeDiffPage> {
  SummaryMergeFieldChoice _titleChoice = SummaryMergeFieldChoice.existing;
  SummaryMergeFieldChoice _contentChoice = SummaryMergeFieldChoice.combined;
  SummaryMergeFieldChoice _tagsChoice = SummaryMergeFieldChoice.combined;
  bool _isMerging = false;

  SummaryMergeResolution get _resolution => SummaryMergeResolution(
        title: _titleChoice,
        content: _contentChoice,
        tags: _tagsChoice,
      );

  @override
  Widget build(BuildContext context) {
    final preview = ref.read(summaryUseCasesProvider).buildMergedSummary(
          widget.primarySummary,
          widget.secondarySummary,
          resolution: _resolution,
        );
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('合并事实记忆'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '请比较两版记忆，确认最终要保留的标题、内容和标签。',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (widget.similarity != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '相似度 ${(widget.similarity! * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFieldSection(
            title: '标题',
            existingValue: widget.primarySummary.title,
            incomingValue: widget.secondarySummary.title,
            existingLabel: widget.primaryLabel,
            incomingLabel: widget.secondaryLabel,
            choice: _titleChoice,
            allowCombined: false,
            onChanged: (choice) {
              setState(() {
                _titleChoice = choice;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildFieldSection(
            title: '内容',
            existingValue: widget.primarySummary.content,
            incomingValue: widget.secondarySummary.content,
            existingLabel: widget.primaryLabel,
            incomingLabel: widget.secondaryLabel,
            choice: _contentChoice,
            allowCombined: true,
            onChanged: (choice) {
              setState(() {
                _contentChoice = choice;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildFieldSection(
            title: '标签',
            existingValue: _formatTags(widget.primarySummary.tags),
            incomingValue: _formatTags(widget.secondarySummary.tags),
            existingLabel: widget.primaryLabel,
            incomingLabel: widget.secondaryLabel,
            choice: _tagsChoice,
            allowCombined: true,
            onChanged: (choice) {
              setState(() {
                _tagsChoice = choice;
              });
            },
          ),
          const SizedBox(height: 16),
          Card(
            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '合并后预览',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    preview.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    preview.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: preview.tags.isEmpty
                        ? <Widget>[
                            Text(
                              '无标签',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ]
                        : preview.tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                              ),
                            )
                            .toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isMerging
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('暂不合并'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isMerging ? null : _confirmMerge,
                  child: Text(_isMerging ? '合并中...' : '确认合并'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldSection({
    required String title,
    required String existingValue,
    required String incomingValue,
    required String existingLabel,
    required String incomingLabel,
    required SummaryMergeFieldChoice choice,
    required ValueChanged<SummaryMergeFieldChoice> onChanged,
    required bool allowCombined,
  }) {
    final options = <SummaryMergeFieldChoice>[
      SummaryMergeFieldChoice.existing,
      SummaryMergeFieldChoice.incoming,
      if (allowCombined) SummaryMergeFieldChoice.combined,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options
                  .map(
                    (option) => ChoiceChip(
                      label: Text(_choiceLabel(option)),
                      selected: choice == option,
                      onSelected: (_) => onChanged(option),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            _buildVersionCard(
              label: existingLabel,
              value: existingValue,
              accentColor: Colors.blue.shade700,
            ),
            const SizedBox(height: 12),
            _buildVersionCard(
              label: secondaryLabelOrFallback(incomingLabel),
              value: incomingValue,
              accentColor: Colors.green.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionCard({
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
        color: accentColor.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(value.isEmpty ? '空内容' : value),
        ],
      ),
    );
  }

  String _choiceLabel(SummaryMergeFieldChoice choice) {
    switch (choice) {
      case SummaryMergeFieldChoice.existing:
        return '保留原版';
      case SummaryMergeFieldChoice.incoming:
        return '保留新版';
      case SummaryMergeFieldChoice.combined:
        return '智能合并';
    }
  }

  String _formatTags(List<String> tags) {
    if (tags.isEmpty) {
      return '无标签';
    }
    return tags.join('、');
  }

  String secondaryLabelOrFallback(String label) {
    return label.isEmpty ? '候选记忆' : label;
  }

  Future<void> _confirmMerge() async {
    setState(() {
      _isMerging = true;
    });

    try {
      await ref.read(summaryEntityNotifierProvider.notifier).mergeFactMemories(
            primaryId: widget.primarySummary.id,
            secondaryId: widget.secondarySummary.id,
            resolution: _resolution,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('合并失败：$error')),
      );
      setState(() {
        _isMerging = false;
      });
    }
  }
}
