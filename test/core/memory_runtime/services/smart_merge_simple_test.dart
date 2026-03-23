import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';
import 'package:local_vault/core/memory_runtime/services/rule_based_memory_runtime.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/memory_runtime/policies/default_memory_policy.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';

void main() {
  test('规则路径结构化合并 - GraphRAG 示例', () async {
    // SLM 未初始化，走规则路径
    final slmService = MemorySLMService();
    final policy = DefaultMemoryPolicy(
      maxCompressedSummaryCharsValue: 800,
      maxCompressedClausesValue: 20,
    );

    final merger = RuleBasedMemoryMerger(
      slmService: slmService,
      policy: policy,
    );

    // 用户提供的真实测试文本
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

    // 执行智能合并（SLM 未初始化，走规则路径）
    final result = await merger.mergeUnits(
      left,
      right,
      strategy: MemoryMergeStrategy.smartMerge,
    );

    print('\n========== 合并结果 ==========');
    print(result.summary);
    print('============================\n');

    // 验证输出格式为结构化项目符号
    expect(result.summary, isNotEmpty, reason: '合并结果不应为空');
    expect(result.summary.contains('•'), isTrue, reason: '规则路径应该输出结构化项目符号（•）');

    // 验证关键信息保留
    expect(result.summary.contains('1000 倍'), isTrue, reason: '应保留关键性能数据');

    // 验证去重逻辑
    final bulletCount = result.summary
        .split('\n')
        .where((line) => line.trim().startsWith('•'))
        .length;
    print('要点数量：$bulletCount');
    expect(bulletCount, greaterThanOrEqualTo(3), reason: '至少保留几条要点');
    expect(bulletCount, lessThanOrEqualTo(15), reason: '最多保留 15 条要点');
  });

  test('低信号过滤测试', () async {
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

    print('\n========== 低信号过滤结果 ==========');
    print(result.summary);
    print('==================================\n');

    // 验证低信号内容被过滤
    expect(result.summary.contains('这个'), isFalse, reason: '应过滤"这个"等低信号词');
    expect(result.summary.contains('那个'), isFalse, reason: '应过滤"那个"等低信号词');
    expect(result.summary.contains('一些'), isFalse, reason: '应过滤"一些"等低信号词');
    expect(result.summary.contains('可能'), isFalse, reason: '应过滤"可能"等低信号词');
    expect(result.summary.contains('一般来说'), isFalse, reason: '应过滤"一般来说"等低信号词');
    expect(result.summary.contains('通常情况下'), isFalse,
        reason: '应过滤"通常情况下"等低信号词');
    expect(result.summary.contains('总之'), isFalse, reason: '应过滤"总之"等低信号词');
    expect(result.summary.contains('简单来说'), isFalse, reason: '应过滤"简单来说"等低信号词');

    // 验证高信号内容保留
    expect(result.summary.contains('核心功能') || result.summary.contains('快速检索'),
        isTrue,
        reason: '应保留高信号内容');
    expect(result.summary.contains('关键技术') || result.summary.contains('优化算法'),
        isTrue,
        reason: '应保留高信号内容');
    expect(
        result.summary.contains('必须') || result.summary.contains('性能'), isTrue,
        reason: '应保留高信号内容');
    expect(
        result.summary.contains('建议') || result.summary.contains('测试'), isTrue,
        reason: '应保留高信号内容');
  });
}
