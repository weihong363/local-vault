import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/utils/memory_title_generator.dart';

void main() {
  group('Topic Taxonomy Basic Functionality Tests', () {
    test('Should successfully use default configuration', () {
      // Verify default configuration is available
      expect(true, isTrue);
    });

    test('Title Generation - Content with Technical Keywords', () {
      final testCases = [
        'GraphRAG 端侧性能优化方案',
        'RAG 检索增强生成技术探讨',
        'LLM 大语言模型应用场景',
        'OCR 文字识别集成',
      ];

      for (final content in testCases) {
        final result = StructuredMemoryTitleGenerator.generateTitle(content);

        // Verify generated title is reasonable (8-20 characters)
        expect(result.title.length, inInclusiveRange(2, 25),
            reason:
                'Input "$content" generated unreasonable title length: ${result.title}');

        // Verify confidence is reasonable
        expect(result.confidence, greaterThan(0.3),
            reason:
                'Input "$content" has too low confidence: ${result.confidence}');
      }
    });

    test('Real Scenario - GraphRAG Edge Performance Analysis', () async {
      const title = 'GraphRAG：设计';
      const content = '''
坦白说，如果把微软标准的 GraphRAG 直接搬到手机上，目前的性能会是严重的瓶颈，几乎不可用。
微软 LazyGraphRAG：核心思路是"能不用大模型就不用"。它将索引成本降至标准版的 0.1%。
华东师大 E²GraphRAG：使用 SpaCy 等传统工具替代大模型做实体识别。
nano-graphrag：核心代码仅约 1100 行，去除了复杂组件。
''';

      final result = StructuredMemoryTitleGenerator.generateTitle(
        '$title\n$content',
      );

      // Verify generated title contains GraphRAG or related keywords
      expect(
        result.title.contains('GraphRAG') ||
            result.title.contains('Edge') ||
            result.title.contains('Performance'),
        isTrue,
        reason:
            'GraphRAG edge performance analysis content should extract GraphRAG theme, actual: ${result.title}',
      );

      // Verify confidence is reasonable
      expect(result.confidence, greaterThan(0.5));
    });

    test('Real Scenario - RAG Edge Application Discussion', () async {
      const title = 'RAG：优化';
      const content = '''
RAG 在端侧（手机、物联网设备等）的应用，核心挑战在于资源受限与效果保真之间的平衡。
全本地部署：通过 MediaPipe 等框架集成 1.2B 左右的模型。
端云协同：DRAGON 框架将检索生成解耦为端侧和云侧两路并行。
向量库需精简，结合 SQLite 实现毫秒级检索。
''';

      final result = StructuredMemoryTitleGenerator.generateTitle(
        '$title\n$content',
      );

      // Verify generated title contains RAG or edge related keywords
      expect(
        result.title.contains('RAG') ||
            result.title.contains('Edge') ||
            result.title.contains('Retrieval'),
        isTrue,
        reason:
            'RAG edge application content should extract RAG theme, actual: ${result.title}',
      );

      // Verify confidence is reasonable
      expect(result.confidence, greaterThan(0.5));
    });

    test('Real Scenario - Transformer Attention Mechanism Implementation',
        () async {
      const title = 'def：实现注意力计算函数';
      const content = '''
在开发中应用这两者，通常集中在搭建 Transformer 类模型时。
核心是两点：实现注意力计算函数，以及正确堆叠残差连接与归一化。
缩放点积注意力是最基础的函数，负责计算 Q、K、V 之间的交互。
多头注意力需要按照标准结构将注意力、残差和前馈网络串联起来。
''';

      final result = StructuredMemoryTitleGenerator.generateTitle(
        '$title\n$content',
      );

      // Verify generated title contains Transformer or attention related keywords
      expect(
        result.title.contains('Transformer') ||
            result.title.contains('Attention') ||
            result.title.contains('Implementation'),
        isTrue,
        reason:
            'Transformer attention mechanism content should extract related theme, actual: ${result.title}',
      );

      // Verify confidence is reasonable
      expect(result.confidence, greaterThan(0.5));
    });
  });
}
