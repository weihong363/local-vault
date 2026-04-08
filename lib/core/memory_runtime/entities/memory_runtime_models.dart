import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/core/domain/entities/rule_semantic_profile.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';

enum MemoryJobKind {
  sessionIngest,
  fullCompaction,
}

enum ClassificationStatus {
  classified,
  deferred,
}

class TopicCandidate {
  const TopicCandidate({
    required this.topic,
    required this.score,
  });

  final String topic;
  final double score;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'topic': topic,
      'score': score,
    };
  }

  factory TopicCandidate.fromJson(Map<String, dynamic> json) {
    return TopicCandidate(
      topic: json['topic'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CoreMemoryMetadata {
  const CoreMemoryMetadata({
    this.candidateTopics = const <TopicCandidate>[],
    this.selectedTopic,
    required this.topicConfidence,
    required this.classificationStatus,
  });

  final List<TopicCandidate> candidateTopics;
  final String? selectedTopic;
  final double topicConfidence;
  final ClassificationStatus classificationStatus;

  String get primaryTopic {
    if (selectedTopic?.trim().isNotEmpty ?? false) {
      return selectedTopic!.trim();
    }
    if (candidateTopics.isNotEmpty) {
      return candidateTopics.first.topic.trim();
    }
    return '';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'candidateTopics': candidateTopics
          .take(3)
          .map((candidate) => candidate.toJson())
          .toList(growable: false),
      'selectedTopic': selectedTopic,
      'topicConfidence': topicConfidence,
      'classificationStatus': classificationStatus.name,
    };
  }

  factory CoreMemoryMetadata.fromJson(Map<String, dynamic> json) {
    final rawCandidates = json['candidateTopics'] as List? ?? const [];
    final parsedCandidates = rawCandidates
        .whereType<Map>()
        .map((item) => TopicCandidate.fromJson(Map<String, dynamic>.from(item)))
        .where((candidate) => candidate.topic.trim().isNotEmpty)
        .toList(growable: false);

    return CoreMemoryMetadata(
      candidateTopics: parsedCandidates.take(3).toList(growable: false),
      selectedTopic: json['selectedTopic'] as String?,
      topicConfidence: (json['topicConfidence'] as num?)?.toDouble() ?? 0.0,
      classificationStatus: ClassificationStatus.values.firstWhere(
        (status) => status.name == json['classificationStatus'],
        orElse: () => ClassificationStatus.classified,
      ),
    );
  }

  factory CoreMemoryMetadata.legacyTopic(
    String topic, {
    double confidence = 1.0,
  }) {
    final normalized = topic.trim();
    return CoreMemoryMetadata(
      candidateTopics: normalized.isEmpty
          ? const <TopicCandidate>[]
          : <TopicCandidate>[
              TopicCandidate(topic: normalized, score: confidence),
            ],
      selectedTopic: normalized.isEmpty ? null : normalized,
      topicConfidence: confidence,
      classificationStatus: normalized.isEmpty
          ? ClassificationStatus.deferred
          : ClassificationStatus.classified,
    );
  }

  factory CoreMemoryMetadata.fromTopicClassification(
    String topic, {
    required double confidence,
    double threshold = 0.5,
  }) {
    final normalized = topic.trim();
    final status = confidence < threshold
        ? ClassificationStatus.deferred
        : ClassificationStatus.classified;
    return CoreMemoryMetadata(
      candidateTopics: normalized.isEmpty
          ? const <TopicCandidate>[]
          : <TopicCandidate>[
              TopicCandidate(topic: normalized, score: confidence),
            ],
      selectedTopic: status == ClassificationStatus.classified &&
              normalized.isNotEmpty
          ? normalized
          : null,
      topicConfidence: confidence,
      classificationStatus: status,
    );
  }
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
    required this.metadata,
  });

  final String namespace;
  final String key;
  final String summary;
  final String topic;
  final List<String> keywords;
  final double importance;
  final double confidence;
  final CoreMemoryMetadata metadata;

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
    this.coreMemoryMetadata,
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

  final CoreMemoryMetadata? coreMemoryMetadata;

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
      if (coreMemoryMetadata != null)
        'coreMemoryMetadata': coreMemoryMetadata!.toJson(),
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
      coreMemoryMetadata:
          _decodeCoreMemoryMetadata(json['coreMemoryMetadata'], json['topic']),
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
      if (coreMemoryMetadata != null) 'cm': coreMemoryMetadata!.toJson(),
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
      coreMemoryMetadata: _decodeCoreMemoryMetadata(json['cm'], json['t']),
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
    CoreMemoryMetadata? coreMemoryMetadata,
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
      coreMemoryMetadata: coreMemoryMetadata ?? this.coreMemoryMetadata,
    );
  }

  String get effectiveTopic {
    final primaryTopic = coreMemoryMetadata?.primaryTopic ?? '';
    if (primaryTopic.isNotEmpty) {
      return primaryTopic;
    }
    return topic;
  }
}

CoreMemoryMetadata? _decodeCoreMemoryMetadata(dynamic raw, dynamic legacyTopic) {
  if (raw is Map<String, dynamic>) {
    return CoreMemoryMetadata.fromJson(raw);
  }
  if (raw is Map) {
    return CoreMemoryMetadata.fromJson(Map<String, dynamic>.from(raw));
  }

  final topic = (legacyTopic as String? ?? '').trim();
  if (topic.isEmpty) {
    return null;
  }
  return CoreMemoryMetadata.legacyTopic(topic);
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
    this.coreMemoryMetadata,
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

  @HiveField(9, defaultValue: null)
  final CoreMemoryMetadata? coreMemoryMetadata;

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
    CoreMemoryMetadata? coreMemoryMetadata,
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
      coreMemoryMetadata: coreMemoryMetadata ?? this.coreMemoryMetadata,
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
      if (coreMemoryMetadata != null) 'cm': coreMemoryMetadata!.toJson(),
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
      coreMemoryMetadata: _decodeCoreMemoryMetadata(json['cm'], json['t']),
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
      if (coreMemoryMetadata != null)
        'coreMemoryMetadata': coreMemoryMetadata!.toJson(),
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
      coreMemoryMetadata:
          _decodeCoreMemoryMetadata(json['coreMemoryMetadata'], json['topic']),
    );
  }

  String get effectiveTopic {
    final primaryTopic = coreMemoryMetadata?.primaryTopic ?? '';
    if (primaryTopic.isNotEmpty) {
      return primaryTopic;
    }
    return topic;
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
