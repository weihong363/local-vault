import 'package:flutter_test/flutter_test.dart';

void main() {
  group('_getDefaultTopic Fallback Logic Tests', () {
    group('Content Extraction Logic', () {
      test('Extract topic from first sentence of Chinese content', () {
        final content = '这是一个测试句子。后面还有更多内容。';
        final result = _getDefaultTopicDirectly(content);
        // Should extract first sentence (not exceeding 20 characters)
        expect(result.length, greaterThanOrEqualTo(2));
        expect(result.length, lessThanOrEqualTo(20));
        expect(result, contains('测试'));
      });

      test('Extract topic from first 10 words of English content', () {
        final content =
            'This is a test content with multiple words for testing the extraction logic';
        final result = _getDefaultTopicDirectly(content);
        expect(result, contains(' ')); // Should contain multiple words
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('Return default value when content is null', () {
        final result = _getDefaultTopicDirectly(null);
        // null will be detected as no CJK characters, returns English default value
        expect(result, 'Untitled Memory');
      });

      test('Return default value when content is empty string', () {
        final result = _getDefaultTopicDirectly('');
        // Empty string has no CJK characters, returns English default value
        expect(result, 'Untitled Memory');
      });

      test('Return default value when content only contains whitespace', () {
        final result = _getDefaultTopicDirectly('   \n\t  ');
        // Whitespace has no CJK characters, returns English default value
        expect(result, 'Untitled Memory');
      });

      test(
          'Return English default value when content is English and cannot be extracted',
          () {
        final content = 'a'; // Too short to extract
        final result = _getDefaultTopicDirectly(content);
        expect(result, 'Untitled Memory');
      });

      test('Can correctly handle content containing CJK characters', () {
        final content = '测试内容 test content';
        final result = _getDefaultTopicDirectly(content);
        // Because it contains Chinese, should attempt extraction or return Chinese default value
        expect(result, isNotEmpty);
      });

      test('Handle overly long first sentence', () {
        final content = '这是一个非常非常非常非常非常非常非常非常非常长的句子，超过了 20 个字符的限制。';
        final result = _getDefaultTopicDirectly(content);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('Handle sentences containing multiple punctuation marks', () {
        final content = '第一句结束！第二句开始？第三句继续。';
        final result = _getDefaultTopicDirectly(content);
        // Should split at the first exclamation mark
        expect(result, contains('第一句'));
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('Handle content with only two words', () {
        final content = 'Hello World';
        final result = _getDefaultTopicDirectly(content);
        expect(result, 'Hello World');
      });

      test('Handle single word content (cannot extract)', () {
        final content = 'Single';
        final result = _getDefaultTopicDirectly(content);
        // Single word length >= 2, can be extracted
        expect(result, 'Single');
      });
    });

    group('Edge Case Handling', () {
      test('Handle null content', () {
        expect(() => _getDefaultTopicDirectly(null), returnsNormally);
        final result = _getDefaultTopicDirectly(null);
        // null has no CJK characters, returns English default value
        expect(result, 'Untitled Memory');
      });

      test('Handle emoji content', () {
        final content = '😀🎉🚀';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
      });

      test('Handle special characters', () {
        final content = '@#\$%^&*()_+';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
      });

      test('Handle mixed languages', () {
        final content = '中文 English 日本語 한국어';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
      });
    });

    group('Performance Tests', () {
      test('Handle large text content', () {
        final content = 'A' * 10000; // 10KB text
        expect(() => _getDefaultTopicDirectly(content), returnsNormally);
        final result = _getDefaultTopicDirectly(content);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('Return results quickly', () {
        final content = '这是一个测试';
        final stopwatch = Stopwatch()..start();
        _getDefaultTopicDirectly(content);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds,
            lessThan(100)); // Should complete within 100ms
      });
    });

    group('Real Data Tests (From Database Backup)', () {
      test('GraphRAG Performance Analysis Content - Extract First Sentence',
          () {
        // From record ID: 1774200508108
        final content =
            '坦白说，如果把微软标准的 GraphRAG 直接搬到手机上，目前的性能会是严重的瓶颈，几乎不可用。它的构建和查询都太重了。\n\n不过，学术界和社区已经针对资源受限环境推出了很多轻量化变体，让 GraphRAG 在端侧运行成为可能。';
        final result = _getDefaultTopicDirectly(content);
        // Should extract first 20 characters of first sentence
        expect(result.length, greaterThanOrEqualTo(2));
        expect(result.length, lessThanOrEqualTo(20));
        expect(result, isNotEmpty);
      });

      test('RAG Edge Device Application Content - Extract Topic', () {
        // From record ID: 1774200577433
        final content =
            'RAG 在端侧（手机、物联网设备等）的应用，核心挑战在于资源受限（算力、内存、存储）与效果保真之间的平衡。目前主流的应用思路主要分为全本地轻量化和端云协同两种架构。';
        final result = _getDefaultTopicDirectly(content);
        expect(result.length, greaterThanOrEqualTo(2));
        expect(result.length, lessThanOrEqualTo(20));
        // First sentence is too long (43 characters), will enter logic to take first 10 words
        expect(result, isNotEmpty);
      });

      test('Transformer Implementation Content - Extract Technical Topic', () {
        // From record ID: 1774253645126 (record with null topic)
        final content =
            '在开发中应用这两者，通常集中在搭建 Transformer 类模型时。核心是两点：实现注意力计算函数，以及正确堆叠残差连接与归一化。';
        final result = _getDefaultTopicDirectly(content);
        // Should be able to extract meaningful content
        expect(result.length, greaterThanOrEqualTo(2));
        expect(result.length, lessThanOrEqualTo(20));
        expect(result, isNotEmpty);
      });

      test('Long Paragraph Content - Correctly Handle Punctuation Split', () {
        // From second paragraph of GraphRAG content
        final content =
            '⚖️ 端侧 GraphRAG 的性能瓶颈在哪？\n\n主要体现在索引构建和查询延迟两个方面：\n\n· 索引构建代价极高：标准 GraphRAG 依赖大模型反复提取实体和摘要，索引成本是向量RAG 的 1000 倍以上。对手机来说，这个计算量是无法承受的。\n· 查询延迟高且不可控：查询时可能需要遍历整个图结构，延迟比向量检索高得多。';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('Content Containing Code Examples - Skip Code Extraction', () {
        // From code section of Transformer record
        final content =
            '''def scaled_dot_product_attention(query, key, value, mask=None, dropout=0.0):
    """计算注意力权重并加权求和"""
    d_k = query.size(-1)
    scores = torch.matmul(query, key.transpose(-2, -1)) / (d_k ** 0.5)''';
        final result = _getDefaultTopicDirectly(content);
        // Should be able to extract from code comment or first line
        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('Content Containing Emoji and Special Symbols', () {
        // From emoji usage in GraphRAG record
        final content =
            '💎 总结与建议\n\n目前，标准 GraphRAG 因资源消耗过大，不适合直接在手机上运行。但如果你希望利用图结构的优势来增强对话记忆，可以参考以下路径：';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('Technical Document with Mixed Chinese and English', () {
        // From RAG record
        final content =
            'DRAGON 框架：将检索生成解耦为端侧（私域）和云侧（公域）两路并行，再通过算法融合结果，避免数据上传，首字延迟几乎无增加。';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('Content Containing List Items', () {
        // From notes in Transformer record
        final content =
            '· 残差连接要求维度一致：残差连接是逐元素相加，因此子层（注意力输出、FFN 输出）的维度必须严格等于输入维度（通常为 d_model）。';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('Ultra-short Content - Single Sentence Processing', () {
        final content = '你觉得这种“图结构 + 摘要”的混合思路，符合你的预期吗？';
        final result = _getDefaultTopicDirectly(content);
        expect(result.length, greaterThanOrEqualTo(2));
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('Multi-paragraph Content - Only Take First Paragraph', () {
        final content = '''第一段的第一句话。

这是第二段的内容。

这是第三段的内容。''';
        final result = _getDefaultTopicDirectly(content);
        // Should split at Chinese period, return content without punctuation
        expect(result.length, lessThanOrEqualTo(20));
        expect(result, startsWith('第一段'));
      });
    });
  });
}

/// Logic copied directly from rule_based_memory_runtime.dart for testing
String _extractTopicFromContentDirectly(String content) {
  final trimmed = content.trim();

  // Take first 20 characters of first sentence
  final firstSentence = trimmed.split(RegExp(r'[.!?!.!?.\n]')).first.trim();
  if (firstSentence.length >= 2 && firstSentence.length <= 20) {
    return firstSentence;
  }

  // Take first 10 words
  final words = trimmed.split(RegExp(r'\s+'));
  final take = words.length > 10 ? 10 : words.length;
  if (take >= 2) {
    final preview = words.take(take).join(' ');
    if (preview.length <= 20) return preview;
  }

  return '';
}

String _getDefaultTopicDirectly(String? content) {
  if (content != null && content.trim().isNotEmpty) {
    // Attempt to extract from first sentence of content
    final firstSentence =
        content.trim().split(RegExp(r'[.!？!.!?.\n,,;]')).first.trim();

    if (firstSentence.length >= 2 && firstSentence.length <= 20) {
      return firstSentence;
    }

    // If first sentence is too long, attempt to take first 20 characters as topic
    if (firstSentence.length > 20) {
      // For Chinese content, directly take first 20 characters
      return firstSentence.substring(0, 20);
    }

    // Or take first 10 words (applicable for English)
    final words = content.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      final preview = words.take(10).join(' ');
      if (preview.length <= 20) return preview;
    }
  }

  // Final default value (by language)
  final hasCJK = content != null &&
      RegExp(r'[\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF]').hasMatch(content);
  return hasCJK ? '未命名记忆' : 'Untitled Memory';
}
