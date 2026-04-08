import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';

void main() {
  group('CoreMemoryMetadata topic classification', () {
    test('0.49 confidence is deferred with no selected topic', () {
      final metadata = CoreMemoryMetadata.fromTopicClassification(
        'GraphRAG',
        confidence: 0.49,
      );

      expect(metadata.classificationStatus, ClassificationStatus.deferred);
      expect(metadata.selectedTopic, isNull);
      expect(metadata.candidateTopics, hasLength(1));
      expect(metadata.candidateTopics.first.topic, 'GraphRAG');
      expect(metadata.primaryTopic, 'GraphRAG');
    });

    test('0.50 confidence is classified and selected', () {
      final metadata = CoreMemoryMetadata.fromTopicClassification(
        'GraphRAG',
        confidence: 0.50,
      );

      expect(metadata.classificationStatus, ClassificationStatus.classified);
      expect(metadata.selectedTopic, 'GraphRAG');
      expect(metadata.primaryTopic, 'GraphRAG');
    });
  });

  group('StateRecord metadata migration', () {
    test('legacy records with topic get migrated metadata', () {
      final record = StateRecord.fromJson(<String, dynamic>{
        'namespace': 'topic_state',
        'key': 'graphrag',
        'summary': 'Legacy summary',
        'topic': 'GraphRAG',
        'keywords': <String>['GraphRAG'],
        'importance': 0.8,
        'version': 1,
        'updatedAt': DateTime.utc(2026, 4, 8).toIso8601String(),
      });

      expect(record.coreMemoryMetadata, isNotNull);
      expect(
        record.coreMemoryMetadata?.classificationStatus,
        ClassificationStatus.classified,
      );
      expect(record.effectiveTopic, 'GraphRAG');
    });

    test('deferred metadata still preserves topic via effectiveTopic', () {
      final record = StateRecord(
        namespace: 'topic_state',
        key: 'graphrag',
        summary: 'Pending classification',
        topic: 'Legacy Topic',
        keywords: const <String>['pending'],
        importance: 0.6,
        version: 1,
        updatedAt: DateTime.utc(2026, 4, 8),
        coreMemoryMetadata: CoreMemoryMetadata.fromTopicClassification(
          'GraphRAG',
          confidence: 0.49,
        ),
      );

      expect(
        record.coreMemoryMetadata?.classificationStatus,
        ClassificationStatus.deferred,
      );
      expect(record.effectiveTopic, 'GraphRAG');
    });
  });
}
