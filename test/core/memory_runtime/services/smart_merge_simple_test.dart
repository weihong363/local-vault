import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';
import 'package:local_vault/core/memory_runtime/policies/default_memory_policy.dart';
import 'package:local_vault/core/memory_runtime/services/rule_based_memory_runtime.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';

void main() {
  test('Rule path structured merge - GraphRAG example', () async {
    // SLM is not initialized and follows the regular path
    final slmService = MemorySLMService();
    final policy = DefaultMemoryPolicy(
      maxCompressedSummaryCharsValue: 800,
      maxCompressedClausesValue: 20,
    );

    final merger = RuleBasedMemoryMerger(
      slmService: slmService,
      policy: policy,
    );

    // Real test text
    final graphragText1 = '''
坦白说，如果把微软标准的 GraphRAG 直接搬到手机上，目前的性能会是严重的瓶颈，几乎不可用。它的构建和查询都太重了。

不过，学术界和社区已经针对资源受限环境推出了很多轻量化变体，让 GraphRAG 在端侧运行成为可能。
''';

    final graphragText2 = '''
端侧 GraphRAG 的性能瓶颈在哪？

主要体现在索引构建和查询延迟两个方面：

· 索引构建代价极高：标准 GraphRAG 依赖大模型反复提取实体和摘要，索引成本是向量 RAG 的 1000 倍以上。对手机来说，这个计算量是无法承受的。
· 查询延迟高且不可控：查询时可能需要遍历整个图结构，延迟比向量检索高得多。手机 CPU 处理这种复杂图遍历会很吃力，影响用户体验。
''';

    final left = MemoryUnit(
      id: 'test_1',
      summary: graphragText1,
      topic: 'GraphRAG',
      keywords: ['GraphRAG', '性能', '端侧'],
      sourceIds: <String>['source1'],
      importance: 0.7,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      confidence: 0.8,
    );

    final right = MemoryUnit(
      id: 'test_2',
      summary: graphragText2,
      topic: 'GraphRAG',
      keywords: ['GraphRAG', '索引', '查询'],
      sourceIds: <String>['source2'],
      importance: 0.6,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      confidence: 0.7,
    );

    // Perform Smart Merge (SLM not initialized, follow the rule path)
    final result = await merger.mergeUnits(
      left,
      right,
      strategy: MemoryMergeStrategy.smartMerge,
    );

    print('\n========== Merge Results ==========');
    print(result.summary);
    print('============================\n');

    // Verify output format is structured bullet points
    expect(result.summary, isNotEmpty,
        reason: 'Merge result should not be empty');
    expect(result.summary.contains('•'), isTrue,
        reason: 'Rule path should output structured bullet points (•)');

    // Verify critical information retention
    expect(result.summary.contains('1000 倍'), isTrue,
        reason: 'Should retain key performance data');

    // Verify deduplication logic
    final bulletCount = result.summary
        .split('\n')
        .where((line) => line.trim().startsWith('•'))
        .length;
    print('Bullet point count: $bulletCount');
    expect(bulletCount, greaterThanOrEqualTo(3),
        reason: 'Should retain at least a few bullet points');
    expect(bulletCount, lessThanOrEqualTo(15),
        reason: 'Should retain at most 15 bullet points');
  });

  test('Low signal filtering test', () async {
    final slmService = MemorySLMService();
    final policy = DefaultMemoryPolicy();

    final merger = RuleBasedMemoryMerger(
      slmService: slmService,
      policy: policy,
    );

    final text1 = '''
这个方案很好。那个也不错。一些情况下可以用。可能适合你。
核心功能是实现快速检索。关键技术是优化算法。
''';

    final text2 = '''
一般来说，这样处理比较好。通常情况下效果不错。
总之，值得尝试。简单来说，就是优化。
必须注意性能问题。建议先做测试。
''';

    final left = MemoryUnit(
      id: 'test_3',
      summary: text1,
      topic: '测试',
      keywords: ['测试'],
      sourceIds: <String>['source3'],
      importance: 0.5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      confidence: 0.8,
    );

    final right = MemoryUnit(
      id: 'test_4',
      summary: text2,
      topic: '测试',
      keywords: ['测试'],
      sourceIds: <String>['source4'],
      importance: 0.5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      confidence: 0.8,
    );

    final result = await merger.mergeUnits(left, right);

    print('\n========== Low Signal Filter Results ==========');
    print(result.summary);
    print('==================================\n');

    // Verify that low-signal content is filtered
    expect(result.summary.contains('这个'), isFalse,
        reason: 'Should filter low-signal words like "这个"');
    expect(result.summary.contains('那个'), isFalse,
        reason: 'Should filter low-signal words like "那个"');
    expect(result.summary.contains('一些'), isFalse,
        reason: 'Should filter low-signal words like "一些"');
    expect(result.summary.contains('可能'), isFalse,
        reason: 'Should filter low-signal words like "可能"');
    expect(result.summary.contains('一般来说'), isFalse,
        reason: 'Should filter low-signal words like "一般来说"');
    expect(result.summary.contains('通常情况下'), isFalse,
        reason: 'Should filter low-signal words like "通常情况下"');
    expect(result.summary.contains('总之'), isFalse,
        reason: 'Should filter low-signal words like "总之"');
    expect(result.summary.contains('简单来说'), isFalse,
        reason: 'Should filter low-signal words like "简单来说"');

    // Verify high-signal content retention
    expect(result.summary.contains('核心功能') || result.summary.contains('快速检索'),
        isTrue,
        reason: 'Should retain high-signal content');
    expect(result.summary.contains('关键技术') || result.summary.contains('优化算法'),
        isTrue,
        reason: 'Should retain high-signal content');
    expect(
        result.summary.contains('必须') || result.summary.contains('性能'), isTrue,
        reason: 'Should retain high-signal content');
    expect(
        result.summary.contains('建议') || result.summary.contains('测试'), isTrue,
        reason: 'Should retain high-signal content');
  });
}
