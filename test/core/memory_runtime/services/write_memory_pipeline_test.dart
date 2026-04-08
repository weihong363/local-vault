import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/core/memory_runtime/services/write_memory_pipeline.dart';

void main() {
  group('RawDocumentCreator', () {
    test('preserves raw immutable input and metadata', () {
      const creator = RawDocumentCreator();
      final input = WriteMemoryInput(
        rawText: 'Alice deployed build 42 today.',
        metadata: {'source': 'unit-test'},
        sourceId: 'src-1',
      );

      final doc = creator.create(input);

      expect(doc.rawText, equals('Alice deployed build 42 today.'));
      expect(doc.metadata['source'], equals('unit-test'));
      expect(doc.docId, equals('src-1'));
    });
  });

  group('SentenceChunker', () {
    test('creates sentence-level chunks with offsets/docId', () {
      const chunker = SentenceChunker();
      final doc = MemoryDoc(
        docId: 'doc-1',
        rawText: 'One. Two! Three?',
        metadata: const {},
        createdAt: DateTime(2026, 4, 8),
      );

      final chunks = chunker.chunk(doc);

      expect(chunks.length, equals(3));
      expect(chunks.first.docId, equals('doc-1'));
      expect(chunks.first.startOffset, equals(0));
      expect(chunks.first.endOffset, greaterThan(chunks.first.startOffset));
    });
  });

  group('RuleBasedExtractor', () {
    test('extracts entities/actions/time/topic candidates with confidence', () {
      const extractor = RuleBasedExtractor();
      final chunks = [
        const MemoryChunk(
          chunkId: 'c-1',
          docId: 'd-1',
          text: 'Alice deployed SearchService on 2026-04-08.',
          startOffset: 0,
          endOffset: 44,
          index: 0,
        ),
      ];

      final extracted = extractor.extract(chunks).first;

      expect(extracted.entities, contains('Alice'));
      expect(extracted.actions, contains('deploy'));
      expect(extracted.timeCandidates, contains('2026-04-08'));
      expect(extracted.topicCandidates.length, lessThanOrEqualTo(3));
      expect(extracted.confidence, greaterThanOrEqualTo(0.55));
    });
  });

  group('MemoryEventNormalizer', () {
    test('builds normalized events with deterministic eventId', () {
      const normalizer = MemoryEventNormalizer();
      final doc = MemoryDoc(
        docId: 'd-1',
        rawText: 'Alice deployed SearchService.',
        metadata: const {},
        createdAt: DateTime(2026, 4, 8),
      );
      final extracted = [
        const ExtractedInfo(
          chunkId: 'c-1',
          entities: ['Alice'],
          actions: ['deploy'],
          timeCandidates: [],
          topicCandidates: [TopicCandidate(topic: 'searchservice', confidence: 1)],
          confidence: 0.9,
        ),
      ];

      final first = normalizer.normalize(doc, extracted).first;
      final second = normalizer.normalize(doc, extracted).first;

      expect(first.eventType, equals('release'));
      expect(first.eventId, equals(second.eventId));
    });
  });

  group('StateOperationDecider', () {
    test('returns append/overwrite/dedup/defer operations', () {
      const decider = StateOperationDecider();
      final events = [
        const MemoryEvent(
          eventId: 'evt-1',
          docId: 'd1',
          eventType: 'note',
          entity: 'Alice',
          action: 'noted',
          timeHint: null,
          topics: [],
          confidence: 0.9,
        ),
        const MemoryEvent(
          eventId: 'evt-2',
          docId: 'd1',
          eventType: 'maintenance',
          entity: 'Alice',
          action: 'fix',
          timeHint: null,
          topics: [],
          confidence: 0.9,
        ),
        const MemoryEvent(
          eventId: 'evt-3',
          docId: 'd1',
          eventType: 'note',
          entity: 'Alice',
          action: 'noted',
          timeHint: null,
          topics: [],
          confidence: 0.2,
        ),
      ];

      final updates = decider.decide(events, existingEventIds: {'evt-1'});

      expect(updates[0].operation, equals(StateOperation.dedup));
      expect(updates[1].operation, equals(StateOperation.overwrite));
      expect(updates[2].operation, equals(StateOperation.defer));
    });
  });

  group('MemoryWritePipeline', () {
    test('end-to-end pipeline preserves raw text in doc/chunks and outputs structured state updates', () {
      final pipeline = MemoryWritePipeline();

      final result = pipeline.run(
        const WriteMemoryInput(
          rawText: 'Alice deploys SearchService today. Bob reviews release notes.',
          metadata: {'channel': 'e2e-test'},
          sourceId: 'pipeline-doc',
          forwardToLegacyIngest: false,
        ),
      );

      expect(result.document.rawText, contains('Alice deploys SearchService today'));
      expect(result.chunks.every((chunk) => chunk.docId == result.document.docId), isTrue);
      expect(result.stateUpdates, isNotEmpty);
      expect(result.stateUpdates.first.payload['eventType'], isNotNull);
      expect(result.stateUpdates.first.payload['entity'], isNotNull);
      expect(result.stateUpdates.first.payload.containsKey('rawText'), isFalse);
    });
  });
}
