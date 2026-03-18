import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/config/memory_policy_config.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/summary_merge_models.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';

void main() {
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
  });
}

class _FakeMemorySlmService extends MemorySLMService {
  @override
  Future<MemorySlmResponse<String>> extractTopic(
    String title,
    String content,
  ) async {
    return const MemorySlmResponse<String>(
      success: true,
      data: '购物清单',
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
