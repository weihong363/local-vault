import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/config/memory_policy_config.dart';
import 'package:local_vault/core/domain/entities/rule_semantic_profile.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/summary_merge_models.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const <String, Object>{});

  group('SummaryUseCases session batching', () {
    late _InMemorySummaryRepository repository;
    late SummaryUseCases useCases;

    setUp(() {
      repository = _InMemorySummaryRepository();
      useCases = SummaryUseCases(repository, _FakeMemorySlmService());
    });

    test('keeps separate session entries until the third matching record',
        () async {
      final now = DateTime.now();
      await useCases.addSessionMemory(
        SummaryEntity(
          id: 'session_batch_1',
          title: '买菜',
          content: '今晚需要买牛奶和面包',
          type: MemoryType.session,
          createdAt: now,
          source: 'quick_action',
          tags: const ['购物'],
        ),
      );
      await useCases.addSessionMemory(
        SummaryEntity(
          id: 'session_batch_2',
          title: '买菜',
          content: '别忘了鸡蛋和水果',
          type: MemoryType.session,
          createdAt: now.add(const Duration(minutes: 1)),
          source: 'quick_action',
          tags: const ['购物'],
        ),
      );

      expect(repository.getSummariesByType(MemoryType.session), hasLength(2));
      expect(repository.getSummariesByType(MemoryType.fact), isEmpty);

      await useCases.addSessionMemory(
        SummaryEntity(
          id: 'session_batch_3',
          title: '买菜',
          content: '再补一些酸奶和蔬菜',
          type: MemoryType.session,
          createdAt: now.add(const Duration(minutes: 2)),
          source: 'quick_action',
          tags: const ['购物'],
        ),
      );

      final facts = repository.getSummariesByType(MemoryType.fact);
      expect(repository.getSummariesByType(MemoryType.session), isEmpty);
      expect(facts, hasLength(1));
      expect(facts.single.topic, '购物清单');
      expect(facts.single.content, contains('牛奶'));
      expect(facts.single.content, contains('酸奶'));
    });

    test(
        'exact duplicate session updates existing entry instead of adding a new one',
        () async {
      final session = SummaryEntity.create(
        title: '会议记录',
        content: '周五上午十点同步项目进展',
        type: MemoryType.session,
        source: 'quick_action',
        tags: const ['工作'],
      );

      await useCases.addSessionMemory(session);
      await useCases.addSessionMemory(
        SummaryEntity.create(
          title: session.title,
          content: session.content,
          type: MemoryType.session,
          source: session.source,
          tags: session.tags,
        ),
      );

      final sessions = repository.getSummariesByType(MemoryType.session);
      expect(sessions, hasLength(1));
      expect(sessions.single.accessCount, 1);
    });

    test('custom policy upgrades fact using centralized core thresholds',
        () async {
      useCases = SummaryUseCases(
        repository,
        _FakeMemorySlmService(),
        policyConfig: const MemoryPolicyConfig(
          coreUpgrade: CoreUpgradePolicy(
            accessCountThreshold: 2,
            importanceThreshold: 0.95,
          ),
        ),
      );

      await useCases.addSummary(
        SummaryEntity.create(
          title: '项目决策',
          content: '确认下周发布窗口',
          type: MemoryType.fact,
        ).copyWith(
          accessCount: 2,
        ),
      );

      final cores = repository.getSummariesByType(MemoryType.core);
      expect(cores, hasLength(1));
      expect(cores.single.title, '项目决策');
    });

    test('cleanup session memories honors configured session max age',
        () async {
      useCases = SummaryUseCases(
        repository,
        _FakeMemorySlmService(),
        policyConfig: const MemoryPolicyConfig(
          sessionMaxAge: Duration(minutes: 30),
        ),
      );

      final oldSession = SummaryEntity.create(
        title: '临时提醒',
        content: '半小时前记录的内容',
        type: MemoryType.session,
      ).copyWith(
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await repository.addSummary(oldSession);
      await useCases.cleanupSessionMemories();

      expect(repository.getSummariesByType(MemoryType.session), isEmpty);
    });

    test('deduplication honors configured similarity threshold', () async {
      final now = DateTime.now();
      useCases = SummaryUseCases(
        repository,
        _FakeMemorySlmService(),
        policyConfig: const MemoryPolicyConfig(
          similarity: SimilarityPolicy(
            deduplicationThreshold: 0.9,
          ),
        ),
      );

      await useCases.addSummary(
        SummaryEntity(
          id: 'existing_dedup',
          title: 'project launch',
          content: 'prepare launch checklist',
          createdAt: now,
          source: 'manual',
        ),
      );

      await useCases.addWithDeduplication(
        SummaryEntity(
          id: 'incoming_dedup',
          title: 'project launch',
          content: 'prepare launch checklist draft',
          createdAt: now.add(const Duration(minutes: 1)),
          source: 'manual',
        ),
      );

      expect(repository.getAllSummaries(), hasLength(2));
    });

    test('findSimilarMemories honors configured similarity threshold',
        () async {
      final now = DateTime.now();
      useCases = SummaryUseCases(
        repository,
        _FakeMemorySlmService(),
        policyConfig: const MemoryPolicyConfig(
          similarity: SimilarityPolicy(
            relatedMemoryThreshold: 0.9,
          ),
        ),
      );

      await repository.addSummary(
        SummaryEntity(
          id: 'existing_similar',
          title: 'project launch',
          content: 'prepare launch checklist',
          createdAt: now,
          source: 'manual',
        ),
      );

      final similar = useCases.findSimilarMemories(
        SummaryEntity(
          id: 'target_similar',
          title: 'project launch',
          content: 'prepare launch checklist draft',
          createdAt: now.add(const Duration(minutes: 1)),
          source: 'manual',
        ),
      );

      expect(similar, isEmpty);
    });

    test('session batching honors configured combined score threshold',
        () async {
      final now = DateTime.now();
      useCases = SummaryUseCases(
        repository,
        _FakeMemorySlmService(),
        policyConfig: const MemoryPolicyConfig(
          sessionBatching: SessionBatchingPolicy(
            combinedScoreThreshold: 0.95,
          ),
        ),
      );

      await useCases.addSessionMemory(
        SummaryEntity(
          id: 'session_1',
          title: 'project launch',
          content: 'prepare launch checklist',
          type: MemoryType.session,
          createdAt: now,
          source: 'quick_action',
          tags: const ['work'],
        ),
      );
      await useCases.addSessionMemory(
        SummaryEntity(
          id: 'session_2',
          title: 'project launch',
          content: 'confirm launch owner',
          type: MemoryType.session,
          createdAt: now.add(const Duration(minutes: 1)),
          source: 'quick_action',
          tags: const ['work'],
        ),
      );
      await useCases.addSessionMemory(
        SummaryEntity(
          id: 'session_3',
          title: 'project launch',
          content: 'review launch timeline',
          type: MemoryType.session,
          createdAt: now.add(const Duration(minutes: 2)),
          source: 'quick_action',
          tags: const ['work'],
        ),
      );

      expect(repository.getSummariesByType(MemoryType.session), hasLength(3));
      expect(repository.getSummariesByType(MemoryType.fact), isEmpty);
    });

    test('session batching allows stable topic matches to bypass rule gate',
        () async {
      final now = DateTime.now();

      await useCases.addSessionMemory(
        SummaryEntity(
          id: 'rag_session_1',
          title: 'RAG 向量库选型',
          content: '需要对比向量数据库的召回延迟与部署成本。',
          type: MemoryType.session,
          createdAt: now,
          source: 'quick_action',
          tags: const ['向量库'],
          topic: 'RAG',
        ),
      );
      await useCases.addSessionMemory(
        SummaryEntity(
          id: 'rag_session_2',
          title: 'RAG 重排策略',
          content: '继续验证交叉编码器重排和 rerank 指标。',
          type: MemoryType.session,
          createdAt: now.add(const Duration(minutes: 1)),
          source: 'quick_action',
          tags: const ['重排'],
          topic: 'RAG',
        ),
      );

      expect(repository.getSummariesByType(MemoryType.session), hasLength(2));
      expect(repository.getSummariesByType(MemoryType.fact), isEmpty);

      await useCases.addSessionMemory(
        SummaryEntity(
          id: 'rag_session_3',
          title: 'RAG Chunk 切分',
          content: '需要重新评估 chunk 大小和 overlap 对召回率的影响。',
          type: MemoryType.session,
          createdAt: now.add(const Duration(minutes: 2)),
          source: 'quick_action',
          tags: const ['切分'],
          topic: 'RAG',
        ),
      );

      final facts = repository.getSummariesByType(MemoryType.fact);
      expect(repository.getSummariesByType(MemoryType.session), isEmpty);
      expect(facts, hasLength(1));
      expect(facts.single.topic, 'RAG');
      expect(facts.single.content, contains('向量数据库'));
      expect(facts.single.content, contains('chunk'));
    });

    test('session batching refreshes stale topics before matching', () async {
      final now = DateTime.now();
      useCases = SummaryUseCases(repository, _CanonicalRagMemorySlmService());

      await useCases.addSessionMemory(
        SummaryEntity(
          id: 'stale_topic_1',
          title: 'Sentence Transformers 在端侧的用法',
          content: '继续验证向量检索和 embedding 方案。',
          type: MemoryType.session,
          createdAt: now,
          source: 'quick_action',
          tags: const ['embedding'],
          topic: 'sent',
        ),
      );
      await useCases.addSessionMemory(
        SummaryEntity(
          id: 'stale_topic_2',
          title: '移动端 RAG 方案',
          content: '需要继续比较 chunk 切分和重排策略。',
          type: MemoryType.session,
          createdAt: now.add(const Duration(minutes: 1)),
          source: 'quick_action',
          tags: const ['chunk'],
          topic: 'rag在端侧手机',
        ),
      );
      await useCases.addSessionMemory(
        SummaryEntity(
          id: 'stale_topic_3',
          title: '检索增强生成解释',
          content: '它的全称是检索增强生成，需要补充召回细节。',
          type: MemoryType.session,
          createdAt: now.add(const Duration(minutes: 2)),
          source: 'quick_action',
          tags: const ['召回'],
          topic: '它的全称是检',
        ),
      );

      final facts = repository.getSummariesByType(MemoryType.fact);
      expect(repository.getSummariesByType(MemoryType.session), isEmpty);
      expect(facts, hasLength(1));
      expect(facts.single.topic, 'RAG');
    });

    test('fact summary save keeps new fact and returns merge candidates',
        () async {
      final now = DateTime.now();
      await useCases.addSummary(
        SummaryEntity(
          id: 'existing_fact',
          title: 'project launch',
          content: 'prepare launch checklist',
          createdAt: now,
          type: MemoryType.fact,
          source: 'manual',
        ),
      );

      final result = await useCases.addFactSummary(
        SummaryEntity(
          id: 'new_fact',
          title: 'project launch',
          content: 'prepare launch checklist draft',
          createdAt: now.add(const Duration(minutes: 1)),
          type: MemoryType.fact,
          source: 'manual',
        ),
      );

      expect(repository.getSummariesByType(MemoryType.fact), hasLength(2));
      expect(result.wasExactDuplicate, isFalse);
      expect(result.mergeCandidates, hasLength(1));
      expect(result.mergeCandidates.single.summary.id, 'existing_fact');
    });

    test('mergeMemoriesWithResolution applies chosen fact fields', () async {
      final now = DateTime.now();
      await useCases.addSummary(
        SummaryEntity(
          id: 'primary_fact',
          title: '旧标题',
          content: '旧内容',
          createdAt: now,
          type: MemoryType.fact,
          source: 'manual',
          tags: const ['旧标签'],
          accessCount: 2,
        ),
      );
      await useCases.addSummary(
        SummaryEntity(
          id: 'secondary_fact',
          title: '新标题',
          content: '新内容',
          createdAt: now.add(const Duration(minutes: 1)),
          type: MemoryType.fact,
          source: 'manual',
          tags: const ['新标签'],
          accessCount: 1,
        ),
      );

      await useCases.mergeMemoriesWithResolution(
        primaryId: 'primary_fact',
        secondaryId: 'secondary_fact',
        resolution: const SummaryMergeResolution(
          title: SummaryMergeFieldChoice.incoming,
          content: SummaryMergeFieldChoice.incoming,
          tags: SummaryMergeFieldChoice.combined,
        ),
      );

      final facts = repository.getSummariesByType(MemoryType.fact);
      expect(facts, hasLength(1));
      expect(facts.single.id, 'primary_fact');
      expect(facts.single.title, '新标题');
      expect(facts.single.content, '新内容');
      expect(facts.single.tags, containsAll(const ['旧标签', '新标签']));
      expect(facts.single.accessCount, 3);
    });

    test('mergeMemoriesWithResolution throws neutral error for missing memory',
        () async {
      expect(
        () => useCases.mergeMemoriesWithResolution(
          primaryId: 'missing_primary',
          secondaryId: 'missing_secondary',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'Requested memory could not be found',
          ),
        ),
      );
    });

    test(
        'mergeMemoriesWithResolution rejects non-fact memories with neutral error',
        () async {
      await useCases.addSummary(
        SummaryEntity(
          id: 'session_memory',
          title: '临时记录',
          content: '仅用于会话内提醒',
          createdAt: DateTime.now(),
          type: MemoryType.session,
          source: 'manual',
        ),
      );
      await useCases.addSummary(
        SummaryEntity(
          id: 'fact_memory',
          title: '正式记录',
          content: '需要长期保存',
          createdAt: DateTime.now(),
          type: MemoryType.fact,
          source: 'manual',
        ),
      );

      expect(
        () => useCases.mergeMemoriesWithResolution(
          primaryId: 'session_memory',
          secondaryId: 'fact_memory',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Manual merge currently supports fact memories only',
          ),
        ),
      );
    });

    test('manual upgrade promotes fact to core and raises importance floor',
        () async {
      await useCases.addSummary(
        SummaryEntity(
          id: 'manual_core_upgrade',
          title: '发布节奏决策',
          content: '确认下周三晚间发布',
          createdAt: DateTime.now(),
          type: MemoryType.fact,
          source: 'manual',
          importance: 0.4,
        ),
      );

      final reason = await useCases.getFactUpgradeReason('manual_core_upgrade');
      await useCases.upgradeFactToCore('manual_core_upgrade');

      final upgraded = repository.getSummary('manual_core_upgrade');
      expect(reason, isNotEmpty);
      expect(upgraded, isNotNull);
      expect(upgraded!.type, MemoryType.core);
      expect(upgraded.importance, greaterThanOrEqualTo(0.8));
    });
  });
}

class _FakeMemorySlmService extends MemorySLMService {
  String _resolveTopic(String title, String content, {String? existingTopic}) {
    final stableExisting = existingTopic?.trim() ?? '';
    if (stableExisting.isNotEmpty) {
      return stableExisting;
    }

    final normalizedTitle = title.toLowerCase();
    final normalizedContent = content.toLowerCase();
    if (title.contains('买菜') ||
        normalizedContent.contains('牛奶') ||
        normalizedContent.contains('面包')) {
      return '购物清单';
    }
    if (normalizedTitle.contains('project launch')) {
      return 'project launch';
    }
    if (normalizedTitle.contains('rag') || normalizedContent.contains('rag')) {
      return 'RAG';
    }
    return title.trim().isNotEmpty ? title.trim() : '购物清单';
  }

  RuleSemanticProfile _buildProfile(
    String topic, {
    required List<String> tags,
  }) {
    final normalizedTopic = topic.trim();
    final lowerTopic = normalizedTopic.toLowerCase();
    final resolvedTags =
        tags.isEmpty ? <String>[normalizedTopic] : List<String>.from(tags);

    if (lowerTopic == 'rag') {
      return RuleSemanticProfile(
        language: RuleSemanticLanguage.cjk,
        domainKey: 'rag',
        domainLabel: 'RAG',
        facetKey: '',
        facetLabel: '',
        displayTopic: 'RAG',
        displayTitle: 'RAG',
        tags: resolvedTags,
        keywords: <String>['RAG', ...resolvedTags],
        confidence: 0.9,
      );
    }

    return RuleSemanticProfile(
      language: RuleSemanticLanguage.cjk,
      domainKey: '',
      domainLabel: '',
      facetKey: normalizedTopic,
      facetLabel: normalizedTopic,
      displayTopic: normalizedTopic,
      displayTitle: normalizedTopic,
      tags: resolvedTags,
      keywords: <String>[normalizedTopic, ...resolvedTags],
      confidence: 0.8,
    );
  }

  @override
  RuleSemanticProfile describeTextSemantics({
    required String title,
    required String content,
    List<String> tags = const <String>[],
  }) {
    return _buildProfile(
      _resolveTopic(title, content),
      tags: tags,
    );
  }

  @override
  RuleSemanticProfile describeSummarySemantics(SummaryEntity summary) {
    return _buildProfile(
      _resolveTopic(
        summary.title,
        summary.content,
        existingTopic: summary.topic,
      ),
      tags: summary.tags,
    );
  }

  @override
  Future<MemorySlmResponse<String>> extractTopic(
    String title,
    String content,
  ) async {
    return MemorySlmResponse<String>(
      success: true,
      data: _resolveTopic(title, content),
      fallbackUsed: MemorySlmFallbackMode.rules,
      latencyMs: 0,
    );
  }

  @override
  Future<MemorySlmResponse<bool>> isSameTopic(
    SummaryEntity entityA,
    SummaryEntity entityB,
  ) async {
    return const MemorySlmResponse<bool>(
      success: true,
      data: true,
      fallbackUsed: MemorySlmFallbackMode.rules,
      latencyMs: 0,
    );
  }

  @override
  Future<MemorySlmResponse<MemorySlmMergeResult>> mergeSessions(
    List<SummaryEntity> sessions,
  ) async {
    return MemorySlmResponse<MemorySlmMergeResult>(
      success: true,
      data: MemorySlmMergeResult(
        title: '买菜清单',
        content: sessions.map((session) => session.content).join('\n'),
        tags: const ['购物'],
      ),
      fallbackUsed: MemorySlmFallbackMode.rules,
      latencyMs: 0,
    );
  }

  @override
  Future<MemorySlmResponse<String>> generateUpgradeReason(
    SummaryEntity fact,
  ) async {
    return const MemorySlmResponse<String>(
      success: true,
      data: '这条记忆值得长期保留为核心记忆。',
      fallbackUsed: MemorySlmFallbackMode.rules,
      latencyMs: 0,
    );
  }
}

class _CanonicalRagMemorySlmService extends _FakeMemorySlmService {
  @override
  Future<MemorySlmResponse<String>> extractTopic(
    String title,
    String content,
  ) async {
    return const MemorySlmResponse<String>(
      success: true,
      data: 'RAG',
      fallbackUsed: MemorySlmFallbackMode.rules,
      latencyMs: 0,
    );
  }
}

class _InMemorySummaryRepository implements SummaryRepositoryInterface {
  final Map<String, SummaryEntity> _items = <String, SummaryEntity>{};

  @override
  int get totalCount => _items.length;

  @override
  Future<void> addSummary(SummaryEntity summary) async {
    _items[summary.id] = summary;
  }

  @override
  Future<void> clearAll() async {
    _items.clear();
  }

  @override
  Future<void> deleteSummary(String id) async {
    _items.remove(id);
  }

  @override
  SummaryEntity? getSummary(String id) => _items[id];

  @override
  List<SummaryEntity> getAllSummaries() {
    final values = _items.values.toList();
    values.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return values;
  }

  @override
  List<SummaryEntity> getSummariesBySource(String source) {
    return getAllSummaries()
        .where((summary) => summary.source == source)
        .toList();
  }

  @override
  List<SummaryEntity> getSummariesByTag(String tag) {
    return getAllSummaries()
        .where((summary) => summary.tags.contains(tag))
        .toList();
  }

  @override
  List<SummaryEntity> getSummariesByType(MemoryType type) {
    return getAllSummaries().where((summary) => summary.type == type).toList();
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> recordAccess(String id) async {
    final summary = _items[id];
    if (summary == null) {
      return;
    }
    _items[id] = summary.copyWith(
      accessCount: summary.accessCount + 1,
      lastAccessedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<SummaryEntity> searchSummaries(String query) {
    final normalized = query.trim().toLowerCase();
    return getAllSummaries()
        .where(
          (summary) =>
              summary.title.toLowerCase().contains(normalized) ||
              summary.content.toLowerCase().contains(normalized),
        )
        .toList();
  }

  @override
  Future<void> updateImportance(String id, double importance) async {
    final summary = _items[id];
    if (summary == null) {
      return;
    }
    _items[id] = summary.copyWith(
      importance: importance,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateSortOrders(List<SummaryEntity> summaries) async {
    for (var index = 0; index < summaries.length; index++) {
      final summary = summaries[index];
      _items[summary.id] = summary.copyWith(sortOrder: index);
    }
  }

  @override
  Future<void> updateSummary(SummaryEntity summary) async {
    _items[summary.id] = summary;
  }
}
