import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/utils/similarity_utils.dart';

void main() {
  group('SimilarityUtils', () {
    test('Recognizes related Chinese RAG texts as more similar', () {
      final related = SimilarityUtils.calculateMemorySimilarity(
        'RAG 检索方案',
        'RAG 召回策略需要优化，重点看向量检索和重排。',
        'RAG 检索优化',
        '继续调整向量检索、召回率和重排效果。',
      );
      final unrelated = SimilarityUtils.calculateMemorySimilarity(
        'RAG 检索方案',
        'RAG 召回策略需要优化，重点看向量检索和重排。',
        '智能马桶选型',
        '需要确认自动翻盖、烘干和除臭体验。',
      );

      expect(related, greaterThan(unrelated));
      expect(related, greaterThan(0.2));
    });

    test('Keeps identical Chinese text at full similarity', () {
      final score = SimilarityUtils.calculateMemorySimilarity(
        'RAG 方案',
        'RAG 检索增强生成方案',
        'RAG 方案',
        'RAG 检索增强生成方案',
      );

      expect(score, 1.0);
    });

    test('boosts asymmetric English matches with BM25-style overlap', () {
      final related = SimilarityUtils.calculateMemorySimilarity(
        'release rollback plan',
        'Need to confirm the release rollback plan, owner, and checklist.',
        'rollback checklist',
        'Finalize the release rollback plan and checklist before launch.',
      );
      final unrelated = SimilarityUtils.calculateMemorySimilarity(
        'release rollback plan',
        'Need to confirm the release rollback plan, owner, and checklist.',
        'cafeteria lunch menu',
        'Compare soup, salad, and dessert options for Friday.',
      );

      expect(related, greaterThan(unrelated));
      expect(related, greaterThan(0.3));
    });
  });
}
