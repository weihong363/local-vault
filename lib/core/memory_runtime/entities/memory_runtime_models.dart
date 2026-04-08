import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
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

@HiveType(typeId: 10)
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
    this.metadata,
    this.confidence,
  });

  @HiveField(0)
  final String namespace;

  @HiveField(1)
  final String key;

  @HiveField(2)
  final String summary;

  @HiveField(3)
  final String topic;

  @HiveField(4)
  final List<String> keywords;

  @HiveField(5)
  final double importance;

  @HiveField(6)
  final int version;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8, defaultValue: null)
  final String? metadata;

  @HiveField(9, defaultValue: null)
  final double? confidence;

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
      if (metadata != null) 'metadata': metadata,
      if (confidence != null) 'confidence': confidence,
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
      metadata: json['metadata'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  /// 优化的紧凑 JSON 格式（用于网络传输或备份）
  Map<String, dynamic> toCompactJson() {
    return {
      'n': namespace,
      'k': key,
      's': summary,
      't': topic,
      'kw': keywords,
      'i': importance,
      'v': version,
      'u': updatedAt.millisecondsSinceEpoch,
      if (metadata != null) 'm': metadata,
      if (confidence != null) 'c': confidence,
    };
  }

  factory StateRecord.fromCompactJson(Map<String, dynamic> json) {
    return StateRecord(
      namespace: json['n'] as String? ?? '',
      key: json['k'] as String? ?? '',
      summary: json['s'] as String? ?? '',
      topic: json['t'] as String? ?? '',
      keywords: List<String>.from(json['kw'] ?? const <String>[]),
      importance: switch (json['i']) {
        int value => value.toDouble(),
        double value => value,
        _ => 0.0,
      },
      version: switch (json['v']) {
        int value => value,
        double value => value.toInt(),
        _ => 1,
      },
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['u'] as int? ?? 0),
      metadata: json['m'] as String?,
      confidence: (json['c'] as num?)?.toDouble(),
    );
  }

  /// 二进制序列化（用于 Hive 存储优化）
  List<int> toBinary() {
    final compact = toCompactJson();
    return utf8.encode(jsonEncode(compact));
  }

  factory StateRecord.fromBinary(List<int> data) {
    final jsonString = utf8.decode(data);
    final compact = jsonDecode(jsonString) as Map<String, dynamic>;
    return StateRecord.fromCompactJson(compact);
  }

  /// 增量更新（避免全量覆盖）
  StateRecord copyWith({
    String? summary,
    String? topic,
    List<String>? keywords,
    double? importance,
    String? metadata,
    double? confidence,
    bool incrementVersion = true,
  }) {
    return StateRecord(
      namespace: this.namespace,
      key: this.key,
      summary: summary ?? this.summary,
      topic: topic ?? this.topic,
      keywords: keywords ?? this.keywords,
      importance: importance ?? this.importance,
      version: incrementVersion ? this.version + 1 : this.version,
      updatedAt: DateTime.now(),
      metadata: metadata ?? this.metadata,
      confidence: confidence ?? this.confidence,
    );
  }
}

@HiveType(typeId: 11)
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

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String summary;

  @HiveField(2)
  final String topic;

  @HiveField(3)
  final List<String> keywords;

  @HiveField(4)
  final double importance;

  @HiveField(5)
  final List<String> sourceIds;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
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

  /// 紧凑 JSON 格式
  Map<String, dynamic> toCompactJson() {
    return {
      'i': id,
      's': summary,
      't': topic,
      'kw': keywords,
      'imp': importance,
      'src': sourceIds,
      'c': createdAt.millisecondsSinceEpoch,
      'u': updatedAt.millisecondsSinceEpoch,
      'conf': confidence,
    };
  }

  factory MemoryUnit.fromCompactJson(Map<String, dynamic> json) {
    return MemoryUnit(
      id: json['i'] as String? ?? '',
      summary: json['s'] as String? ?? '',
      topic: json['t'] as String? ?? '',
      keywords: List<String>.from(json['kw'] ?? const <String>[]),
      importance: switch (json['imp']) {
        int value => value.toDouble(),
        double value => value,
        _ => 0.0,
      },
      sourceIds: List<String>.from(json['src'] ?? const <String>[]),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['c'] as int? ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['u'] as int? ?? 0),
      confidence: switch (json['conf']) {
        int value => value.toDouble(),
        double value => value,
        _ => 0.0,
      },
    );
  }

  /// 二进制序列化
  List<int> toBinary() {
    final compact = toCompactJson();
    return utf8.encode(jsonEncode(compact));
  }

  factory MemoryUnit.fromBinary(List<int> data) {
    final jsonString = utf8.decode(data);
    final compact = jsonDecode(jsonString) as Map<String, dynamic>;
    return MemoryUnit.fromCompactJson(compact);
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

@HiveType(typeId: 12)
class ArchiveRecord {
  const ArchiveRecord({
    required this.id,
    required this.sourceType,
    required this.payload,
    required this.createdAt,
    required this.retentionTag,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sourceType;

  @HiveField(2)
  final Map<String, dynamic> payload;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
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
    this.stateUpdates = const <StateRecord>[],
  });

  final List<SummaryEntity> mergedFacts;
  final List<SummaryEntity> updatedSessions;
  final Set<String> consumedSessionIds;
  final List<ArchiveRecord> archiveRecords;
  final List<StateRecord> stateUpdates;

  int get mergedCount => mergedFacts.length;
}

class WriteMemoryInput {
  const WriteMemoryInput({
    required this.rawText,
    this.metadata = const <String, String>{},
    this.createdAt,
    this.sourceId,
    this.legacySummary,
    this.forwardToLegacyIngest = true,
  });

  factory WriteMemoryInput.fromSummaryEntity(SummaryEntity summary) {
    return WriteMemoryInput(
      rawText: summary.content.trim().isEmpty ? summary.title : summary.content,
      metadata: <String, String>{
        'summaryId': summary.id,
        'title': summary.title,
        'type': summary.type.name,
        if (summary.topic != null && summary.topic!.isNotEmpty)
          'topic': summary.topic!,
      },
      createdAt: summary.createdAt,
      sourceId: summary.id,
      legacySummary: summary,
      forwardToLegacyIngest: true,
    );
  }

  final String rawText;
  final Map<String, String> metadata;
  final DateTime? createdAt;
  final String? sourceId;
  final SummaryEntity? legacySummary;
  final bool forwardToLegacyIngest;
}

class MemoryDoc {
  const MemoryDoc({
    required this.docId,
    required this.rawText,
    required this.metadata,
    required this.createdAt,
    this.sourceId,
  });

  final String docId;
  final String rawText;
  final Map<String, String> metadata;
  final DateTime createdAt;
  final String? sourceId;
}

class MemoryChunk {
  const MemoryChunk({
    required this.chunkId,
    required this.docId,
    required this.text,
    required this.startOffset,
    required this.endOffset,
    required this.index,
  });

  final String chunkId;
  final String docId;
  final String text;
  final int startOffset;
  final int endOffset;
  final int index;
}

class TopicCandidate {
  const TopicCandidate({
    required this.topic,
    required this.confidence,
  });

  final String topic;
  final double confidence;
}

class ExtractedInfo {
  const ExtractedInfo({
    required this.chunkId,
    required this.entities,
    required this.actions,
    required this.timeCandidates,
    required this.topicCandidates,
    required this.confidence,
  });

  final String chunkId;
  final List<String> entities;
  final List<String> actions;
  final List<String> timeCandidates;
  final List<TopicCandidate> topicCandidates;
  final double confidence;
}

class MemoryEvent {
  const MemoryEvent({
    required this.eventId,
    required this.docId,
    required this.eventType,
    required this.entity,
    required this.action,
    required this.timeHint,
    required this.topics,
    required this.confidence,
  });

  final String eventId;
  final String docId;
  final String eventType;
  final String entity;
  final String action;
  final String? timeHint;
  final List<TopicCandidate> topics;
  final double confidence;
}

enum StateOperation {
  append,
  overwrite,
  dedup,
  defer,
}

class StateUpdate {
  const StateUpdate({
    required this.eventId,
    required this.namespace,
    required this.stateKey,
    required this.operation,
    required this.rationale,
    required this.payload,
  });

  final String eventId;
  final String namespace;
  final String stateKey;
  final StateOperation operation;
  final String rationale;
  final Map<String, dynamic> payload;
}

class WriteMemoryResult {
  const WriteMemoryResult({
    required this.document,
    required this.chunks,
    required this.extracted,
    required this.events,
    required this.stateUpdates,
  });

  final MemoryDoc document;
  final List<MemoryChunk> chunks;
  final List<ExtractedInfo> extracted;
  final List<MemoryEvent> events;
  final List<StateUpdate> stateUpdates;
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
