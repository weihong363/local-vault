import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/summary_merge_models.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';
import 'package:local_vault/l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context)!;
    final preview = ref.read(summaryUseCasesProvider).buildMergedSummary(
          widget.primarySummary,
          widget.secondarySummary,
          resolution: _resolution,
        );
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.mergeFactMemories),
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
                  Text(
                    loc.mergeFactMemoriesDescription,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (widget.similarity != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      loc.similarityPercent(
                        '${(widget.similarity! * 100).toStringAsFixed(1)}%',
                      ),
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
            title: loc.title,
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
            title: loc.content,
            existingValue: widget.primarySummary.content.isEmpty
                ? widget.primarySummary.title // 降级使用 title
                : widget.primarySummary.content,
            incomingValue: widget.secondarySummary.content.isEmpty
                ? widget.secondarySummary.title // 降级使用 title
                : widget.secondarySummary.content,
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
            title: loc.tags,
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
                  Text(
                    loc.mergedPreview,
                    style: const TextStyle(
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
                              loc.noTags,
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
                  child: Text(loc.notNow),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isMerging ? null : _confirmMerge,
                  child: Text(
                    _isMerging ? loc.mergingLabel : loc.confirmMerge,
                  ),
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
    final loc = AppLocalizations.of(context)!;
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
          SelectableText(value.isEmpty ? loc.emptyValue : value),
        ],
      ),
    );
  }

  String _choiceLabel(SummaryMergeFieldChoice choice) {
    final loc = AppLocalizations.of(context)!;
    switch (choice) {
      case SummaryMergeFieldChoice.existing:
        return loc.keepOriginal;
      case SummaryMergeFieldChoice.incoming:
        return loc.keepNew;
      case SummaryMergeFieldChoice.combined:
        return loc.smartMerge;
    }
  }

  String _formatTags(List<String> tags) {
    final loc = AppLocalizations.of(context)!;
    if (tags.isEmpty) {
      return loc.noTags;
    }
    return tags.join(', ');
  }

  String secondaryLabelOrFallback(String label) {
    final loc = AppLocalizations.of(context)!;
    return label.isEmpty ? loc.candidateMemory : label;
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.mergeFailedMessage('$error'),
          ),
        ),
      );
      setState(() {
        _isMerging = false;
      });
    }
  }
}
