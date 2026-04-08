import 'dart:math';

import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';

class RawDocumentCreator {
  const RawDocumentCreator();

  MemoryDoc create(WriteMemoryInput input) {
    final createdAt = input.createdAt ?? DateTime.now();
    final docId = input.sourceId ?? 'doc_${createdAt.microsecondsSinceEpoch}';
    return MemoryDoc(
      docId: docId,
      rawText: input.rawText,
      metadata: input.metadata,
      createdAt: createdAt,
      sourceId: input.sourceId,
    );
  }
}

class SentenceChunker {
  const SentenceChunker();

  List<MemoryChunk> chunk(MemoryDoc doc) {
    final text = doc.rawText;
    if (text.trim().isEmpty) {
      return const <MemoryChunk>[];
    }

    final matches = RegExp(r'[^.!?。！？\n]+[.!?。！？]?', multiLine: true)
        .allMatches(text)
        .where((match) => (match.group(0) ?? '').trim().isNotEmpty)
        .toList();

    if (matches.isEmpty) {
      return <MemoryChunk>[
        MemoryChunk(
          chunkId: '${doc.docId}_0',
          docId: doc.docId,
          text: text.trim(),
          startOffset: 0,
          endOffset: text.length,
          index: 0,
        ),
      ];
    }

    return matches.asMap().entries.map((entry) {
      final index = entry.key;
      final match = entry.value;
      final chunkText = (match.group(0) ?? '').trim();
      return MemoryChunk(
        chunkId: '${doc.docId}_$index',
        docId: doc.docId,
        text: chunkText,
        startOffset: match.start,
        endOffset: match.end,
        index: index,
      );
    }).toList();
  }
}

class RuleBasedExtractor {
  const RuleBasedExtractor();

  List<ExtractedInfo> extract(List<MemoryChunk> chunks) {
    return chunks.map(_extractOne).toList();
  }

  ExtractedInfo _extractOne(MemoryChunk chunk) {
    final text = chunk.text;
    final entityMatches = RegExp(r'\b[A-Z][a-zA-Z0-9_]+\b').allMatches(text);
    final entities = entityMatches.map((m) => m.group(0)!).toSet().toList();

    final actions = <String>[];
    const actionLexicon = <String>[
      'create',
      'created',
      'build',
      'deploy',
      'fix',
      'update',
      'plan',
      'discuss',
      'ship',
      'review',
    ];
    final lowered = text.toLowerCase();
    for (final action in actionLexicon) {
      if (lowered.contains(action)) {
        actions.add(action);
      }
    }

    final timeMatches = RegExp(
      r'\b(today|tomorrow|yesterday|\d{4}-\d{2}-\d{2}|\d{1,2}:\d{2})\b',
      caseSensitive: false,
    ).allMatches(text);
    final timeCandidates =
        timeMatches.map((m) => m.group(0)!).toSet().toList(growable: false);

    final topicCandidates = _extractTopicCandidates(text);
    final confidence = min(
      1.0,
      0.35 +
          (entities.isNotEmpty ? 0.2 : 0) +
          (actions.isNotEmpty ? 0.25 : 0) +
          (timeCandidates.isNotEmpty ? 0.2 : 0),
    );

    return ExtractedInfo(
      chunkId: chunk.chunkId,
      entities: entities,
      actions: actions,
      timeCandidates: timeCandidates,
      topicCandidates: topicCandidates,
      confidence: confidence,
    );
  }

  List<TopicCandidate> _extractTopicCandidates(String text) {
    final tokens = RegExp(r"\b[a-zA-Z][a-zA-Z0-9_-]{2,}\b")
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .where((token) => !_stopWords.contains(token))
        .toList();

    final frequencies = <String, int>{};
    for (final token in tokens) {
      frequencies[token] = (frequencies[token] ?? 0) + 1;
    }

    final sorted = frequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return const <TopicCandidate>[];
    }

    final maxFreq = sorted.first.value;
    return sorted.take(3).map((entry) {
      return TopicCandidate(
        topic: entry.key,
        confidence: entry.value / maxFreq,
      );
    }).toList();
  }
}

class MemoryEventNormalizer {
  const MemoryEventNormalizer();

  List<MemoryEvent> normalize(
    MemoryDoc doc,
    List<ExtractedInfo> extracted,
  ) {
    final events = <MemoryEvent>[];
    for (final info in extracted) {
      final entity = info.entities.isEmpty ? 'system' : info.entities.first;
      final action = info.actions.isEmpty ? 'noted' : info.actions.first;
      final eventType = _deriveEventType(action);
      final eventId = _buildEventId(entity: entity, eventType: eventType);
      events.add(
        MemoryEvent(
          eventId: eventId,
          docId: doc.docId,
          eventType: eventType,
          entity: entity,
          action: action,
          timeHint: info.timeCandidates.isEmpty ? null : info.timeCandidates.first,
          topics: info.topicCandidates.take(3).toList(),
          confidence: info.confidence,
        ),
      );
    }
    return events;
  }

  String _deriveEventType(String action) {
    if (action.contains('deploy') || action.contains('ship')) {
      return 'release';
    }
    if (action.contains('fix') || action.contains('update')) {
      return 'maintenance';
    }
    if (action.contains('plan') || action.contains('discuss')) {
      return 'planning';
    }
    return 'note';
  }

  String _buildEventId({required String entity, required String eventType}) {
    final normalized = '${entity.toLowerCase()}::$eventType';
    var hash = 2166136261;
    for (final unit in normalized.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0xffffffff;
    }
    return 'evt_${hash.toRadixString(16).padLeft(8, '0')}';
  }
}

class StateOperationDecider {
  const StateOperationDecider();

  List<StateUpdate> decide(
    List<MemoryEvent> events, {
    Set<String> existingEventIds = const <String>{},
  }) {
    return events.map((event) {
      if (event.confidence < 0.45) {
        return StateUpdate(
          eventId: event.eventId,
          namespace: 'event_state',
          stateKey: '${event.entity}:${event.eventType}',
          operation: StateOperation.defer,
          rationale: 'Low confidence event deferred for later consolidation.',
          payload: _payload(event),
        );
      }

      if (existingEventIds.contains(event.eventId)) {
        return StateUpdate(
          eventId: event.eventId,
          namespace: 'event_state',
          stateKey: '${event.entity}:${event.eventType}',
          operation: StateOperation.dedup,
          rationale: 'Deterministic eventId already exists; deduplicated.',
          payload: _payload(event),
        );
      }

      final operation = event.eventType == 'maintenance'
          ? StateOperation.overwrite
          : StateOperation.append;
      return StateUpdate(
        eventId: event.eventId,
        namespace: 'event_state',
        stateKey: '${event.entity}:${event.eventType}',
        operation: operation,
        rationale: operation == StateOperation.overwrite
            ? 'Maintenance event should refresh existing state.'
            : 'New event appended to state timeline.',
        payload: _payload(event),
      );
    }).toList();
  }

  Map<String, dynamic> _payload(MemoryEvent event) {
    return <String, dynamic>{
      'eventType': event.eventType,
      'entity': event.entity,
      'action': event.action,
      if (event.timeHint != null) 'timeHint': event.timeHint,
      'topics': event.topics
          .map((topic) => <String, dynamic>{
                'topic': topic.topic,
                'confidence': topic.confidence,
              })
          .toList(),
      'confidence': event.confidence,
    };
  }
}

class MemoryWritePipeline {
  MemoryWritePipeline({
    RawDocumentCreator? documentCreator,
    SentenceChunker? chunker,
    RuleBasedExtractor? extractor,
    MemoryEventNormalizer? eventNormalizer,
    StateOperationDecider? stateOperationDecider,
  })  : _documentCreator = documentCreator ?? const RawDocumentCreator(),
        _chunker = chunker ?? const SentenceChunker(),
        _extractor = extractor ?? const RuleBasedExtractor(),
        _eventNormalizer = eventNormalizer ?? const MemoryEventNormalizer(),
        _stateOperationDecider =
            stateOperationDecider ?? const StateOperationDecider();

  final RawDocumentCreator _documentCreator;
  final SentenceChunker _chunker;
  final RuleBasedExtractor _extractor;
  final MemoryEventNormalizer _eventNormalizer;
  final StateOperationDecider _stateOperationDecider;

  WriteMemoryResult run(
    WriteMemoryInput input, {
    Set<String> existingEventIds = const <String>{},
  }) {
    final document = _documentCreator.create(input);
    final chunks = _chunker.chunk(document);
    final extracted = _extractor.extract(chunks);
    final events = _eventNormalizer.normalize(document, extracted);
    final updates =
        _stateOperationDecider.decide(events, existingEventIds: existingEventIds);

    return WriteMemoryResult(
      document: document,
      chunks: chunks,
      extracted: extracted,
      events: events,
      stateUpdates: updates,
    );
  }
}

const Set<String> _stopWords = <String>{
  'the',
  'and',
  'for',
  'with',
  'that',
  'this',
  'from',
  'were',
  'have',
  'has',
  'into',
  'about',
  'today',
  'tomorrow',
};
