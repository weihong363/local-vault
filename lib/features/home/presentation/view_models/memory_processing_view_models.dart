import 'package:local_vault/core/domain/entities/summary_entity.dart';

enum MemoryOperationStatus { append, overwrite, dedup, defer }

class MemoryStateDashboardViewModel {
  const MemoryStateDashboardViewModel({
    required this.activeEvents,
    required this.recentStateUpdates,
    required this.pendingOrDeferred,
  });

  final List<MemoryEventItemViewModel> activeEvents;
  final List<StateUpdateItemViewModel> recentStateUpdates;
  final List<DeferredMemoryItemViewModel> pendingOrDeferred;
}

class MemoryEventItemViewModel {
  const MemoryEventItemViewModel({
    required this.id,
    required this.title,
    required this.preview,
    required this.createdAt,
    required this.tags,
    required this.state,
  });

  final String id;
  final String title;
  final String preview;
  final DateTime createdAt;
  final List<String> tags;
  final MemoryState state;
}

class StateUpdateItemViewModel {
  const StateUpdateItemViewModel({
    required this.key,
    required this.topic,
    required this.summary,
    required this.updatedAt,
    required this.classification,
    required this.confidence,
  });

  final String key;
  final String topic;
  final String summary;
  final DateTime updatedAt;
  final String classification;
  final double confidence;
}

class DeferredMemoryItemViewModel {
  const DeferredMemoryItemViewModel({
    required this.key,
    required this.summary,
    required this.reason,
    required this.updatedAt,
    required this.confidence,
  });

  final String key;
  final String summary;
  final String reason;
  final DateTime updatedAt;
  final double confidence;
}

class ExplainabilityFieldViewModel {
  const ExplainabilityFieldViewModel({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class MemoryProcessingDetailViewModel {
  const MemoryProcessingDetailViewModel({
    required this.title,
    required this.rawText,
    required this.extractedEntities,
    required this.extractedActions,
    required this.extractedTimeSignals,
    required this.topicCandidates,
    required this.derivedEventId,
    required this.derivedEventPayload,
    required this.operationStatus,
    required this.operationReason,
  });

  final String title;
  final String rawText;
  final List<String> extractedEntities;
  final List<String> extractedActions;
  final List<String> extractedTimeSignals;
  final List<ExplainabilityFieldViewModel> topicCandidates;
  final String derivedEventId;
  final String derivedEventPayload;
  final MemoryOperationStatus operationStatus;
  final String operationReason;
}
