import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';
import 'package:local_vault/core/memory_runtime/services/rule_based_memory_runtime.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/memory_runtime/policies/default_memory_policy.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';

void main() {
  group('智能合并双入口策略测试', () {
    late RuleBasedMemoryMerger merger;
    late MemorySLMService slmService;
    late MemoryPolicy policy;

    setUp(() async {
      slmService = MemorySLMService();
      policy = DefaultMemoryPolicy(
        maxCompressedSummaryCharsValue: 800,
        maxCompressedClausesValue: 20,
      );

      // 不初始化 SLM，模拟 SLM 关闭状态
      merger = RuleBasedMemoryMerger(
        slmService: slmService,
        policy: policy,
      );
    });

    group('规则路径测试（SLM 关闭）', () {
      test('GraphRAG 文本 - 基础结构化合并', () async {
        // 用户提供的真实测试文本
        final graphragText1 = '''
坦白说，如果把微软标准的 GraphRAG 直接搬到手机上，目前的性能会是严重的瓶颈，几乎不可用。它的构建和查询都太重了。

不过，学术界和社区已经针对资源受限环境推出了很多轻量化变体，让 GraphRAG 在端侧运行成为可能。
''';

        final graphragText2 = '''
端侧 GraphRAG 的性能瓶颈在哪？

主要体现在索引构建和查询延迟两个方面：

· 索引构建代价极高：标准 GraphRAG 依赖大模型反复提取实体和摘要，索引成本是向量RAG 的 1000 倍以上。对手机来说，这个计算量是无法承受的。
· 查询延迟高且不可控：查询时可能需要遍历整个图结构，延迟比向量检索高得多。手机 CPU 处理这种复杂图遍历会很吃力，影响用户体验。
''';

        // 模拟两个记忆单元
        final left = _createMemoryUnit(
          summary: graphragText1,
          topic: 'GraphRAG',
          keywords: ['GraphRAG', '性能', '端侧'],
        );

        final right = _createMemoryUnit(
          summary: graphragText2,
          topic: 'GraphRAG',
          keywords: ['GraphRAG', '索引', '查询'],
        );

        // 执行智能合并（SLM 未初始化，走规则路径）
        final result = await merger.mergeUnits(
          left,
          right,
          strategy: MemoryMergeStrategy.smartMerge,
        );

        // 验证输出格式为结构化项目符号
        expect(result.summary, isNotEmpty);
        expect(result.summary.contains('•'), isTrue,
            reason: '规则路径应该输出结构化项目符号（•）');

        // 验证关键信息保留
        expect(result.summary.contains('1000 倍'), isTrue, reason: '应保留关键性能数据');
        expect(result.summary.contains('索引构建') || result.summary.contains('索引'),
            isTrue,
            reason: '应保留核心概念');

        // 验证去重逻辑
        final bulletCount = result.summary
            .split('\n')
            .where((line) => line.trim().startsWith('•'))
            .length;
        expect(bulletCount, greaterThanOrEqualTo(5), reason: '至少保留 5 条要点');
        expect(bulletCount, lessThanOrEqualTo(10), reason: '最多保留 10 条要点');

        print('✅ 规则路径合并结果:\n${result.summary}');
      });

      test('轻量化方案文本 - 低信号过滤', () async {
        final text1 = '''
有哪些专为端侧优化的轻量化方案？

针对这些痛点，目前有几种主流优化方向，它们在内存、速度和效果上找到了更好的平衡：

· 微软LazyGraphRAG：核心思路是"能不用大模型就不用"。它将索引成本降至标准版的 0.1%，查询成本更是低至 1/700 以下，同时还能保持不错的答案质量。
''';

        final text2 = '''
· 华东师大E²GraphRAG：使用 SpaCy 等传统工具替代大模型做实体识别，索引构建时间仅为标准 GraphRAG 的 1/10，查询时间仅为 LightRAG 的 1/100。
· RAGFlow轻量图提取引擎：针对低配置设备设计，通过增量式抽取架构，能将内存占用稳定控制在 1.5GB 以内。
''';

        final left = _createMemoryUnit(
          summary: text1,
          topic: '轻量化方案',
          keywords: ['LazyGraphRAG', '优化'],
        );

        final right = _createMemoryUnit(
          summary: text2,
          topic: '轻量化方案',
          keywords: ['E²GraphRAG', 'RAGFlow'],
        );

        final result = await merger.mergeUnits(left, right);

        // 验证低信号内容被过滤
        expect(result.summary.contains('这个'), isFalse, reason: '应过滤"这个"等低信号词');
        expect(result.summary.contains('那个'), isFalse, reason: '应过滤"那个"等低信号词');
        expect(result.summary.contains('一些'), isFalse, reason: '应过滤"一些"等低信号词');

        // 验证关键数据保留
        expect(
            result.summary.contains('0.1%') || result.summary.contains('1/700'),
            isTrue,
            reason: '应保留关键性能数据');
        expect(
            result.summary.contains('1/10') || result.summary.contains('1/100'),
            isTrue,
            reason: '应保留关键性能数据');
        expect(result.summary.contains('1.5GB'), isTrue, reason: '应保留关键技术参数');

        print('✅ 轻量化方案合并结果:\n${result.summary}');
      });

      test('重复内容去重测试', () async {
        final text1 = '''
GraphRAG 在端侧运行很困难。
标准 GraphRAG 因资源消耗过大，不适合直接在手机上运行。
''';

        final text2 = '''
端侧设备上运行 GraphRAG 非常困难。
手机无法承受 GraphRAG 的计算量。
''';

        final left = _createMemoryUnit(
          summary: text1,
          topic: 'GraphRAG 困难',
          keywords: ['GraphRAG', '端侧'],
        );

        final right = _createMemoryUnit(
          summary: text2,
          topic: 'GraphRAG 困难',
          keywords: ['GraphRAG', '手机'],
        );

        final result = await merger.mergeUnits(left, right);

        // 验证相似内容去重
        final lines = result.summary
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
        expect(lines.length, lessThanOrEqualTo(10), reason: '去重后行数不应过多');

        // 验证输出格式
        for (final line in lines.where((l) => l.trim().startsWith('•'))) {
          expect(line.trim().startsWith('• '), isTrue, reason: '每个要点应以"• "开头');
        }

        print('✅ 去重测试结果:\n${result.summary}');
      });

      test('建议类文本 - 保留关键行动点', () async {
        final text1 = '''
总结与建议

目前，标准 GraphRAG 因资源消耗过大，不适合直接在手机上运行。但如果你希望利用图结构的优势来增强对话记忆，可以参考以下路径：

1. 关注前沿优化：LazyGraphRAG 和 E²GraphRAG 的思路非常适合端侧，可以持续关注其开源进展。
2. 采用混合架构：不一定要全量跑 GraphRAG。可以在服务端预先构建好轻量级知识图谱（如用 RAGFlow），在手机端只保留关键的图结构索引。
''';

        final text2 = '''
结合你之前提到的"对话压缩"需求，不妨考虑一下：用轻量级 GraphRAG 从历史对话中提炼出关键实体和关系，形成一个迷你的对话知识图，再把它压缩成自然语言摘要，作为后续对话的上下文输入。

你觉得这种"图结构 + 摘要"的混合思路，符合你的预期吗？
''';

        final left = _createMemoryUnit(
          summary: text1,
          topic: '建议',
          keywords: ['建议', '架构'],
        );

        final right = _createMemoryUnit(
          summary: text2,
          topic: '建议',
          keywords: ['对话压缩', '混合'],
        );

        final result = await merger.mergeUnits(left, right);

        // 验证关键行动点保留
        expect(
            result.summary.contains('LazyGraphRAG') ||
                result.summary.contains('E²GraphRAG'),
            isTrue,
            reason: '应保留具体方案名称');
        expect(result.summary.contains('RAGFlow'), isTrue, reason: '应保留具体方案名称');
        expect(result.summary.contains('混合') || result.summary.contains('架构'),
            isTrue,
            reason: '应保留核心建议');

        // 验证问句可能被过滤（低信号）
        // 注意：这不是强制要求，因为问句也可能包含重要信息

        print('✅ 建议类文本合并结果:\n${result.summary}');
      });

      test('表格数据文本 - 保留结构化信息', () async {
        final text1 = '''
轻量化 GraphRAG 框架对比

框架/方案 核心优化思路 内存/资源占用 索引构建速度 查询延迟 端侧可行性
微软LazyGraphRAG 延迟使用大模型，按需深度检索 较低 极快 (向量RAG) 可配置 (随预算扩展) 
华东师大E²GraphRAG 传统 NLP 工具 (SpaCy) 替代大模型 低 快 (1/10) 非常快 (1/100) 
''';

        final text2 = '''
RAGFlow轻量引擎 增量式抽取，内存优化控制 可控 (1.5GB内) 中等 中等 
nano-graphrag 精简代码，去除冗余模块 低 中等 中等 

表格总结了几种轻量化方案的性能表现，供你参考。
''';

        final left = _createMemoryUnit(
          summary: text1,
          topic: '框架对比',
          keywords: ['对比', '性能'],
        );

        final right = _createMemoryUnit(
          summary: text2,
          topic: '框架对比',
          keywords: ['框架', '方案'],
        );

        final result = await merger.mergeUnits(left, right);

        // 验证关键框架名称保留
        expect(result.summary.contains('LazyGraphRAG'), isTrue,
            reason: '应保留框架名称');
        expect(
            result.summary.contains('E²GraphRAG') ||
                result.summary.contains('E2GraphRAG'),
            isTrue,
            reason: '应保留框架名称');
        expect(result.summary.contains('RAGFlow'), isTrue, reason: '应保留框架名称');
        expect(result.summary.contains('nano-graphrag'), isTrue,
            reason: '应保留框架名称');

        print('✅ 表格数据合并结果:\n${result.summary}');
      });
    });

    group('边界条件测试', () {
      test('空内容处理', () async {
        final left = _createMemoryUnit(
          summary: '',
          topic: '测试',
          keywords: [],
        );

        final right = _createMemoryUnit(
          summary: '',
          topic: '测试',
          keywords: [],
        );

        final result = await merger.mergeUnits(left, right);

        expect(result.summary, isEmpty);
      });

      test('单条内容处理', () async {
        final content = '这是唯一的内容。';

        final left = _createMemoryUnit(
          summary: content,
          topic: '测试',
          keywords: ['测试'],
        );

        final right = _createMemoryUnit(
          summary: '',
          topic: '测试',
          keywords: [],
        );

        final result = await merger.mergeUnits(left, right);

        expect(result.summary, isNotEmpty);
        expect(result.summary.contains('唯一'), isTrue);
      });

      test('超长文本压缩', () async {
        // 生成超长文本
        final longText = List.generate(100, (i) => '这是第$i个句子。').join(' ');

        final left = _createMemoryUnit(
          summary: longText,
          topic: '测试',
          keywords: ['测试'],
        );

        final right = _createMemoryUnit(
          summary: longText, // 重复内容，测试去重
          topic: '测试',
          keywords: ['测试'],
        );

        final result = await merger.mergeUnits(left, right);

        // 验证去重后只保留一份
        expect(result.summary.length, lessThan(longText.length * 1.5),
            reason: '去重后长度应显著减少');

        // 验证要点数量限制
        final bulletCount = result.summary
            .split('\n')
            .where((line) => line.trim().startsWith('•'))
            .length;
        expect(bulletCount, lessThanOrEqualTo(10), reason: '最多 10 条要点');
      });
    });

    group('其他合并策略测试', () {
      test('保留旧版本策略', () async {
        final oldContent = '这是旧版本的内容。';
        final newContent = '这是新版本的内容。';

        final left = _createMemoryUnit(
          summary: oldContent,
          topic: '测试',
          keywords: ['旧'],
        );

        final right = _createMemoryUnit(
          summary: newContent,
          topic: '测试',
          keywords: ['新'],
        );

        final result = await merger.mergeUnits(
          left,
          right,
          strategy: MemoryMergeStrategy.keepOld,
        );

        expect(result.summary, equals(oldContent));
      });

      test('保留新版本策略', () async {
        final oldContent = '这是旧版本的内容。';
        final newContent = '这是新版本的内容。';

        final left = _createMemoryUnit(
          summary: oldContent,
          topic: '测试',
          keywords: ['旧'],
        );

        final right = _createMemoryUnit(
          summary: newContent,
          topic: '测试',
          keywords: ['新'],
        );

        final result = await merger.mergeUnits(
          left,
          right,
          strategy: MemoryMergeStrategy.keepNew,
        );

        expect(result.summary, equals(newContent));
      });
    });
  });
}

// 辅助函数：创建测试用的 MemoryUnit
MemoryUnit _createMemoryUnit({
  required String summary,
  required String topic,
  required List<String> keywords,
}) {
  return MemoryUnit(
    id: 'test_${DateTime.now().millisecondsSinceEpoch}',
    summary: summary,
    topic: topic,
    keywords: keywords,
    sourceIds: <String>['test_source'],
    importance: 0.5,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    confidence: 0.8,
  );
}
