import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/features/home/presentation/presenters/memory_processing_presenter.dart';
import 'package:local_vault/features/home/presentation/view_models/memory_processing_view_models.dart';

class MemoryProcessingDetailArgs {
  const MemoryProcessingDetailArgs({
    this.summaryId,
    this.stateStorageKey,
  });

  final String? summaryId;
  final String? stateStorageKey;
}

class MemoryProcessingDetailPage extends ConsumerWidget {
  const MemoryProcessingDetailPage({
    super.key,
    required this.summaries,
    required this.stateRecords,
    required this.args,
  });

  final List<SummaryEntity> summaries;
  final List<StateRecord> stateRecords;
  final MemoryProcessingDetailArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenter = ref.watch(memoryProcessingPresenterProvider);

    final state = args.stateStorageKey == null
        ? null
        : stateRecords
            .where((record) => record.storageKey == args.stateStorageKey)
            .cast<StateRecord?>()
            .firstOrNull;

    final summary = args.summaryId == null
        ? null
        : summaries
            .where((item) => item.id == args.summaryId)
            .cast<SummaryEntity?>()
            .firstOrNull;

    if (state == null && summary == null) {
      return const Scaffold(
        body: Center(child: Text('No memory detail available.')),
      );
    }

    final detail = state != null
        ? presenter.fromStateRecord(state)
        : presenter.fromSummary(summary!, _findLinkedState(summary!));

    return Scaffold(
      appBar: AppBar(title: const Text('Memory processing detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(detail.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _section('Raw text', detail.rawText),
          _chips('Extracted entities', detail.extractedEntities),
          _chips('Extracted actions', detail.extractedActions),
          _chips('Extracted time signals', detail.extractedTimeSignals),
          const SizedBox(height: 8),
          Text('Topic candidates with confidence',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...detail.topicCandidates
              .map((item) => ListTile(title: Text(item.label), trailing: Text(item.value))),
          const SizedBox(height: 12),
          _section('Derived eventId', detail.derivedEventId),
          _section('Derived event payload', detail.derivedEventPayload),
          _section(
            'State operation result',
            '${detail.operationStatus.name} — ${detail.operationReason}',
          ),
        ],
      ),
    );
  }

  StateRecord? _findLinkedState(SummaryEntity summary) {
    return stateRecords
        .where((record) =>
            record.summary == summary.content ||
            record.keywords.any(summary.content.contains))
        .cast<StateRecord?>()
        .firstOrNull;
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }

  Widget _chips(String title, List<String> values) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) => Chip(label: Text(value))).toList(),
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
