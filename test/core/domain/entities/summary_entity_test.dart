import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';

void main() {
  group('SummaryEntity basic functionality', () {
    test('create entity with default values', () {
      final summary = SummaryEntity.create(
        title: 'Test Summary',
        content: 'Test Content',
      );

      expect(summary.title, 'Test Summary');
      expect(summary.content, 'Test Content');
      expect(summary.type, MemoryType.fact); // 默认类型已改为 fact
      expect(summary.accessCount, 0);
      expect(summary.importance, 0.5);
    });

    test('update entity importance', () {
      final summary = SummaryEntity.create(
        title: 'Test',
        content: 'Content',
      ).copyWith(importance: 0.8);

      expect(summary.importance, 0.8);
    });

    test('update entity access count', () {
      final summary = SummaryEntity.create(
        title: 'Test',
        content: 'Content',
      ).copyWith(accessCount: 10);

      expect(summary.accessCount, 10);
    });
  });
}
