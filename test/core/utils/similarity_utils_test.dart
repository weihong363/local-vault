import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/utils/similarity_utils.dart';

void main() {
  group('SimilarityUtils', () {
    test('recognizes related Chinese RAG texts as more similar', () {
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

    test('keeps identical Chinese text at full similarity', () {
      final score = SimilarityUtils.calculateMemorySimilarity(
        'RAG 方案',
        'RAG 检索增强生成方案',
        'RAG 方案',
        'RAG 检索增强生成方案',
      );

      expect(score, 1.0);
    });
  });
}
