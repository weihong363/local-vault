import 'package:local_vault/core/domain/entities/rule_semantic_profile.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';

enum MemoryJobKind {
  sessionIngest,
  fullCompaction,
}

class MemoryCompressionJob {
  MemoryCompressionJob({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.summaryId,
  });

  factory MemoryCompressionJob.sessionIngest(String summaryId) {
    final now = DateTime.now();
    return MemoryCompressionJob(
      id: 'session_${summaryId}_${now.microsecondsSinceEpoch}',
      kind: MemoryJobKind.sessionIngest,
      summaryId: summaryId,
      createdAt: now,
    );
  }

  factory MemoryCompressionJob.fullCompaction() {
    final now = DateTime.now();
    return MemoryCompressionJob(
      id: 'compact_${now.microsecondsSinceEpoch}',
      kind: MemoryJobKind.fullCompaction,
      createdAt: now,
    );
  }

  final String id;
  final MemoryJobKind kind;
  final String? summaryId;
  final DateTime createdAt;
}

class StatePatch {
  const StatePatch({
    required this.namespace,
    required this.key,
    required this.summary,
    required this.topic,
    required this.keywords,
    required this.importance,
    required this.confidence,
  });

  final String namespace;
  final String key;
  final String summary;
  final String topic;
  final List<String> keywords;
  final double importance;
  final double confidence;

  String get storageKey => '$namespace::$key';
}

class StateRecord {
  const StateRecord({
    required this.namespace,
    required this.key,
    required this.summary,
    required this.topic,
    required this.keywords,
    required this.importance,
    required this.version,
    required this.updatedAt,
  });

  final String namespace;
  final String key;
  final String summary;
  final String topic;
  final List<String> keywords;
  final double importance;
  final int version;
  final DateTime updatedAt;

  String get storageKey => '$namespace::$key';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'namespace': namespace,
      'key': key,
      'summary': summary,
      'topic': topic,
      'keywords': keywords,
      'importance': importance,
      'version': version,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StateRecord.fromJson(Map<String, dynamic> json) {
    return StateRecord(
      namespace: json['namespace'] as String? ?? '',
      key: json['key'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      keywords: List<String>.from(json['keywords'] ?? const <String>[]),
      importance: switch (json['importance']) {
        int value => value.toDouble(),
        double value => value,
        _ => 0.0,
      },
      version: switch (json['version']) {
        int value => value,
        double value => value.toInt(),
        _ => 1,
      },
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class MemoryUnit {
  const MemoryUnit({
    required this.id,
    required this.summary,
    required this.topic,
    required this.keywords,
    required this.importance,
    required this.sourceIds,
    required this.createdAt,
    required this.updatedAt,
    required this.confidence,
  });

  final String id;
  final String summary;
  final String topic;
  final List<String> keywords;
  final double importance;
  final List<String> sourceIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double confidence;

  MemoryUnit copyWith({
    String? id,
    String? summary,
    String? topic,
    List<String>? keywords,
    double? importance,
    List<String>? sourceIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? confidence,
  }) {
    return MemoryUnit(
      id: id ?? this.id,
      summary: summary ?? this.summary,
      topic: topic ?? this.topic,
      keywords: keywords ?? this.keywords,
      importance: importance ?? this.importance,
      sourceIds: sourceIds ?? this.sourceIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'summary': summary,
      'topic': topic,
      'keywords': keywords,
      'importance': importance,
      'sourceIds': sourceIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'confidence': confidence,
    };
  }

  factory MemoryUnit.fromJson(Map<String, dynamic> json) {
    return MemoryUnit(
      id: json['id'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      keywords: List<String>.from(json['keywords'] ?? const <String>[]),
      importance: switch (json['importance']) {
        int value => value.toDouble(),
        double value => value,
        _ => 0.0,
      },
      sourceIds: List<String>.from(json['sourceIds'] ?? const <String>[]),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      confidence: switch (json['confidence']) {
        int value => value.toDouble(),
        double value => value,
        _ => 0.0,
      },
    );
  }
}

class ArchiveRecord {
  const ArchiveRecord({
    required this.id,
    required this.sourceType,
    required this.payload,
    required this.createdAt,
    required this.retentionTag,
  });

  final String id;
  final String sourceType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final String retentionTag;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sourceType': sourceType,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'retentionTag': retentionTag,
    };
  }

  factory ArchiveRecord.fromJson(Map<String, dynamic> json) {
    return ArchiveRecord(
      id: json['id'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? '',
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      retentionTag: json['retentionTag'] as String? ?? '',
    );
  }
}

class SessionCompactionResult {
  const SessionCompactionResult({
    this.mergedFacts = const <SummaryEntity>[],
    this.updatedSessions = const <SummaryEntity>[],
    this.consumedSessionIds = const <String>{},
    this.archiveRecords = const <ArchiveRecord>[],
  });

  final List<SummaryEntity> mergedFacts;
  final List<SummaryEntity> updatedSessions;
  final Set<String> consumedSessionIds;
  final List<ArchiveRecord> archiveRecords;

  int get mergedCount => mergedFacts.length;
}

class MemoryRetrievalRequest {
  const MemoryRetrievalRequest({
    this.query = '',
    this.topic = '',
    this.keywords = const <String>[],
    this.maxItems = 5,
    this.maxStateItems = 2,
  });

  final String query;
  final String topic;
  final List<String> keywords;
  final int maxItems;
  final int maxStateItems;
}

class MemoryRetrievalResult {
  const MemoryRetrievalResult({
    required this.states,
    required this.memoryUnits,
    required this.queryProfile,
  });

  final List<StateRecord> states;
  final List<MemoryUnit> memoryUnits;
  final RuleSemanticProfile queryProfile;
}

class MemoryContextBundle {
  const MemoryContextBundle({
    required this.states,
    required this.memoryUnits,
    required this.contextText,
  });

  final List<StateRecord> states;
  final List<MemoryUnit> memoryUnits;
  final String contextText;
}

class MemoryRuntimeDiagnostics {
  const MemoryRuntimeDiagnostics({
    required this.queueDepth,
    required this.isProcessing,
    required this.lastProcessedAt,
    required this.lastError,
    required this.stateRecordCount,
    required this.memoryUnitCount,
    required this.archiveRecordCount,
  });

  final int queueDepth;
  final bool isProcessing;
  final DateTime? lastProcessedAt;
  final String? lastError;
  final int stateRecordCount;
  final int memoryUnitCount;
  final int archiveRecordCount;
}
