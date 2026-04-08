import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/features/home/presentation/view_models/memory_processing_view_models.dart';

final memoryProcessingPresenterProvider = Provider<MemoryProcessingPresenter>(
  (ref) => const MemoryProcessingPresenter(),
);

class MemoryProcessingPresenter {
  const MemoryProcessingPresenter();

  MemoryStateDashboardViewModel buildDashboard({
    required List<SummaryEntity> summaries,
    required List<StateRecord> stateRecords,
  }) {
    final activeEvents = summaries
        .where((summary) =>
            summary.type == MemoryType.session ||
            summary.state == MemoryState.session)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final sortedStates = [...stateRecords]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return MemoryStateDashboardViewModel(
      activeEvents: activeEvents
          .take(6)
          .map(
            (summary) => MemoryEventItemViewModel(
              id: summary.id,
              title: summary.title,
              preview: summary.content,
              createdAt: summary.createdAt,
              tags: summary.tags,
              state: summary.state,
            ),
          )
          .toList(growable: false),
      recentStateUpdates: sortedStates
          .take(8)
          .map(
            (state) => StateUpdateItemViewModel(
              key: state.storageKey,
              topic: state.effectiveTopic,
              summary: state.summary,
              updatedAt: state.updatedAt,
              classification:
                  state.coreMemoryMetadata?.classificationStatus.name ??
                      'classified',
              confidence: state.coreMemoryMetadata?.topicConfidence ??
                  state.confidence ??
                  0.0,
            ),
          )
          .toList(growable: false),
      pendingOrDeferred: sortedStates
          .where(
            (state) =>
                state.coreMemoryMetadata?.classificationStatus ==
                ClassificationStatus.deferred,
          )
          .map(
            (state) => DeferredMemoryItemViewModel(
              key: state.storageKey,
              summary: state.summary,
              reason:
                  'Topic confidence ${(state.coreMemoryMetadata?.topicConfidence ?? 0.0).toStringAsFixed(2)} below threshold.',
              updatedAt: state.updatedAt,
              confidence: state.coreMemoryMetadata?.topicConfidence ?? 0.0,
            ),
          )
          .toList(growable: false),
    );
  }

  MemoryProcessingDetailViewModel fromSummary(
    SummaryEntity summary,
    StateRecord? linkedState,
  ) {
    final rawText = summary.content.trim();
    return MemoryProcessingDetailViewModel(
      title: summary.title,
      rawText: rawText,
      extractedEntities: _extractEntities(rawText),
      extractedActions: _extractActions(rawText),
      extractedTimeSignals: _extractTimeSignals(rawText),
      topicCandidates: _topicCandidates(
        linkedState?.coreMemoryMetadata,
        fallbackTags: summary.tags,
      ),
      derivedEventId: 'event_${summary.id}',
      derivedEventPayload: jsonEncode({
        'summaryId': summary.id,
        'state': summary.state.name,
        'topic': summary.topic ?? linkedState?.effectiveTopic ?? '',
      }),
      operationStatus: _operationFor(linkedState),
      operationReason: _operationReason(linkedState),
    );
  }

  MemoryProcessingDetailViewModel fromStateRecord(StateRecord state) {
    return MemoryProcessingDetailViewModel(
      title: state.storageKey,
      rawText: state.summary,
      extractedEntities: _extractEntities(state.summary),
      extractedActions: _extractActions(state.summary),
      extractedTimeSignals: _extractTimeSignals(state.summary),
      topicCandidates: _topicCandidates(state.coreMemoryMetadata),
      derivedEventId: 'state_${state.namespace}_${state.key}',
      derivedEventPayload: jsonEncode({
        'key': state.storageKey,
        'topic': state.effectiveTopic,
        'keywords': state.keywords,
        'version': state.version,
      }),
      operationStatus: _operationFor(state),
      operationReason: _operationReason(state),
    );
  }

  MemoryOperationStatus _operationFor(StateRecord? state) {
    if (state == null) return MemoryOperationStatus.append;
    if (state.coreMemoryMetadata?.classificationStatus ==
        ClassificationStatus.deferred) {
      return MemoryOperationStatus.defer;
    }
    if (state.version > 1) return MemoryOperationStatus.overwrite;
    if (state.summary.length < 18) return MemoryOperationStatus.dedup;
    return MemoryOperationStatus.append;
  }

  String _operationReason(StateRecord? state) {
    if (state == null) return 'No prior state found; append as new event entry.';
    if (state.coreMemoryMetadata?.classificationStatus ==
        ClassificationStatus.deferred) {
      return 'Deferred due to low topic confidence awaiting future evidence.';
    }
    if (state.version > 1) {
      return 'Record version is ${state.version}, indicating an overwrite update.';
    }
    if (state.summary.length < 18) {
      return 'Short normalized payload treated as deduplicated content.';
    }
    return 'New state key observed, appended into active state timeline.';
  }

  List<String> _extractEntities(String text) {
    final tokens = text
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 4)
        .take(4)
        .toList(growable: false);
    return tokens.isEmpty ? const <String>['(none)'] : tokens;
  }

  List<String> _extractActions(String text) {
    const actionHints = <String>['fix', 'build', 'update', 'review', 'ship'];
    final lower = text.toLowerCase();
    final matched = actionHints
        .where((keyword) => lower.contains(keyword))
        .toList(growable: false);
    return matched.isEmpty ? const <String>['capture'] : matched;
  }

  List<String> _extractTimeSignals(String text) {
    final regex = RegExp(r'\b(today|tomorrow|yesterday|\d{1,2}:\d{2})\b',
        caseSensitive: false);
    final matches = regex
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList(growable: false);
    return matches.isEmpty ? const <String>['No explicit time signal'] : matches;
  }

  List<ExplainabilityFieldViewModel> _topicCandidates(
    CoreMemoryMetadata? metadata, {
    List<String> fallbackTags = const <String>[],
  }) {
    if (metadata != null && metadata.candidateTopics.isNotEmpty) {
      return metadata.candidateTopics
          .map(
            (candidate) => ExplainabilityFieldViewModel(
              label: candidate.topic,
              value: candidate.score.toStringAsFixed(2),
            ),
          )
          .toList(growable: false);
    }

    if (fallbackTags.isNotEmpty) {
      return fallbackTags
          .take(3)
          .map(
            (tag) => ExplainabilityFieldViewModel(
              label: tag,
              value: '0.50',
            ),
          )
          .toList(growable: false);
    }

    return const <ExplainabilityFieldViewModel>[
      ExplainabilityFieldViewModel(label: 'unclassified', value: '0.00'),
    ];
  }
}
