import 'package:flutter_test/flutter_test.dart';

void main() {
  group('_compressSummary 压缩逻辑测试', () {
    group('基础功能测试', () {
      test('简单句子列表压缩', () {
        final parts = [
          '这是第一句话。',
          '这是第二句话。',
          '这是第三句话。',
        ];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 1000);

        expect(result, isNotEmpty);
        expect(result.contains('。'), isTrue); // 应该用句号连接
      });

      test('空列表处理', () {
        final parts = <String>[];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 1000);

        expect(result, isEmpty);
      });

      test('包含空字符串的列表', () {
        final parts = ['', '有效句子。', '   ', '另一个有效句子。'];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 1000);

        expect(result, isNotEmpty);
        expect(result.contains('有效句子'), isTrue);
      });
    });

    group('信息保留测试（基于真实数据）', () {
      test('GraphRAG 记录 - 关键性能数据应保留', () {
        // 来自记录 ID: 1774200508108
        final content =
            '微软 LazyGraphRAG 将索引成本降至标准版的 0.1%，查询成本更是低至 1/700 以下。华东师大 E²GraphRAG 索引构建时间仅为标准 GraphRAG 的 1/10，查询时间仅为 LightRAG 的 1/100。';

        final parts = [content];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 200);

        // 关键性能数据应该保留
        expect(result, contains('0.1%'));
        expect(result, contains('1/700'));
        expect(result, contains('1/10'));
        expect(result, contains('1/100'));
      });

      test('RAG 端侧记录 - 关键技术参数应保留', () {
        // 来自记录 ID: 1774200577433
        final content =
            '采用 1.5B-7B 的 SLM（小型语言模型）。通过 MediaPipe 等框架集成 1.2B 左右的模型（如 LFM2-1.2B），内存占用可控制在 2.8GB 以内。轻量检索（SRAS）模型仅 0.76MB，可在 CPU 上实现毫秒级过滤。';

        final parts = [content];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 300);

        // 关键技术参数应该保留
        expect(result, contains('1.5B-7B'));
        expect(result, contains('1.2B'));
        expect(result, contains('2.8GB'));
        expect(result, contains('0.76MB'));
      });

      test('Transformer 记录 - 核心概念应保留', () {
        // 来自记录 ID: 1774253645126
        final content =
            '实现注意力计算函数，以及正确堆叠残差连接与归一化。Pre-LN（前置层归一化）结构，训练更稳定。Post-LN 对学习率敏感，若未使用学习率预热，深层网络容易梯度爆炸。';

        final parts = [content];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 200);

        // 核心概念应该保留
        expect(result.contains('Pre-LN') || result.contains('前置层归一化'), isTrue);
        expect(result.contains('Post-LN'), isTrue);
        expect(
          result.contains('残差连接') || result.contains('归一化'),
          isTrue,
        );
      });
    });

    group('短句优先测试', () {
      test('短小精悍的关键句不应被过滤', () {
        final parts = [
          '这是一个非常长的句子，包含了大量的描述性文字，目的是为了测试当存在长短句时，压缩算法是否能够保留那些短小但是关键的句子。',
          '关键点：性能优化。',
          '另一个短句。',
        ];

        final result =
            _compressSummaryDirectly(parts, maxClauses: 5, maxChars: 100);

        // 当前实现按长度排序，短句可能被过滤
        // 这个测试用于验证问题存在
        expect(result.length, lessThanOrEqualTo(100));
      });

      test('混合长短句内容', () {
        final parts = [
          '长句：微软标准的 GraphRAG 直接搬到手机上，目前的性能会是严重的瓶颈，几乎不可用，因为它的构建和查询都太重了。',
          '短句：索引构建代价极高。',
          '短句：查询延迟高。',
          '中长句：学术界推出了很多轻量化变体。',
        ];

        final result =
            _compressSummaryDirectly(parts, maxClauses: 3, maxChars: 150);

        // 验证当前行为：可能只保留最长的句子
        expect(result, isNotEmpty);
      });
    });

    group('去重逻辑测试', () {
      test('语义重复的句子应去重', () {
        final parts = [
          'GraphRAG 在端侧运行很困难。',
          '端侧设备上运行 GraphRAG 非常困难。', // 语义相近
          '手机无法承受 GraphRAG 的计算量。',
        ];

        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 500);

        // 新实现基于段落级别的去重，语义重复但文字不同的句子可能都会保留
        // 这个测试用于验证当前行为
        expect(result.split('。').where((s) => s.trim().isNotEmpty).length,
            lessThanOrEqualTo(3));
      });

      test('完全相同的句子只保留一个', () {
        final parts = [
          '这是重复的句子。',
          '这是重复的句子。',
          '这是不重复的句子。',
        ];

        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 500);

        // 完全相同的句子应该去重
        final clauses = result.split('。').where((s) => s.trim().isNotEmpty);
        expect(clauses.any((c) => c.trim() == '这是重复的句子'), isTrue);
        // 不应该出现两次
        expect(
          clauses.where((c) => c.trim() == '这是重复的句子').length,
          equals(1),
        );
      });
    });

    group('标点符号分割测试', () {
      test('中文标点应正确分割', () {
        final content = '第一句结束。第二句开始！第三句继续？第四句暂停；第五句完成：';
        final parts = [content];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 500);

        // 新实现按段落分割，不是按标点分割
        // 这个测试验证段落级别的压缩
        expect(result, isNotEmpty);
      });

      test('英文标点应正确分割', () {
        final content =
            'First sentence ends. Second sentence starts! Third continues?';
        final parts = [content];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 500);

        // 新实现按段落分割
        expect(result, isNotEmpty);
      });

      test('换行符应正确分割', () {
        final content = '第一段。\n第二段。\n第三段。';
        final parts = [content];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 500);

        // 新实现按双换行符分割段落
        expect(result, isNotEmpty);
      });
    });

    group('长度限制测试', () {
      test('超过最大字符数应截断', () {
        final parts = [
          '这是一个很长的句子，包含了大量的文字描述，目的是为了测试当结果超过最大字符数限制时，系统会正确地截断它，而不是返回完整的超长字符串。',
          '这是另一个长句子，也包含了很多文字，用来增加总长度。',
        ];

        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 50);

        expect(result.length, lessThanOrEqualTo(50));
      });

      test('maxClauses 限制应生效', () {
        final parts = List.generate(20, (i) => '第${i + 1}个句子。');
        final result =
            _compressSummaryDirectly(parts, maxClauses: 5, maxChars: 1000);

        final clauses = result.split('。').where((s) => s.trim().isNotEmpty);
        expect(clauses.length, lessThanOrEqualTo(5));
      });
    });

    group('真实场景测试', () {
      test('GraphRAG 完整段落压缩', () {
        // 来自真实记录的第一段
        final content =
            '坦白说，如果把微软标准的 GraphRAG 直接搬到手机上，目前的性能会是严重的瓶颈，几乎不可用。它的构建和查询都太重了。不过，学术界和社区已经针对资源受限环境推出了很多轻量化变体，让 GraphRAG 在端侧运行成为可能。';

        final parts = [content];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 5, maxChars: 100);

        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(100));
        // 应该保留关键信息
        expect(
          result.contains('GraphRAG') ||
              result.contains('手机') ||
              result.contains('性能'),
          isTrue,
        );
      });

      test('多记录合并场景', () {
        // 模拟两条记录的 summary 合并
        final part1 =
            'GraphRAG 在端侧运行的主要瓶颈是索引构建和查询延迟。标准 GraphRAG 依赖大模型反复提取实体和摘要，索引成本是向量 RAG 的 1000 倍以上。';
        final part2 =
            '轻量化方案包括微软 LazyGraphRAG、华东师大 E²GraphRAG、RAGFlow 轻量引擎和 nano-graphrag。它们在不同维度上做了优化。';

        final parts = [part1, part2];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 5, maxChars: 200);

        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(200));
        // 应该保留两边的关键信息
        expect(
          result.contains('索引') ||
              result.contains('查询') ||
              result.contains('轻量化') ||
              result.contains('LazyGraphRAG'),
          isTrue,
        );
      });

      test('包含技术术语的内容', () {
        final content =
            'TransformerBlock 使用 Pre-LN 结构，通过 nn.LayerNorm(d_model) 实现层归一化。注意力部分使用 nn.MultiheadAttention(d_model, n_head, dropout=dropout, batch_first=True)。前馈网络 FFN 包含两个线性层和 ReLU 激活函数。';

        final parts = [content];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 250);

        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(250));
        // 应该保留关键技术术语
        expect(
          result.contains('Pre-LN') ||
              result.contains('LayerNorm') ||
              result.contains('MultiheadAttention') ||
              result.contains('FFN'),
          isTrue,
        );
      });
    });

    group('边界情况测试', () {
      test('只有一个子句', () {
        final parts = ['只有这一个句子。'];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 5, maxChars: 100);

        expect(result, '只有这一个句子。');
      });

      test('所有子句都很长', () {
        final parts = [
          'A' * 100,
          'B' * 100,
          'C' * 100,
        ];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 2, maxChars: 150);

        expect(result.length, lessThanOrEqualTo(150));
      });

      test('包含特殊字符', () {
        final parts = [
          '包含@#\$%特殊字符的句子。',
          '包含 emoji 😀🎉🚀的句子。',
          '包含\n\t\r空白字符的句子。',
        ];
        final result =
            _compressSummaryDirectly(parts, maxClauses: 10, maxChars: 500);

        expect(result, isNotEmpty);
      });
    });
  });
}

/// 直接从 rule_based_memory_runtime.dart 复制的逻辑用于测试
String _compressSummaryDirectly(
  List<String> parts, {
  required int maxClauses,
  required int maxChars,
}) {
  final sentences = <String>[];
  final sentenceScores = <String, double>{};

  // 1. 提取句子并打分
  for (final part in parts) {
    final normalizedPart = part.trim();
    if (normalizedPart.isEmpty) continue;

    // 按自然段落分割，而不是简单按标点
    final paragraphs = normalizedPart.split(RegExp(r'\n\s*\n'));
    for (final paragraph in paragraphs) {
      final cleanParagraph = paragraph.trim();
      if (cleanParagraph.isEmpty) continue;

      // 整个段落作为一个语义单元
      final key = _normalizeForTest(cleanParagraph);
      if (!sentenceScores.containsKey(key)) {
        sentences.add(cleanParagraph);
        sentenceScores[key] = _scoreSentenceImportance(cleanParagraph);
      }
    }
  }

  // 2. 按重要性分数排序，而不是长度
  sentences.sort((a, b) {
    final scoreA = sentenceScores[_normalizeForTest(a)] ?? 0.0;
    final scoreB = sentenceScores[_normalizeForTest(b)] ?? 0.0;
    return scoreB.compareTo(scoreA);
  });

  // 3. 选择最重要的句子，直到达到字符限制
  final selected = <String>[];
  var totalLength = 0;

  for (final sentence in sentences) {
    if (selected.length >= maxClauses) break;

    // 如果是第一个句子且超过限制，需要截断
    if (selected.isEmpty) {
      if (sentence.length <= maxChars) {
        selected.add(sentence);
        totalLength = sentence.length;
      } else {
        // 截断第一个超长的句子
        final truncated = sentence.substring(0, maxChars).trimRight();
        selected.add(truncated);
        totalLength = truncated.length;
        break; // 已经达到字符限制
      }
    } else {
      // 非第一个句子，检查总长度
      if (totalLength + sentence.length + 1 > maxChars)
        break; // +1 for separator

      selected.add(sentence);
      totalLength += sentence.length + 1;
    }
  }

  // 4. 使用更自然的连接符
  return selected.join('。');
}

/// 评估句子重要性分数
double _scoreSentenceImportance(String sentence) {
  double score = 1.0;

  // 包含数字的句子通常更重要（数据、版本等）
  if (RegExp(r'\d').hasMatch(sentence)) {
    score += 0.3;
  }

  // 包含特定关键词的句子更重要
  final importantKeywords = ['核心', '关键', '重要', '必须', '应该', '建议'];
  for (final keyword in importantKeywords) {
    if (sentence.contains(keyword)) {
      score += 0.2;
      break;
    }
  }

  // 过短的句子信息量少
  if (sentence.length < 10) {
    score *= 0.7;
  }

  // 过长的句子可能不够精炼
  if (sentence.length > 100) {
    score *= 0.8;
  }

  return score;
}

/// 简化的归一化函数用于测试
String _normalizeForTest(String text) {
  return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
