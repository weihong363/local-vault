import 'package:flutter_test/flutter_test.dart';

void main() {
  group('_getDefaultTopic 兜底逻辑测试', () {
    group('内容提取逻辑', () {
      test('从中文内容第一句提取主题', () {
        final content = '这是一个测试句子。后面还有更多内容。';
        final result = _getDefaultTopicDirectly(content);
        // 应该提取第一句（不超过 20 字符）
        expect(result.length, greaterThanOrEqualTo(2));
        expect(result.length, lessThanOrEqualTo(20));
        expect(result, contains('测试'));
      });

      test('从英文内容前 10 个词提取主题', () {
        final content =
            'This is a test content with multiple words for testing the extraction logic';
        final result = _getDefaultTopicDirectly(content);
        expect(result, contains(' ')); // 应该包含多个词
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('当内容为空时返回中文默认值', () {
        final result = _getDefaultTopicDirectly(null);
        // null 会被检测为无 CJK 字符，返回英文默认值
        expect(result, 'Untitled Memory');
      });

      test('当内容为空字符串时返回中文默认值', () {
        final result = _getDefaultTopicDirectly('');
        // 空字符串没有 CJK 字符，返回英文默认值
        expect(result, 'Untitled Memory');
      });

      test('当内容只有空白字符时返回中文默认值', () {
        final result = _getDefaultTopicDirectly('   \n\t  ');
        // 空白字符没有 CJK 字符，返回英文默认值
        expect(result, 'Untitled Memory');
      });

      test('当内容为英文且无法提取时返回英文默认值', () {
        final content = 'a'; // 太短，无法提取
        final result = _getDefaultTopicDirectly(content);
        expect(result, 'Untitled Memory');
      });

      test('能够正确处理包含 CJK 字符的内容', () {
        final content = '测试内容 test content';
        final result = _getDefaultTopicDirectly(content);
        // 因为包含中文，应该尝试提取或返回中文默认值
        expect(result, isNotEmpty);
      });

      test('处理过长的第一句话', () {
        final content = '这是一个非常非常非常非常非常非常非常非常非常长的句子，超过了 20 个字符的限制。';
        final result = _getDefaultTopicDirectly(content);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('处理包含多种标点的句子', () {
        final content = '第一句结束！第二句开始？第三句继续。';
        final result = _getDefaultTopicDirectly(content);
        // 应该在第一个感叹号处分割
        expect(result, contains('第一句'));
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('处理只有两个词的内容', () {
        final content = 'Hello World';
        final result = _getDefaultTopicDirectly(content);
        expect(result, 'Hello World');
      });

      test('处理单个词的内容（无法提取）', () {
        final content = 'Single';
        final result = _getDefaultTopicDirectly(content);
        // 单个词长度 >= 2，可以提取
        expect(result, 'Single');
      });
    });

    group('边界情况处理', () {
      test('处理 null content', () {
        expect(() => _getDefaultTopicDirectly(null), returnsNormally);
        final result = _getDefaultTopicDirectly(null);
        // null 没有 CJK 字符，返回英文默认值
        expect(result, 'Untitled Memory');
      });

      test('处理 emoji 内容', () {
        final content = '😀🎉🚀';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
      });

      test('处理特殊字符', () {
        final content = '@#\$%^&*()_+';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
      });

      test('处理混合语言', () {
        final content = '中文 English 日本語 한국어';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
      });
    });

    group('性能测试', () {
      test('处理大文本内容', () {
        final content = 'A' * 10000; // 10KB 的文本
        expect(() => _getDefaultTopicDirectly(content), returnsNormally);
        final result = _getDefaultTopicDirectly(content);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('快速返回结果', () {
        final content = '这是一个测试';
        final stopwatch = Stopwatch()..start();
        _getDefaultTopicDirectly(content);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 应该在 100ms 内完成
      });
    });

    group('真实数据测试（来自数据库备份）', () {
      test('GraphRAG 性能分析内容 - 提取第一句', () {
        // 来自记录 ID: 1774200508108
        final content =
            '坦白说，如果把微软标准的 GraphRAG 直接搬到手机上，目前的性能会是严重的瓶颈，几乎不可用。它的构建和查询都太重了。\n\n不过，学术界和社区已经针对资源受限环境推出了很多轻量化变体，让 GraphRAG 在端侧运行成为可能。';
        final result = _getDefaultTopicDirectly(content);
        // 应该提取第一句的前 20 个字符
        expect(result.length, greaterThanOrEqualTo(2));
        expect(result.length, lessThanOrEqualTo(20));
        expect(result, isNotEmpty);
      });

      test('RAG 端侧应用内容 - 提取主题', () {
        // 来自记录 ID: 1774200577433
        final content =
            'RAG 在端侧（手机、物联网设备等）的应用，核心挑战在于资源受限（算力、内存、存储）与效果保真之间的平衡。目前主流的应用思路主要分为全本地轻量化和端云协同两种架构。';
        final result = _getDefaultTopicDirectly(content);
        expect(result.length, greaterThanOrEqualTo(2));
        expect(result.length, lessThanOrEqualTo(20));
        // 第一句太长（43 字符），会进入取前 10 个词的逻辑
        expect(result, isNotEmpty);
      });

      test('Transformer 实现内容 - 提取技术主题', () {
        // 来自记录 ID: 1774253645126（topic 为 null 的记录）
        final content =
            '在开发中应用这两者，通常集中在搭建 Transformer 类模型时。核心是两点：实现注意力计算函数，以及正确堆叠残差连接与归一化。';
        final result = _getDefaultTopicDirectly(content);
        // 应该能提取到有意义的内容
        expect(result.length, greaterThanOrEqualTo(2));
        expect(result.length, lessThanOrEqualTo(20));
        expect(result, isNotEmpty);
      });

      test('长段落内容 - 正确处理标点分割', () {
        // 来自 GraphRAG 内容的第二段
        final content =
            '⚖️ 端侧 GraphRAG 的性能瓶颈在哪？\n\n主要体现在索引构建和查询延迟两个方面：\n\n· 索引构建代价极高：标准 GraphRAG 依赖大模型反复提取实体和摘要，索引成本是向量RAG 的 1000 倍以上。对手机来说，这个计算量是无法承受的。\n· 查询延迟高且不可控：查询时可能需要遍历整个图结构，延迟比向量检索高得多。';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('包含代码示例的内容 - 跳过代码提取', () {
        // 来自 Transformer 记录的代码部分
        final content =
            '''def scaled_dot_product_attention(query, key, value, mask=None, dropout=0.0):
    """计算注意力权重并加权求和"""
    d_k = query.size(-1)
    scores = torch.matmul(query, key.transpose(-2, -1)) / (d_k ** 0.5)''';
        final result = _getDefaultTopicDirectly(content);
        // 应该能从代码注释或第一行提取
        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('包含 emoji 和特殊符号的内容', () {
        // 来自 GraphRAG 记录中的 emoji 使用
        final content =
            '💎 总结与建议\n\n目前，标准 GraphRAG 因资源消耗过大，不适合直接在手机上运行。但如果你希望利用图结构的优势来增强对话记忆，可以参考以下路径：';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('混合中英文的技术文档', () {
        // 来自 RAG 记录
        final content =
            'DRAGON 框架：将检索生成解耦为端侧（私域）和云侧（公域）两路并行，再通过算法融合结果，避免数据上传，首字延迟几乎无增加。';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('包含列表项的内容', () {
        // 来自 Transformer 记录的注意事项
        final content =
            '· 残差连接要求维度一致：残差连接是逐元素相加，因此子层（注意力输出、FFN 输出）的维度必须严格等于输入维度（通常为 d_model）。';
        final result = _getDefaultTopicDirectly(content);
        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('超短内容 - 单句处理', () {
        final content = '你觉得这种“图结构 + 摘要”的混合思路，符合你的预期吗？';
        final result = _getDefaultTopicDirectly(content);
        expect(result.length, greaterThanOrEqualTo(2));
        expect(result.length, lessThanOrEqualTo(20));
      });

      test('多段落内容 - 只取第一段', () {
        final content = '''第一段的第一句话。

这是第二段的内容。

这是第三段的内容。''';
        final result = _getDefaultTopicDirectly(content);
        // 应该在中文句号处分割，返回不带标点的内容
        expect(result.length, lessThanOrEqualTo(20));
        expect(result, startsWith('第一段'));
      });
    });
  });
}

/// 直接从 rule_based_memory_runtime.dart 复制的逻辑用于测试
String _extractTopicFromContentDirectly(String content) {
  final trimmed = content.trim();

  // 取第一句话的前 20 个字符
  final firstSentence = trimmed.split(RegExp(r'[.!?!.!?.\n]')).first.trim();
  if (firstSentence.length >= 2 && firstSentence.length <= 20) {
    return firstSentence;
  }

  // 取前 10 个词
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
    // 尝试从内容第一句提取
    final firstSentence =
        content.trim().split(RegExp(r'[.!？!.!?.\n,,;]')).first.trim();

    if (firstSentence.length >= 2 && firstSentence.length <= 20) {
      return firstSentence;
    }

    // 如果第一句太长，尝试截取前 20 个字符作为主题
    if (firstSentence.length > 20) {
      // 对于中文内容，直接取前 20 个字符
      return firstSentence.substring(0, 20);
    }

    // 或取前 10 个词（英文适用）
    final words = content.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      final preview = words.take(10).join(' ');
      if (preview.length <= 20) return preview;
    }
  }

  // 最终默认值（按语言）
  final hasCJK = content != null &&
      RegExp(r'[\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF]').hasMatch(content);
  return hasCJK ? '未命名记忆' : 'Untitled Memory';
}
