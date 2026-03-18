import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:local_vault/core/config/memory_policy_config.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/summary_merge_models.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/utils/similarity_utils.dart';

/// 摘要业务用例
class SummaryUseCases {
  SummaryUseCases(
    this.repository,
    this.slmService, {
    this.policyConfig = MemoryPolicyConfig.defaults,
  });

  final SummaryRepositoryInterface repository;
  final MemorySLMService slmService;
  final MemoryPolicyConfig policyConfig;

  /// 添加摘要
  Future<void> addSummary(SummaryEntity summary) async {
    await repository.addSummary(summary);
    if (summary.type == MemoryType.fact) {
      await _upgradeFactToCoreIfNeeded(summary.id);
    }
  }

  /// 更新摘要
  Future<void> updateSummary(SummaryEntity summary) async {
    await repository.updateSummary(summary);
    if (summary.type == MemoryType.fact) {
      await _upgradeFactToCoreIfNeeded(summary.id);
    }
  }

  /// 删除摘要
  Future<void> deleteSummary(String id) async {
    await repository.deleteSummary(id);
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
  }

  /// 更新重要性评分
  Future<void> updateImportance(String id, double importance) async {
    await repository.updateImportance(id, importance);
    await _upgradeFactToCoreIfNeeded(id);
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
    final effectiveSimilarityThreshold =
        similarityThreshold ?? policyConfig.similarity.deduplicationThreshold;
    final existingSummaries = getAllSummaries();

    final duplicate = _findExactDuplicate(existingSummaries, summary);
    if (duplicate != null) {
      debugPrint('🔄 [去重] 检测到完全重复：${summary.title}');
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
        summary.title,
        summary.content,
        existing.title,
        existing.content,
      );

      bestSimilarity = max(bestSimilarity, similarity);
      if (similarity >= effectiveSimilarityThreshold) {
        debugPrint(
          '🔗 [去重] 高相似度合并：${summary.title} -> ${existing.title} '
          '(相似度：${(similarity * 100).toStringAsFixed(1)}%)',
        );
        final merged = _mergeMemories(existing, summary);
        await updateSummary(merged);
        return;
      }
    }

    debugPrint(
      '✅ [去重] 新增唯一内容：${summary.title} '
      '(最高相似度：${(bestSimilarity * 100).toStringAsFixed(1)}%)',
    );
    await addSummary(summary);
  }

  /// 添加事实记忆，但不自动合并相似事实，改为返回合并候选供 UI 决策。
  Future<FactSummarySaveResult> addFactSummary(
    SummaryEntity summary, {
    double? similarityThreshold,
  }) async {
    final factSummary = summary.type == MemoryType.fact
        ? summary
        : summary.copyWith(type: MemoryType.fact);
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

  /// 添加会话记忆（仅在会话内合并）
  Future<void> addSessionMemory(SummaryEntity summary) async {
    final sessionSummaries = getSummariesByType(MemoryType.session);

    final duplicate = _findExactDuplicate(sessionSummaries, summary);
    if (duplicate != null) {
      await updateSummary(
        duplicate.copyWith(
          lastAccessedAt: DateTime.now(),
          accessCount: duplicate.accessCount + 1,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await addSummary(summary.copyWith(type: MemoryType.session));
    }

    await checkAndMergeSessionBatches();
  }

  /// 检查并合并 Session 批次
  Future<int> checkAndMergeSessionBatches() async {
    final sessions = getSummariesByType(MemoryType.session);
    if (sessions.isEmpty) {
      return 0;
    }

    final batches = await _buildSessionBatches(sessions);
    await _syncSessionProtection(sessions, batches);

    var mergedCount = 0;
    for (final batch in batches) {
      if (!_isEligibleForMerge(batch.sessions)) {
        continue;
      }

      final mergeResponse = await slmService.mergeSessions(batch.sessions);
      if (!mergeResponse.success || mergeResponse.data.content.trim().isEmpty) {
        continue;
      }

      final mergedFact = _buildFactFromBatch(
        batch,
        mergeResponse.data,
      );
      await addSummary(mergedFact);

      for (final session in batch.sessions) {
        await deleteSummary(session.id);
      }
      mergedCount += 1;
    }

    return mergedCount;
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
    await checkAndMergeSessionBatches();

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
      throw ArgumentError('找不到指定的记忆');
    }
    if (primarySummary.type != MemoryType.fact ||
        secondarySummary.type != MemoryType.fact) {
      throw StateError('当前仅支持事实记忆手动合并');
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
      title: _resolveTextChoice(
        existingValue: primary.title,
        incomingValue: secondary.title,
        choice: resolution.title,
        combine: _mergeTitle,
      ),
      content: _resolveTextChoice(
        existingValue: primary.content,
        incomingValue: secondary.content,
        choice: resolution.content,
        combine: _mergeContent,
      ),
      tags: _resolveTagChoice(
        existingTags: primary.tags,
        incomingTags: secondary.tags,
        choice: resolution.tags,
      ),
      createdAt: primary.createdAt.isBefore(secondary.createdAt)
          ? primary.createdAt
          : secondary.createdAt,
      updatedAt: DateTime.now(),
      lastAccessedAt: _latestDate(
        primary.lastAccessedAt,
        secondary.lastAccessedAt,
      ),
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

  Future<List<_SessionBatch>> _buildSessionBatches(
    List<SummaryEntity> sessions,
  ) async {
    final batchPolicy = policyConfig.sessionBatching;
    final sortedSessions = List<SummaryEntity>.from(sessions)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final batches = <_SessionBatch>[];

    for (final rawSession in sortedSessions) {
      final session = await _ensureTopic(rawSession);
      var assigned = false;

      for (final batch in batches) {
        final anchor = batch.sessions.first;
        final ruleScore = _calculateRuleScore(anchor, session);
        if (ruleScore < batchPolicy.minimumRuleScoreForSemanticCheck) {
          continue;
        }

        final semanticResponse = await slmService.isSameTopic(anchor, session);
        final semanticScore = semanticResponse.data ? 1.0 : 0.0;
        final normalizedBatchTopic = _normalizeTitle(batch.topic);
        final normalizedSessionTopic = _normalizeTitle(session.topic ?? '');
        final topicMatches = normalizedBatchTopic.isNotEmpty &&
            normalizedBatchTopic == normalizedSessionTopic;
        final combinedScore = topicMatches
            ? max(batchPolicy.topicMatchScoreFloor, ruleScore)
            : (ruleScore * batchPolicy.ruleWeight) +
                (semanticScore * batchPolicy.semanticWeight);

        if (combinedScore >= batchPolicy.combinedScoreThreshold) {
          batch.sessions.add(session);
          assigned = true;
          break;
        }
      }

      if (!assigned) {
        batches.add(
          _SessionBatch(
            topic: session.topic ?? _normalizeTitle(session.title),
            sessions: <SummaryEntity>[session],
          ),
        );
      }
    }

    return batches;
  }

  Future<SummaryEntity> _ensureTopic(SummaryEntity session) async {
    final existingTopic = session.topic?.trim();
    if (existingTopic != null && existingTopic.isNotEmpty) {
      return session;
    }

    final topicResponse = await slmService.extractTopic(
      session.title,
      session.content,
    );
    final topic = topicResponse.data.trim();
    final updated = session.copyWith(topic: topic);
    await repository.updateSummary(updated);
    return updated;
  }

  Future<void> _syncSessionProtection(
    List<SummaryEntity> originalSessions,
    List<_SessionBatch> batches,
  ) async {
    final now = DateTime.now();
    final candidateIds = <String, _SessionBatch>{};
    for (final batch in batches.where((batch) => batch.sessions.length >= 2)) {
      for (final session in batch.sessions) {
        candidateIds[session.id] = batch;
      }
    }

    for (final session in originalSessions) {
      final batch = candidateIds[session.id];
      final nextTopic = batch?.topic ?? session.topic;
      final nextProtectedUntil = batch == null
          ? null
          : now.add(policyConfig.candidateProtectionWindow);
      final hasProtectionChanged = batch == null
          ? session.protectedUntil != null
          : session.protectedUntil == null ||
              session.protectedUntil!.isBefore(now) ||
              session.protectedUntil!
                      .difference(nextProtectedUntil!)
                      .inMinutes
                      .abs() >
                  1;
      final hasTopicChanged = nextTopic != null && nextTopic != session.topic;

      if (!hasProtectionChanged && !hasTopicChanged) {
        continue;
      }

      await repository.updateSummary(
        session.copyWith(
          topic: nextTopic,
          clearProtectedUntil: batch == null,
          protectedUntil: batch == null ? null : nextProtectedUntil,
        ),
      );
    }
  }

  bool _isEligibleForMerge(List<SummaryEntity> sessions) {
    return sessions.length >=
            policyConfig.sessionBatching.minimumMergeBatchSize &&
        sessions.any((session) => session.content.trim().isNotEmpty);
  }

  double _calculateRuleScore(SummaryEntity a, SummaryEntity b) {
    final batchPolicy = policyConfig.sessionBatching;
    double score = 0.0;

    final titleA = _normalizeTitle(a.title);
    final titleB = _normalizeTitle(b.title);
    if (titleA.isNotEmpty && titleA == titleB) {
      score += batchPolicy.exactTitleMatchWeight;
    } else if (titleA.isNotEmpty &&
        titleB.isNotEmpty &&
        (titleA.contains(titleB) || titleB.contains(titleA))) {
      score += batchPolicy.partialTitleMatchWeight;
    }

    final similarity = SimilarityUtils.calculateMemorySimilarity(
      a.title,
      a.content,
      b.title,
      b.content,
    );
    score += similarity * batchPolicy.semanticSimilarityWeight;

    if (a.tags.isNotEmpty && b.tags.isNotEmpty) {
      final overlap = a.tags.toSet().intersection(b.tags.toSet()).length;
      final maxSize = max(a.tags.length, b.tags.length);
      score += (overlap / max(1, maxSize)) * batchPolicy.tagOverlapWeight;
    }

    if (_sourceFamily(a.source) == _sourceFamily(b.source)) {
      score += batchPolicy.sameSourceWeight;
    }

    final timeDiff = a.createdAt.difference(b.createdAt).abs();
    if (timeDiff <= policyConfig.timeThresholds.shortTerm) {
      score += batchPolicy.shortTermTimeWeight;
    } else if (timeDiff <= policyConfig.timeThresholds.mediumTerm) {
      score += batchPolicy.mediumTermTimeWeight;
    }

    return score.clamp(0.0, 1.0);
  }

  String _sourceFamily(String source) {
    final parts = source.split('_');
    return parts.isEmpty ? source : parts.first;
  }

  String _mergeTitle(String title1, String title2) {
    final normalized1 = _normalizeTitle(title1);
    final normalized2 = _normalizeTitle(title2);
    if (normalized1 == normalized2) {
      return title1.length >= title2.length ? title1 : title2;
    }
    if (title1.contains(title2)) {
      return title1;
    }
    if (title2.contains(title1)) {
      return title2;
    }
    return title2.length >= title1.length ? title2 : title1;
  }

  String _resolveTextChoice({
    required String existingValue,
    required String incomingValue,
    required SummaryMergeFieldChoice choice,
    required String Function(String existing, String incoming) combine,
  }) {
    switch (choice) {
      case SummaryMergeFieldChoice.existing:
        return existingValue;
      case SummaryMergeFieldChoice.incoming:
        return incomingValue;
      case SummaryMergeFieldChoice.combined:
        return combine(existingValue, incomingValue);
    }
  }

  List<String> _resolveTagChoice({
    required List<String> existingTags,
    required List<String> incomingTags,
    required SummaryMergeFieldChoice choice,
  }) {
    switch (choice) {
      case SummaryMergeFieldChoice.existing:
        return existingTags;
      case SummaryMergeFieldChoice.incoming:
        return incomingTags;
      case SummaryMergeFieldChoice.combined:
        return <String>{...existingTags, ...incomingTags}.toList();
    }
  }

  DateTime? _latestDate(DateTime? left, DateTime? right) {
    if (left == null) {
      return right;
    }
    if (right == null) {
      return left;
    }
    return left.isAfter(right) ? left : right;
  }

  SummaryEntity _buildFactFromBatch(
    _SessionBatch batch,
    MemorySlmMergeResult mergeResult,
  ) {
    final accessCount = batch.sessions
        .fold<int>(0, (sum, session) => sum + session.accessCount);
    final importance = batch.sessions.fold<double>(
          0.0,
          (sum, session) => sum + session.importance,
        ) /
        batch.sessions.length;

    DateTime? lastAccessedAt;
    for (final session in batch.sessions) {
      final candidate = session.lastAccessedAt;
      if (candidate == null) {
        continue;
      }
      if (lastAccessedAt == null || candidate.isAfter(lastAccessedAt)) {
        lastAccessedAt = candidate;
      }
    }

    return SummaryEntity.create(
      title: mergeResult.title,
      content: mergeResult.content,
      tags: mergeResult.tags,
      type: MemoryType.fact,
      source: 'slm_session_merge',
      topic: batch.topic,
      importance: importance,
    ).copyWith(
      createdAt: batch.sessions.first.createdAt,
      accessCount: accessCount,
      lastAccessedAt: lastAccessedAt,
      updatedAt: DateTime.now(),
    );
  }
}

class _SessionBatch {
  _SessionBatch({
    required this.topic,
    required this.sessions,
  });

  final String topic;
  final List<SummaryEntity> sessions;
}
