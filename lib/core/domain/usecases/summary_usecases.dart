import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:local_vault/core/config/memory_policy_config.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/summary_merge_models.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/utils/memory_title_generator.dart';
import 'package:local_vault/core/utils/similarity_utils.dart';

/// 摘要业务用例
class SummaryUseCases {
  SummaryUseCases(
    this.repository,
    this.slmService, {
    this.policyConfig = MemoryPolicyConfig.defaults,
    this.memoryCapability,
  });

  final SummaryRepositoryInterface repository;
  final MemorySLMService slmService;
  final MemoryPolicyConfig policyConfig;
  final MemoryCapability? memoryCapability;

  /// 添加摘要
  Future<void> addSummary(SummaryEntity summary) async {
    final enhancedSummary = _enhanceWithStructuredTitle(summary);
    await repository.addSummary(enhancedSummary);
    if (enhancedSummary.type == MemoryType.fact) {
      await _upgradeFactToCoreIfNeeded(enhancedSummary.id);
    }
    _scheduleMemoryCompaction();
  }

  /// 使用结构化标题生成器优化标题
  SummaryEntity _enhanceWithStructuredTitle(SummaryEntity summary) {
    final rawContent = '${summary.title} ${summary.content}'.trim();
    if (rawContent.isEmpty) {
      return summary;
    }

    final titleResult =
        StructuredMemoryTitleGenerator.generateTitle(rawContent);
    if (titleResult.confidence >= 0.5 && titleResult.title.isNotEmpty) {
      debugPrint(
        '📝 [StructuredTitle] Generated title: ${titleResult.title} '
        '(confidence: ${(titleResult.confidence * 100).toStringAsFixed(1)}%)',
      );
      return summary.copyWith(
        title: titleResult.title,
        updatedAt: DateTime.now(),
      );
    }

    return summary;
  }

  /// 更新摘要
  Future<void> updateSummary(SummaryEntity summary) async {
    await repository.updateSummary(summary);
    if (summary.type == MemoryType.fact) {
      await _upgradeFactToCoreIfNeeded(summary.id);
    }
    _scheduleMemoryCompaction();
  }

  /// 删除摘要
  Future<void> deleteSummary(String id) async {
    await repository.deleteSummary(id);
    _scheduleMemoryCompaction();
  }

  /// 获取单个摘要
  SummaryEntity? getSummary(String id) {
    return repository.getSummary(id);
  }

  /// 获取所有摘要
  List<SummaryEntity> getAllSummaries() {
    return repository.getAllSummaries();
  }

  /// 搜索摘要
  List<SummaryEntity> searchSummaries(String query) {
    return repository.searchSummaries(query);
  }

  /// 更新排序
  Future<void> updateSortOrders(List<SummaryEntity> summaries) async {
    await repository.updateSortOrders(summaries);
  }

  /// 根据标签获取摘要
  List<SummaryEntity> getSummariesByTag(String tag) {
    return repository.getSummariesByTag(tag);
  }

  /// 根据来源获取摘要
  List<SummaryEntity> getSummariesBySource(String source) {
    return repository.getSummariesBySource(source);
  }

  /// 记录访问
  Future<void> recordAccess(String id) async {
    await repository.recordAccess(id);
    await _upgradeFactToCoreIfNeeded(id);
    _scheduleMemoryCompaction();
  }

  /// 更新重要性评分
  Future<void> updateImportance(String id, double importance) async {
    await repository.updateImportance(id, importance);
    await _upgradeFactToCoreIfNeeded(id);
    _scheduleMemoryCompaction();
  }

  /// 获取事实记忆升级为核心记忆的说明
  Future<String?> getFactUpgradeReason(String id) async {
    final summary = getSummary(id);
    if (summary == null || summary.type != MemoryType.fact) {
      return null;
    }

    final response = await slmService.generateUpgradeReason(summary);
    final reason = response.data.trim();
    return reason.isEmpty ? null : reason;
  }

  /// 手动将事实记忆升级为核心记忆
  Future<SummaryEntity?> upgradeFactToCore(String id) async {
    final summary = getSummary(id);
    if (summary == null || summary.type != MemoryType.fact) {
      return null;
    }

    final updated = summary.copyWith(
      type: MemoryType.core,
      importance: max(
        summary.importance,
        policyConfig.coreUpgrade.importanceThreshold,
      ),
      updatedAt: DateTime.now(),
    );
    await repository.updateSummary(updated);
    _scheduleMemoryCompaction();
    return updated;
  }

  /// 根据记忆类型获取
  List<SummaryEntity> getSummariesByType(MemoryType type) {
    return repository.getSummariesByType(type);
  }

  /// 添加记忆（带去重）
  Future<void> addWithDeduplication(
    SummaryEntity summary, {
    double? similarityThreshold,
  }) async {
    final enhancedSummary = _enhanceWithStructuredTitle(summary);
    final effectiveSimilarityThreshold =
        similarityThreshold ?? policyConfig.similarity.deduplicationThreshold;
    final existingSummaries = getAllSummaries();

    final duplicate = _findExactDuplicate(existingSummaries, enhancedSummary);
    if (duplicate != null) {
      debugPrint(
          '🔄 [Deduplication] Exact duplicate detected: ${enhancedSummary.title}');
      await updateSummary(
        duplicate.copyWith(
          lastAccessedAt: DateTime.now(),
          accessCount: duplicate.accessCount + 1,
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }

    double bestSimilarity = 0.0;
    for (final existing in existingSummaries) {
      final similarity = SimilarityUtils.calculateMemorySimilarity(
        enhancedSummary.title,
        enhancedSummary.content,
        existing.title,
        existing.content,
      );

      bestSimilarity = max(bestSimilarity, similarity);
      if (similarity >= effectiveSimilarityThreshold) {
        debugPrint(
          '🔗 [Deduplication] High-similarity merge: ${enhancedSummary.title} -> ${existing.title} '
          '(similarity: ${(similarity * 100).toStringAsFixed(1)}%)',
        );
        final merged = _mergeMemories(existing, enhancedSummary);
        await updateSummary(merged);
        return;
      }
    }

    debugPrint(
      '✅ [Deduplication] Added unique content: ${enhancedSummary.title} '
      '(highest similarity: ${(bestSimilarity * 100).toStringAsFixed(1)}%)',
    );
    await addSummary(enhancedSummary);
  }

  /// 添加事实记忆，但不自动合并相似事实，改为返回合并候选供 UI 决策。
  Future<FactSummarySaveResult> addFactSummary(
    SummaryEntity summary, {
    double? similarityThreshold,
  }) async {
    final enhancedSummary = _enhanceWithStructuredTitle(summary);
    final factSummary = enhancedSummary.type == MemoryType.fact
        ? enhancedSummary
        : enhancedSummary.copyWith(type: MemoryType.fact);
    final duplicate =
        _findExactDuplicate(getSummariesByType(MemoryType.fact), factSummary);

    if (duplicate != null) {
      final updated = duplicate.copyWith(
        lastAccessedAt: DateTime.now(),
        accessCount: duplicate.accessCount + 1,
        updatedAt: DateTime.now(),
      );
      await updateSummary(updated);
      return FactSummarySaveResult(
        savedSummary: updated,
        wasExactDuplicate: true,
      );
    }

    await addSummary(factSummary);
    final savedSummary = getSummary(factSummary.id) ?? factSummary;
    if (savedSummary.type != MemoryType.fact) {
      return FactSummarySaveResult(savedSummary: savedSummary);
    }

    return FactSummarySaveResult(
      savedSummary: savedSummary,
      mergeCandidates: findMergeCandidates(
        savedSummary,
        threshold: similarityThreshold,
        allowedTypes: const <MemoryType>{MemoryType.fact},
      ),
    );
  }

  /// Adds a session memory and schedules background processing.
  /// Delegates ingestion to the MemoryCapability runtime.
  Future<void> addSessionMemory(SummaryEntity summary) async {
    final enhancedSummary = _enhanceWithStructuredTitle(summary);
    final sessionSummaries = getSummariesByType(MemoryType.session);
    SummaryEntity? savedSession;

    final duplicate = _findExactDuplicate(sessionSummaries, enhancedSummary);
    if (duplicate != null) {
      savedSession = duplicate.copyWith(
        lastAccessedAt: DateTime.now(),
        accessCount: duplicate.accessCount + 1,
        updatedAt: DateTime.now(),
      );
      await updateSummary(savedSession);
    } else {
      savedSession = enhancedSummary.copyWith(type: MemoryType.session);
      await addSummary(savedSession);
    }

    final capability = memoryCapability;
    if (capability != null) {
      unawaited(capability.ingestSession(savedSession));
      return;
    }

    throw StateError('addSessionMemory requires a MemoryCapability');
  }

  /// 查找完全重复的内容（标准化后比较）
  SummaryEntity? _findExactDuplicate(
    List<SummaryEntity> existing,
    SummaryEntity incoming,
  ) {
    final incomingContent = _normalizeContent(incoming.content);
    final incomingTitle = _normalizeTitle(incoming.title);

    for (final item in existing) {
      final normalizedContent = _normalizeContent(item.content);
      final normalizedTitle = _normalizeTitle(item.title);

      if (normalizedTitle == incomingTitle &&
          normalizedContent == incomingContent) {
        return item;
      }
    }
    return null;
  }

  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\u4E00-\u9FFF ]'), '')
        .trim();
  }

  String _normalizeContent(String content) {
    return content.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 合并两个相似记忆
  SummaryEntity _mergeMemories(SummaryEntity existing, SummaryEntity newOne) {
    final mergedTags = {...existing.tags, ...newOne.tags}.toList();
    final mergedContent = _mergeContent(existing.content, newOne.content);

    return existing.copyWith(
      content: mergedContent,
      tags: mergedTags,
      updatedAt: DateTime.now(),
      importance: (existing.importance + newOne.importance) / 2,
      accessCount: existing.accessCount + newOne.accessCount,
      lastAccessedAt: DateTime.now(),
    );
  }

  /// 合并记忆内容，避免重复
  String _mergeContent(String content1, String content2) {
    if (content1.contains(content2)) {
      return content1;
    }
    if (content2.contains(content1)) {
      return content2;
    }

    final normalized1 = _normalizeContent(content1);
    final normalized2 = _normalizeContent(content2);

    if (normalized1.contains(normalized2) ||
        normalized2.contains(normalized1)) {
      return normalized1.length > normalized2.length ? content1 : content2;
    }

    return '$content1\n\n$content2';
  }

  /// 应用遗忘曲线
  Future<void> applyForgettingCurve() async {
    final allSummaries = getAllSummaries();
    final now = DateTime.now();
    final curve = policyConfig.forgettingCurve;

    for (final summary in allSummaries) {
      if (summary.type == MemoryType.core) {
        continue;
      }

      if (summary.type == MemoryType.fact) {
        await _upgradeFactToCoreIfNeeded(summary.id);
      }
      final current = getSummary(summary.id);
      if (current == null || current.type != MemoryType.fact) {
        continue;
      }

      final daysOld = now.difference(current.createdAt).inDays;
      if (daysOld <= curve.startDays) {
        continue;
      }

      final decayFactor = max(
        curve.minImportance,
        1.0 -
            ((daysOld - curve.startDays) / curve.decayPeriodDays) *
                curve.decayRate,
      );
      final newImportance = (current.importance * decayFactor)
          .clamp(
            curve.minImportance,
            1.0,
          )
          .toDouble();

      if (newImportance != current.importance) {
        await repository.updateSummary(
          current.copyWith(
            importance: newImportance,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  /// 清理过期会话记忆（默认 2 小时）
  Future<void> cleanupSessionMemories({
    Duration? maxAge,
  }) async {
    final capability = memoryCapability;
    if (capability != null) {
      unawaited(capability.compact());
    }

    final sessionMemories = getSummariesByType(MemoryType.session);
    final now = DateTime.now();
    final effectiveMaxAge = maxAge ?? policyConfig.sessionMaxAge;

    for (final session in sessionMemories) {
      if (session.isSessionProtected) {
        continue;
      }

      final referenceTime =
          session.lastAccessedAt ?? session.updatedAt ?? session.createdAt;
      if (now.difference(referenceTime) > effectiveMaxAge) {
        await deleteSummary(session.id);
      }
    }
  }

  void _scheduleMemoryCompaction() {
    final capability = memoryCapability;
    if (capability == null) {
      return;
    }
    unawaited(capability.compact());
  }

  /// 查找相似记忆
  List<SummaryEntity> findSimilarMemories(
    SummaryEntity target, {
    double? threshold,
  }) {
    return findMergeCandidates(
      target,
      threshold: threshold,
      allowedTypes: const <MemoryType>{
        MemoryType.fact,
        MemoryType.session,
        MemoryType.core,
      },
    ).map((candidate) => candidate.summary).toList(growable: false);
  }

  List<SummaryMergeCandidate> findMergeCandidates(
    SummaryEntity target, {
    double? threshold,
    Set<MemoryType> allowedTypes = const <MemoryType>{MemoryType.fact},
  }) {
    final effectiveThreshold =
        threshold ?? policyConfig.similarity.relatedMemoryThreshold;
    final candidates = <SummaryMergeCandidate>[];

    for (final summary in getAllSummaries()) {
      if (summary.id == target.id || !allowedTypes.contains(summary.type)) {
        continue;
      }

      final similarity = SimilarityUtils.calculateMemorySimilarity(
        target.title,
        target.content,
        summary.title,
        summary.content,
      );

      if (similarity >= effectiveThreshold) {
        candidates.add(
          SummaryMergeCandidate(
            summary: summary,
            similarity: similarity,
          ),
        );
      }
    }

    candidates.sort((a, b) => b.similarity.compareTo(a.similarity));
    return candidates;
  }

  /// 手动合并两个记忆
  Future<void> mergeMemories(String id1, String id2) async {
    await mergeMemoriesWithResolution(
      primaryId: id1,
      secondaryId: id2,
      resolution: const SummaryMergeResolution(),
    );
  }

  Future<void> mergeMemoriesWithResolution({
    required String primaryId,
    required String secondaryId,
    SummaryMergeResolution resolution = const SummaryMergeResolution(),
  }) async {
    final primarySummary = getSummary(primaryId);
    final secondarySummary = getSummary(secondaryId);

    if (primarySummary == null || secondarySummary == null) {
      throw ArgumentError('Requested memory could not be found');
    }
    if (primarySummary.type != MemoryType.fact ||
        secondarySummary.type != MemoryType.fact) {
      throw StateError('Manual merge currently supports fact memories only');
    }

    final merged = buildMergedSummary(
      primarySummary,
      secondarySummary,
      resolution: resolution,
    );
    await updateSummary(merged);
    await deleteSummary(secondarySummary.id);
  }

  SummaryEntity buildMergedSummary(
    SummaryEntity primary,
    SummaryEntity secondary, {
    SummaryMergeResolution resolution = const SummaryMergeResolution(),
  }) {
    return primary.copyWith(
      title: resolution.title == SummaryMergeFieldChoice.incoming
          ? secondary.title
          : resolution.title == SummaryMergeFieldChoice.existing
              ? primary.title
              : resolution.title == SummaryMergeFieldChoice.combined
                  ? '$primary.title $secondary.title'
                  : primary.title,
      content: resolution.content == SummaryMergeFieldChoice.incoming
          ? secondary.content
          : resolution.content == SummaryMergeFieldChoice.existing
              ? primary.content
              : resolution.content == SummaryMergeFieldChoice.combined
                  ? '$primary.content\n\n$secondary.content'
                  : primary.content,
      tags: resolution.tags == SummaryMergeFieldChoice.incoming
          ? secondary.tags
          : resolution.tags == SummaryMergeFieldChoice.existing
              ? primary.tags
              : resolution.tags == SummaryMergeFieldChoice.combined
                  ? {...primary.tags, ...secondary.tags}.toList()
                  : primary.tags,
      createdAt: primary.createdAt.isBefore(secondary.createdAt)
          ? primary.createdAt
          : secondary.createdAt,
      updatedAt: DateTime.now(),
      lastAccessedAt: primary.lastAccessedAt
                  ?.isAfter(secondary.lastAccessedAt ?? DateTime(1970)) ??
              false
          ? primary.lastAccessedAt
          : secondary.lastAccessedAt,
      topic: primary.topic ?? secondary.topic,
      importance: (primary.importance + secondary.importance) / 2,
      accessCount: primary.accessCount + secondary.accessCount,
    );
  }

  Future<void> _upgradeFactToCoreIfNeeded(String id) async {
    final summary = getSummary(id);
    if (summary == null ||
        !summary.shouldUpgradeToCoreWithPolicy(policyConfig)) {
      return;
    }

    await repository.updateSummary(
      summary.copyWith(
        type: MemoryType.core,
        updatedAt: DateTime.now(),
      ),
    );
  }
















}


