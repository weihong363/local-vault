import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:local_vault/core/config/memory_policy_config.dart';
import 'package:local_vault/core/domain/entities/rule_semantic_profile.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';
import 'package:local_vault/core/memory_runtime/repositories/memory_sidecar_repository.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/utils/similarity_utils.dart';
import 'package:local_vault/core/utils/summary_text_utils.dart';
import 'package:local_vault/core/utils/topic_placeholder_utils.dart';

class NoopModelRuntimeProvider implements ModelRuntimeProvider {
  const NoopModelRuntimeProvider();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<String> resolveVersion() async => 'rules-only';
}

class RuleBasedMemoryCapability implements MemoryCapability {
  RuleBasedMemoryCapability({
    required SummaryRepositoryInterface summaryRepository,
    required MemorySidecarRepository sidecarRepository,
    required MemoryCompressor compressor,
    required MemoryMerger merger,
    required MemoryRetriever retriever,
    required ContextAssembler contextAssembler,
    required MemoryWorker worker,
    required MemoryPolicy policy,
    required MemorySLMService slmService,
    required ModelRuntimeProvider modelRuntimeProvider,
  })  : _summaryRepository = summaryRepository,
        _sidecarRepository = sidecarRepository,
        _compressor = compressor,
        _merger = merger,
        _retriever = retriever,
        _contextAssembler = contextAssembler,
        _worker = worker,
        _policy = policy,
        _slmService = slmService,
        _modelRuntimeProvider = modelRuntimeProvider;

  final SummaryRepositoryInterface _summaryRepository;
  final MemorySidecarRepository _sidecarRepository;
  final MemoryCompressor _compressor;
  final MemoryMerger _merger;
  final MemoryRetriever _retriever;
  final ContextAssembler _contextAssembler;
  final MemoryWorker _worker;
  final MemoryPolicy _policy;
  final MemorySLMService _slmService;
  final ModelRuntimeProvider _modelRuntimeProvider;

  Future<void>? _scheduledDrain;

  @override
  Future<MemoryContextBundle> buildContext(
    MemoryRetrievalRequest request,
  ) async {
    final retrieval = await retrieve(request);
    return _contextAssembler.assemble(retrieval);
  }

  @override
  Future<int> compact() async {
    final jobs = _worker.takePendingJobs();
    _worker.beginProcessing();
    try {
      final sessions =
          _summaryRepository.getSummariesByType(MemoryType.session);
      final compressionResult = await _compressor.compressSessions(sessions);

      for (final session in compressionResult.updatedSessions) {
        if (compressionResult.consumedSessionIds.contains(session.id)) {
          continue;
        }
        await _summaryRepository.updateSummary(session);
      }

      for (final fact in compressionResult.mergedFacts) {
        // Note: 自动晋升逻辑已移至 SummaryUseCases 统一管理
        // 此处不再进行实时判断，而是等待后台定期扫描处理
        await _summaryRepository.addSummary(fact);
      }

      for (final sessionId in compressionResult.consumedSessionIds) {
        await _summaryRepository.deleteSummary(sessionId);
      }

      if (compressionResult.archiveRecords.isNotEmpty) {
        await _sidecarRepository.addArchiveRecords(
          compressionResult.archiveRecords,
        );
        await _sidecarRepository.trimArchiveRecords(
          _policy.archiveRetentionLimit,
        );
      }

      // 新增：处理直接生成的状态记录
      if (compressionResult.stateUpdates.isNotEmpty) {
        final previousRecords = _sidecarRepository.getAllStateRecords();
        final allStates = <StateRecord>[
          ...compressionResult.stateUpdates,
          ..._rebuildStateRecords(
            await _rebuildMemoryUnits(),
            previousRecords: previousRecords,
          ),
        ];

        // 去重（按 storageKey）
        final uniqueStates = <String, StateRecord>{};
        for (final state in allStates) {
          uniqueStates[state.storageKey] = state;
        }

        final finalStates = uniqueStates.values.toList()
          ..sort((a, b) => b.importance.compareTo(a.importance));

        await _sidecarRepository.replaceStateRecords(finalStates);
      } else {
        final rebuiltUnits = await _rebuildMemoryUnits();
        final rebuiltStates = _rebuildStateRecords(
          rebuiltUnits,
          previousRecords: _sidecarRepository.getAllStateRecords(),
        );

        await _sidecarRepository.replaceMemoryUnits(rebuiltUnits);
        await _sidecarRepository.replaceStateRecords(rebuiltStates);
      }

      _worker.completeProcessing();
      return max(compressionResult.mergedCount, jobs.length);
    } catch (error) {
      _worker.completeProcessing(errorMessage: error.toString());
      rethrow;
    }
  }

  @override
  Future<MemoryRuntimeDiagnostics> diagnose() async {
    await _modelRuntimeProvider.isAvailable();
    final stateCount = _sidecarRepository.getAllStateRecords().length;
    final unitCount = _sidecarRepository.getAllMemoryUnits().length;
    final archiveCount = _sidecarRepository.getAllArchiveRecords().length;
    return _worker.snapshot(
      stateRecordCount: stateCount,
      memoryUnitCount: unitCount,
      archiveRecordCount: archiveCount,
    );
  }

  @override
  Future<void> ingestSession(SummaryEntity summary) async {
    await _worker.enqueue(MemoryCompressionJob.sessionIngest(summary.id));
    _scheduleBackgroundDrain();
  }

  @override
  Future<MemoryRetrievalResult> retrieve(MemoryRetrievalRequest request) {
    return _retriever.retrieve(request);
  }

  /// 重建状态记录，支持多类型状态推导
  ///
  /// 增强的状态推导逻辑：
  /// - task_state: 任务、待办、跟进事项
  /// - project_state: 项目、发布、里程碑
  /// - user_preference_state: 用户偏好、习惯
  /// - topic_state: 通用主题状态
  List<StateRecord> _rebuildStateRecords(
    List<MemoryUnit> units, {
    required List<StateRecord> previousRecords,
  }) {
    final previousByKey = <String, StateRecord>{
      for (final record in previousRecords) record.storageKey: record,
    };
    final groupedPatches = <String, List<StatePatch>>{};

    // 第一轮：收集所有状态补丁
    for (final unit in units) {
      final patch = _deriveStatePatch(unit);
      if (patch == null ||
          patch.confidence < _policy.stateConfidenceThreshold) {
        continue;
      }
      groupedPatches.putIfAbsent(patch.storageKey, () => <StatePatch>[]).add(
            patch,
          );
    }

    // 第二轮：合并同 key 的补丁并构建记录
    final records = <StateRecord>[];
    for (final entry in groupedPatches.entries) {
      final mergedPatch = _mergeStatePatches(entry.value);
      final previous = previousByKey[entry.key];

      // 检查是否发生变化
      final changed = previous == null ||
          previous.summary != mergedPatch.summary ||
          previous.topic != mergedPatch.topic ||
          !_sameStrings(previous.keywords, mergedPatch.keywords) ||
          (previous.importance - mergedPatch.importance).abs() > 0.001;

      // 版本号控制：首次创建为 v1，变化时递增，否则保持不变（优化：简化表达式）
      records.add(
        StateRecord(
          namespace: mergedPatch.namespace,
          key: mergedPatch.key,
          summary: mergedPatch.summary,
          topic: mergedPatch.topic,
          keywords: mergedPatch.keywords,
          importance: mergedPatch.importance,
          version: previous?.version == null || changed
              ? (previous?.version ?? 0) + 1
              : previous.version,
          updatedAt: DateTime.now(),
        ),
      );
    }

    // 按重要性降序排序
    records.sort((a, b) => b.importance.compareTo(a.importance));
    return records;
  }

  Future<List<MemoryUnit>> _rebuildMemoryUnits() async {
    final sourceSummaries = _summaryRepository
        .getAllSummaries()
        .where((summary) => summary.type != MemoryType.session)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // 优化：先按 topic 分组，组内再合并
    final byTopic = <String, List<SummaryEntity>>{};
    for (final summary in sourceSummaries) {
      final profile = _slmService.describeSummarySemantics(summary);
      final topic = _stableTopic(summary, profile);
      final normalizedTopic = _normalize(topic);

      byTopic.putIfAbsent(normalizedTopic, () => []).add(summary);
    }

    final units = <MemoryUnit>[];

    // 对每个 topic 组内进行合并
    for (final entries in byTopic.entries) {
      final groupUnits = <MemoryUnit>[];

      for (final summary in entries.value) {
        final candidate = _buildCandidateUnit(summary);
        var merged = false;

        // 在组内寻找最佳合并对象（而不仅仅是第一个）
        MemoryUnit? bestMatch;
        int bestMatchIndex = -1;
        double bestScore = 0.0;

        for (var index = 0; index < groupUnits.length; index++) {
          final existing = groupUnits[index];
          if (_merger.shouldMerge(existing, candidate)) {
            // 计算合并优先级分数
            final score = _calculateMergePriority(existing, candidate);
            if (score > bestScore) {
              bestScore = score;
              bestMatch = existing;
              bestMatchIndex = index;
            }
          }
        }

        if (bestMatch != null) {
          groupUnits[bestMatchIndex] =
              await _merger.mergeUnits(bestMatch, candidate);
          merged = true;
        }

        if (!merged) {
          groupUnits.add(candidate);
        }
      }

      // 将组内合并后的结果加入总列表
      units.addAll(groupUnits);
    }

    units.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return units;
  }

  MemoryUnit _buildCandidateUnit(SummaryEntity summary) {
    final profile = _slmService.describeSummarySemantics(summary);
    final topic = _stableTopic(summary, profile);
    final updatedAt =
        summary.updatedAt ?? summary.lastAccessedAt ?? summary.createdAt;

    return MemoryUnit(
      id: _buildUnitId([summary.id]),
      summary: summary.content.trim().isEmpty
          ? summary.title
          : summary.content.trim(),
      topic: topic,
      keywords: SummaryTextUtils.sanitizeTags([
        ...summary.tags,
        ...profile.tags,
        ...profile.keywords,
        if (topic.isNotEmpty) topic,
      ],
          maxTags: _policy.maxKeywordsPerRecord,
          fallbackTitle: topic.isEmpty ? summary.title : topic),
      importance: summary.importance,
      sourceIds: [summary.id],
      createdAt: summary.createdAt,
      updatedAt: updatedAt,
      confidence: max(0.45, profile.confidence),
    );
  }

  StatePatch? _deriveStatePatch(MemoryUnit unit) {
    final profile = _slmService.describeTextSemantics(
      title: unit.topic,
      content: unit.summary,
      tags: unit.keywords,
    );
    final normalized =
        _normalize('${unit.topic} ${unit.summary} ${unit.keywords.join(' ')}');
    String namespace = '';

    if (_containsAny(normalized, _preferenceSignals)) {
      namespace = 'user_preference_state';
    } else if (_containsAny(normalized, _taskSignals)) {
      namespace = 'task_state';
    } else if (_containsAny(normalized, _projectSignals)) {
      namespace = 'project_state';
    } else if (profile.semanticKey.isNotEmpty) {
      namespace = 'topic_state';
    } else {
      return null;
    }

    final key = switch (namespace) {
      'user_preference_state' => _normalizeKey(profile.facetKey.isNotEmpty
          ? profile.facetKey
          : 'global_preferences'),
      'task_state' => _normalizeKey(
          profile.displayTitle.isNotEmpty ? profile.displayTitle : unit.topic,
        ),
      'project_state' => _normalizeKey(
          profile.domainKey.isNotEmpty
              ? profile.domainKey
              : profile.displayTopic.isNotEmpty
                  ? profile.displayTopic
                  : unit.topic,
        ),
      _ => _normalizeKey(
          profile.semanticKey.isNotEmpty ? profile.semanticKey : unit.topic,
        ),
    };

    if (key.isEmpty) {
      return null;
    }

    return StatePatch(
      namespace: namespace,
      key: key,
      summary: unit.summary,
      topic: unit.topic,
      keywords: unit.keywords.take(_policy.maxKeywordsPerRecord).toList(),
      importance: unit.importance,
      confidence: profile.confidence,
    );
  }

  StatePatch _mergeStatePatches(List<StatePatch> patches) {
    final sorted = List<StatePatch>.from(patches)
      ..sort((a, b) {
        final importanceDiff = b.importance.compareTo(a.importance);
        if (importanceDiff != 0) {
          return importanceDiff;
        }
        return b.confidence.compareTo(a.confidence);
      });
    final primary = sorted.first;
    final keywords = SummaryTextUtils.sanitizeTags(
      sorted.expand((patch) => patch.keywords).toList(),
      maxTags: _policy.maxKeywordsPerRecord,
      fallbackTitle: primary.topic,
    );
    return StatePatch(
      namespace: primary.namespace,
      key: primary.key,
      summary: primary.summary,
      topic: primary.topic,
      keywords: keywords,
      importance: sorted.fold<double>(
        0.0,
        (sum, patch) => max(sum, patch.importance),
      ),
      confidence: sorted.fold<double>(
        0.0,
        (sum, patch) => max(sum, patch.confidence),
      ),
    );
  }

  void _scheduleBackgroundDrain() {
    _scheduledDrain ??= Future<void>.microtask(() async {
      try {
        await compact();
      } catch (error, stackTrace) {
        debugPrint('⚠️ [MemoryRuntime] Background drain failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      } finally {
        _scheduledDrain = null;
      }
    });
  }

  /// 计算合并优先级分数
  double _calculateMergePriority(MemoryUnit existing, MemoryUnit candidate) {
    double score = 0.0;

    // topic 完全相同优先级最高
    if (_normalize(existing.topic) == _normalize(candidate.topic)) {
      score += 1.0;
    }

    // 时间接近的优先级高
    final timeDiff =
        existing.createdAt.difference(candidate.createdAt).abs().inDays;
    if (timeDiff <= 1) {
      score += 0.5;
    } else if (timeDiff <= 7) {
      score += 0.3;
    } else if (timeDiff <= 30) {
      score += 0.1;
    }

    // 关键词重叠度
    final commonKeywords =
        existing.keywords.toSet().intersection(candidate.keywords.toSet());
    final overlapRatio = commonKeywords.length /
        max(existing.keywords.length, candidate.keywords.length);
    score += overlapRatio * 0.5;

    return score;
  }

  static const Set<String> _taskSignals = <String>{
    'task',
    'todo',
    'follow-up',
    'follow up',
    'next step',
    '待办',
    '任务',
    '跟进',
    '修复',
    '处理',
    'checklist',
    'issue',
  };
  static const Set<String> _projectSignals = <String>{
    'project',
    'launch',
    'release',
    'rollout',
    'milestone',
    'roadmap',
    '项目',
    '发布',
    '上线',
    '计划',
    '版本',
  };
  static const Set<String> _preferenceSignals = <String>{
    'prefer',
    'preference',
    'like',
    'dislike',
    '偏好',
    '喜欢',
    '习惯',
  };
}

class RuleBasedMemoryCompressor implements MemoryCompressor {
  RuleBasedMemoryCompressor({
    required MemorySLMService slmService,
    required MemoryPolicyConfig policyConfig,
    required MemoryPolicy policy,
  })  : _slmService = slmService,
        _policyConfig = policyConfig,
        _policy = policy;

  final MemorySLMService _slmService;
  final MemoryPolicyConfig _policyConfig;
  final MemoryPolicy _policy;

  static const Set<String> _taskSignals = <String>{
    'task',
    'todo',
    'follow-up',
    'follow up',
    'next step',
    '待办',
    '任务',
    '跟进',
    '修复',
    '处理',
    'checklist',
    'issue',
  };
  static const Set<String> _projectSignals = <String>{
    'project',
    'launch',
    'release',
    'rollout',
    'milestone',
    'roadmap',
    '项目',
    '发布',
    '上线',
    '计划',
    '版本',
  };
  static const Set<String> _preferenceSignals = <String>{
    'prefer',
    'preference',
    'like',
    'dislike',
    '偏好',
    '喜欢',
    '习惯',
  };

  @override
  Future<SessionCompactionResult> compressSessions(
    List<SummaryEntity> sessions,
  ) async {
    if (sessions.isEmpty) {
      return const SessionCompactionResult();
    }

    final batches = await _buildSessionBatches(sessions);
    final updatedSessions = _syncSessionProtection(sessions, batches);
    final mergedFacts = <SummaryEntity>[];
    final consumedSessionIds = <String>{};
    final archiveRecords = <ArchiveRecord>[];
    final stateUpdates = <StateRecord>[];

    for (final batch in batches) {
      if (!_isEligibleForMerge(batch)) {
        continue;
      }

      final mergeResponse = await _slmService.mergeSessions(batch.sessions);
      final mergedContent = mergeResponse.data.content.trim();
      if (!mergeResponse.success || mergedContent.isEmpty) {
        continue;
      }

      final fact = _buildFactFromBatch(batch, mergeResponse.data);
      mergedFacts.add(fact);
      consumedSessionIds.addAll(batch.sessions.map((item) => item.id));
      archiveRecords.add(
        ArchiveRecord(
          id: 'archive_${fact.id}',
          sourceType: 'session_batch',
          payload: <String, dynamic>{
            'sourceSessionIds': batch.sessions.map((item) => item.id).toList(),
            'mergedFactId': fact.id,
            'topic': batch.topic,
          },
          createdAt: DateTime.now(),
          retentionTag: 'session_merge',
        ),
      );

      // 新增：从合并后的 Fact 生成状态记录
      final stateRecord = await compressToState(fact);
      if (stateRecord != null) {
        stateUpdates.add(stateRecord);
      }
    }

    return SessionCompactionResult(
      mergedFacts: mergedFacts,
      updatedSessions: updatedSessions,
      consumedSessionIds: consumedSessionIds,
      archiveRecords: archiveRecords,
      stateUpdates: stateUpdates,
    );
  }

  /// 从 SummaryEntity 压缩生成 StateRecord
  ///
  /// 实现 session → summary → state 的三层压缩管道
  Future<StateRecord?> compressToState(SummaryEntity summary) async {
    final profile = _slmService.describeSummarySemantics(summary);
    final topic = profile.displayTopic.isNotEmpty
        ? profile.displayTopic
        : summary.topic?.trim() ?? '';
    final keywords = <String>{
      ...summary.tags,
      ...profile.tags,
      ...profile.keywords,
      if (topic.isNotEmpty) topic,
    }.take(_policy.maxKeywordsPerRecord).toList();

    final unit = MemoryUnit(
      id: 'temp_${summary.id}',
      summary: summary.content.trim().isEmpty
          ? summary.title
          : summary.content.trim(),
      topic: topic,
      keywords: keywords,
      importance: summary.importance,
      sourceIds: [summary.id],
      createdAt: summary.createdAt,
      updatedAt: summary.updatedAt ?? DateTime.now(),
      confidence: max(0.45, profile.confidence),
    );

    final patch = _deriveStatePatchWithProfile(unit, profile);

    if (patch == null || patch.confidence < _policy.stateConfidenceThreshold) {
      return null;
    }

    // 构建新的状态记录，版本号为 1
    return StateRecord(
      namespace: patch.namespace,
      key: patch.key,
      summary: patch.summary,
      topic: patch.topic,
      keywords: patch.keywords,
      importance: patch.importance,
      version: 1,
      updatedAt: DateTime.now(),
    );
  }

  /// 使用已有的语义画像推导状态补丁
  /// 避免重复调用 describeTextSemantics
  StatePatch? _deriveStatePatchWithProfile(
    MemoryUnit unit,
    RuleSemanticProfile profile,
  ) {
    final normalized =
        _normalize('${unit.topic} ${unit.summary} ${unit.keywords.join(' ')}');
    String namespace = '';

    if (_containsAny(normalized, _preferenceSignals)) {
      namespace = 'user_preference_state';
    } else if (_containsAny(normalized, _taskSignals)) {
      namespace = 'task_state';
    } else if (_containsAny(normalized, _projectSignals)) {
      namespace = 'project_state';
    } else if (profile.semanticKey.isNotEmpty) {
      namespace = 'topic_state';
    } else {
      return null;
    }

    final key = switch (namespace) {
      'user_preference_state' => _normalizeKey(profile.facetKey.isNotEmpty
          ? profile.facetKey
          : 'global_preferences'),
      'task_state' => _normalizeKey(
          profile.displayTitle.isNotEmpty ? profile.displayTitle : unit.topic,
        ),
      'project_state' => _normalizeKey(
          profile.domainKey.isNotEmpty
              ? profile.domainKey
              : profile.displayTopic.isNotEmpty
                  ? profile.displayTopic
                  : unit.topic,
        ),
      _ => _normalizeKey(
          profile.semanticKey.isNotEmpty ? profile.semanticKey : unit.topic,
        ),
    };

    if (key.isEmpty) {
      return null;
    }

    return StatePatch(
      namespace: namespace,
      key: key,
      summary: unit.summary,
      topic: unit.topic,
      keywords: unit.keywords.take(_policy.maxKeywordsPerRecord).toList(),
      importance: unit.importance,
      confidence: profile.confidence,
    );
  }

  Future<List<_SessionBatch>> _buildSessionBatches(
    List<SummaryEntity> sessions,
  ) async {
    final batchPolicy = _policyConfig.sessionBatching;
    final sortedSessions = List<SummaryEntity>.from(sessions)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final batches = <_SessionBatch>[];

    for (final rawSession in sortedSessions) {
      final session = await _ensureTopic(rawSession);
      final sessionProfile = _slmService.describeSummarySemantics(session);
      var assigned = false;

      for (final batch in batches) {
        final anchor = batch.sessions.last;
        final semanticSimilarity =
            _slmService.calculateSemanticProfileSimilarity(
          batch.profile,
          sessionProfile,
        );
        final ruleScore = _calculateBatchRuleScore(
          batch,
          session,
          batch.profile,
          sessionProfile,
          semanticSimilarity,
        );
        final topicMatches = _slmService.hasStableSemanticAlignment(
          batch.profile,
          sessionProfile,
          minTagOverlap: 1,
        );
        final hasSharedContext = _hasSharedBatchingContext(anchor, session);
        final canBypassRuleGate = topicMatches && hasSharedContext;
        if (ruleScore < batchPolicy.minimumRuleScoreForSemanticCheck &&
            !canBypassRuleGate) {
          continue;
        }

        final semanticScore = topicMatches ? 1.0 : 0.0;
        final canUseTopicShortcut = canBypassRuleGate ||
            (topicMatches &&
                ruleScore >= max(0.6, batchPolicy.topicMatchScoreFloor - 0.25));
        final combinedScore = canUseTopicShortcut
            ? max(batchPolicy.topicMatchScoreFloor, ruleScore)
            : (ruleScore * batchPolicy.ruleWeight) +
                (semanticScore * batchPolicy.semanticWeight);

        if (combinedScore >= batchPolicy.combinedScoreThreshold) {
          batch.sessions.add(session);
          batch.sessionProfiles.add(sessionProfile);
          batch.matchScores.add(combinedScore);
          batch.profile = _slmService.describeBatchSemantics(batch.sessions);
          assigned = true;
          break;
        }
      }

      if (!assigned) {
        batches.add(
          _SessionBatch(
            profile: sessionProfile,
            sessions: <SummaryEntity>[session],
            sessionProfiles: <RuleSemanticProfile>[sessionProfile],
            matchScores: <double>[],
          ),
        );
      }
    }

    return batches;
  }

  double _calculateBatchRuleScore(
    _SessionBatch batch,
    SummaryEntity session,
    RuleSemanticProfile batchProfile,
    RuleSemanticProfile sessionProfile,
    double semanticSimilarity,
  ) {
    final batchPolicy = _policyConfig.sessionBatching;
    double score = 0.0;

    final titleA = _normalizeTitle(batchProfile.displayTitle);
    final titleB = _normalizeTitle(sessionProfile.displayTitle);
    if (titleA.isNotEmpty && titleA == titleB) {
      score += batchPolicy.exactTitleMatchWeight;
    } else if (titleA.isNotEmpty &&
        titleB.isNotEmpty &&
        (titleA.contains(titleB) || titleB.contains(titleA))) {
      score += batchPolicy.partialTitleMatchWeight;
    }

    score += semanticSimilarity * batchPolicy.semanticSimilarityWeight;

    if (batchProfile.domainKey.isNotEmpty &&
        batchProfile.domainKey == sessionProfile.domainKey) {
      score += 0.12;
    }

    if (batchProfile.facetKey.isNotEmpty &&
        batchProfile.facetKey == sessionProfile.facetKey) {
      score += 0.12;
    }

    final batchTags = batch.sessions.expand((item) => item.tags).toSet();
    if (batchTags.isNotEmpty && session.tags.isNotEmpty) {
      final overlap = batchTags.intersection(session.tags.toSet()).length;
      final maxSize = max(batchTags.length, session.tags.length);
      score += (overlap / max(1, maxSize)) * batchPolicy.tagOverlapWeight;
    }

    if (batch.sessions.any(
      (item) => _sourceFamily(item.source) == _sourceFamily(session.source),
    )) {
      score += batchPolicy.sameSourceWeight;
    }

    final anchor = batch.sessions.last;
    final timeDiff = anchor.createdAt.difference(session.createdAt).abs();
    if (timeDiff <= _policyConfig.timeThresholds.shortTerm) {
      score += batchPolicy.shortTermTimeWeight;
    } else if (timeDiff <= _policyConfig.timeThresholds.mediumTerm) {
      score += batchPolicy.mediumTermTimeWeight;
    }

    return score.clamp(0.0, 1.0);
  }

  Future<SummaryEntity> _ensureTopic(SummaryEntity session) async {
    final existingTopic = session.topic?.trim() ?? '';
    final topicResponse = await _slmService.extractTopic(
      session.title,
      session.content,
    );
    final refreshedTopic = topicResponse.data.trim();
    if (!_shouldRefreshSessionTopic(existingTopic, refreshedTopic)) {
      return session;
    }
    return session.copyWith(topic: refreshedTopic);
  }

  bool _hasSharedBatchingContext(SummaryEntity a, SummaryEntity b) {
    if (_sourceFamily(a.source) == _sourceFamily(b.source)) {
      return true;
    }
    if (a.tags.toSet().intersection(b.tags.toSet()).isNotEmpty) {
      return true;
    }
    return a.createdAt.difference(b.createdAt).abs() <=
        _policyConfig.timeThresholds.mediumTerm;
  }

  bool _isCanonicalSessionTopic(String topic) {
    return switch (topic) {
      'rag' || 'llm' || 'slm' || 'ocr' => true,
      _ => false,
    };
  }

  bool _isEligibleForMerge(_SessionBatch batch) {
    final sessions = batch.sessions;
    final hasContent =
        sessions.any((session) => session.content.trim().isNotEmpty);
    if (!hasContent) {
      return false;
    }

    if (sessions.length >=
        _policyConfig.sessionBatching.minimumMergeBatchSize) {
      return true;
    }

    return _isHighConfidencePair(batch);
  }

  bool _isHighConfidencePair(_SessionBatch batch) {
    if (batch.sessions.length != 2 ||
        batch.matchScores.isEmpty ||
        !batch.profile.hasDomain) {
      return false;
    }

    final distinctFacetKeys = batch.sessionProfiles
        .map((profile) => profile.facetKey)
        .where((key) => key.isNotEmpty)
        .toSet();
    if (distinctFacetKeys.length != 1) {
      return false;
    }

    final coherenceScore = batch.matchScores.reduce(min);
    return coherenceScore >= 0.88 && batch.profile.confidence >= 0.65;
  }

  bool _isStableComparableTopic(String topic) {
    return topic.isNotEmpty && !TopicPlaceholderUtils.isPlaceholderTopic(topic);
  }

  List<SummaryEntity> _syncSessionProtection(
    List<SummaryEntity> originalSessions,
    List<_SessionBatch> batches,
  ) {
    final now = DateTime.now();
    final candidateIds = <String, _SessionBatch>{};
    for (final batch in batches.where((batch) => batch.sessions.length >= 2)) {
      for (final session in batch.sessions) {
        candidateIds[session.id] = batch;
      }
    }

    final updates = <SummaryEntity>[];
    for (final session in originalSessions) {
      final batch = candidateIds[session.id];
      final normalized = batch?.sessions.firstWhere(
            (candidate) => candidate.id == session.id,
            orElse: () => session,
          ) ??
          session;
      final nextTopic = batch?.topic ?? normalized.topic ?? session.topic;
      final nextProtectedUntil = batch == null
          ? null
          : now.add(_policyConfig.candidateProtectionWindow);
      final hasProtectionChanged = batch == null
          ? session.protectedUntil != null
          : session.protectedUntil == null ||
              session.protectedUntil!.isBefore(now) ||
              session.protectedUntil!
                      .difference(nextProtectedUntil!)
                      .inMinutes
                      .abs() >
                  1;
      final hasTopicChanged = (nextTopic ?? '') != (session.topic ?? '');

      if (!hasProtectionChanged && !hasTopicChanged) {
        continue;
      }

      updates.add(
        session.copyWith(
          topic: nextTopic,
          clearProtectedUntil: batch == null,
          protectedUntil: batch == null ? null : nextProtectedUntil,
        ),
      );
    }
    return updates;
  }

  bool _shouldRefreshSessionTopic(String existingTopic, String refreshedTopic) {
    final trimmedExisting = existingTopic.trim();
    final trimmedRefreshed = refreshedTopic.trim();
    if (trimmedRefreshed.isEmpty) {
      return false;
    }
    if (trimmedExisting.isEmpty) {
      return true;
    }

    final normalizedExisting = _normalizeTitle(trimmedExisting);
    final normalizedRefreshed = _normalizeTitle(trimmedRefreshed);
    if (normalizedExisting == normalizedRefreshed) {
      return false;
    }

    if (_isCanonicalSessionTopic(normalizedRefreshed)) {
      return true;
    }

    return !_isStableComparableTopic(normalizedExisting) &&
        _isStableComparableTopic(normalizedRefreshed);
  }

  /// 压缩合并后的内容
  String _compressSummary(List<String> parts) {
    // 检查 SLM 是否已初始化（可用）
    final slmAvailable = _slmService.isInitialized;

    if (slmAvailable) {
      // SLM 路径：使用语义分析
      return _compressSummaryWithSLM(parts);
    } else {
      // 规则路径：基于结构化合并
      return _compressSummaryWithRules(parts);
    }
  }

  /// 使用 SLM 进行智能压缩
  String _compressSummaryWithSLM(List<String> parts) {
    // 1. 先尝试直接拼接，如果不超过限制就直接返回
    final directJoin = parts.where((p) => p.trim().isNotEmpty).join('\n\n');

    // 合并时使用合理的字符限制（原始限制的 2 倍，最少 400 字符）
    final mergeCharLimit = max(
      _policy.maxCompressedSummaryChars * 2,
      400,
    );

    if (directJoin.length <= mergeCharLimit) {
      return directJoin;
    }

    // 2. SLM 辅助路径：使用语义分析增强压缩效果
    debugPrint(
        '🔍 [MemoryRuntime] Using SLM-assisted compression for ${parts.length} parts (${directJoin.length} chars)');

    // 3. 利用 SLM 提取的语义信息指导压缩
    final combinedText = parts.join(' ');
    final semanticProfile = _slmService.describeTextSemantics(
      title: 'Memory Merge',
      content: combinedText,
      tags: [],
    );

    // 4. 使用语义增强的规则引擎进行压缩
    return _compressSummaryWithRules(parts, semanticProfile: semanticProfile);
  }

  /// 使用规则进行结构化合并
  String _compressSummaryWithRules(
    List<String> parts, {
    RuleSemanticProfile? semanticProfile,
  }) {
    // 1. 将内容拆分成句子
    final sentences = <String>[];
    for (final part in parts) {
      final normalizedPart = part.trim();
      if (normalizedPart.isEmpty) continue;

      // 按多种标点符号分割句子
      final splitSentences = normalizedPart.split(RegExp(r'[。！？.!?]'));
      for (final sentence in splitSentences) {
        final clean = sentence.trim();
        if (clean.isNotEmpty && clean.length > 5) {
          sentences.add(clean);
        }
      }
    }

    // 2. 归一化并去重
    final seenNormalized = <String>{};
    final uniqueSentences = <String>[];
    for (final sentence in sentences) {
      final normalized = _normalize(sentence);
      if (!seenNormalized.contains(normalized)) {
        seenNormalized.add(normalized);
        uniqueSentences.add(sentence);
      }
    }

    // 3. 去除相似的行
    final filteredSentences = _removeSimilarLines(uniqueSentences);

    // 4. 移除信号较低的行
    final highSignalSentences = _filterLowSignalLines(filteredSentences);

    // 5. 基于语义画像和重要性评分选择前 N 条要点
    final topSentences = _selectTopPoints(
      highSignalSentences,
      min: 5,
      max: 10,
      semanticProfile: semanticProfile,
    );

    // 6. 输出为结构化项目符号
    return _formatAsBulletPoints(topSentences);
  }

  /// 去除相似的行
  List<String> _removeSimilarLines(List<String> lines) {
    if (lines.length <= 1) return lines;

    final result = <String>[];
    final normalizedLines = lines.map((l) => _normalize(l)).toList();
    final used = List<bool>.filled(lines.length, false);

    for (int i = 0; i < lines.length; i++) {
      if (used[i]) continue;

      result.add(lines[i]);

      // 标记与当前行相似的所有行为已使用
      for (int j = i + 1; j < lines.length; j++) {
        if (!used[j] &&
            _areLinesSimilar(normalizedLines[i], normalizedLines[j])) {
          used[j] = true;
        }
      }
    }

    return result;
  }

  /// 判断两行是否相似
  bool _areLinesSimilar(String normalizedA, String normalizedB) {
    final wordsA = normalizedA.split(RegExp(r'\s+')).toSet();
    final wordsB = normalizedB.split(RegExp(r'\s+')).toSet();

    if (wordsA.isEmpty || wordsB.isEmpty) return false;

    final intersection = wordsA.intersection(wordsB);
    final union = wordsA.union(wordsB);

    return intersection.length / union.length >= 0.5;
  }

  /// 过滤低信号行
  List<String> _filterLowSignalLines(List<String> lines) {
    final lowSignalPatterns = [
      RegExp(r'^这个.*'),
      RegExp(r'^那个.*'),
      RegExp(r'^一些.*'),
      RegExp(r'^可能.*'),
      RegExp(r'^也许.*'),
      RegExp(r'^好像.*'),
      RegExp(r'^似乎.*'),
      RegExp(r'^一般来说.*'),
      RegExp(r'^通常情况下.*'),
      RegExp(r'^总的来说.*'),
      RegExp(r'^总之.*'),
      RegExp(r'^简单来说.*'),
      RegExp(r'^基本上.*'),
      RegExp(r'^大概.*'),
      RegExp(r'^大约.*'),
    ];

    return lines.where((line) {
      final normalized = _normalize(line);
      return !lowSignalPatterns.any((pattern) => pattern.hasMatch(normalized));
    }).toList();
  }

  /// 选择前 N 条要点
  List<String> _selectTopPoints(
    List<String> points, {
    required int min,
    required int max,
    RuleSemanticProfile? semanticProfile,
  }) {
    if (points.isEmpty) return [];

    final scored = points.map((point) {
      double score = 0;

      final length = point.length;
      if (length >= 20 && length <= 100) {
        score += 1.0;
      } else if (length > 100) {
        score += 0.5;
      } else if (length >= 10) {
        score += 0.3;
      }

      if (RegExp(r'\d').hasMatch(point)) {
        score += 0.5;
      }

      final importantKeywords = [
        '核心',
        '关键',
        '重要',
        '必须',
        '应该',
        '建议',
        '主要',
        '重点'
      ];
      if (importantKeywords.any((kw) => point.contains(kw))) {
        score += 0.3;
      }

      final actionVerbs = ['实现', '完成', '创建', '建立', '设置', '配置', '优化', '改进'];
      if (actionVerbs.any((verb) => point.startsWith(verb))) {
        score += 0.2;
      }

      if (semanticProfile != null) {
        final topicKeywords = [
          if (semanticProfile.displayTopic.isNotEmpty)
            semanticProfile.displayTopic,
          ...semanticProfile.keywords,
          ...semanticProfile.tags,
        ];
        if (topicKeywords.any(
            (keyword) => point.toLowerCase().contains(keyword.toLowerCase()))) {
          score += 0.4;
        }
      }

      return MapEntry(point, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    final takeCount = scored.length.clamp(min, max);
    return scored.take(takeCount).map((e) => e.key).toList();
  }

  /// 格式化为项目符号
  String _formatAsBulletPoints(List<String> points) {
    if (points.isEmpty) return '';
    return points.map((point) => '• $point').join('\n');
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

    // 对 SLM 返回的合并内容进行压缩，避免保留全文
    final compressedContent = _compressSummary(<String>[mergeResult.content]);

    return SummaryEntity.create(
      title: mergeResult.title,
      content: compressedContent,
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

  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\u4E00-\u9FFF ]'), '')
        .trim();
  }

  String _sourceFamily(String source) {
    final parts = source.split('_');
    return parts.isEmpty ? source : parts.first;
  }

  /// 标准化文本用于模式匹配
  String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 检查文本是否包含任意关键词
  bool _containsAny(String normalized, Set<String> signals) {
    return signals.any((signal) => normalized.contains(signal));
  }

  /// 标准化键名
  String _normalizeKey(String key) {
    return key
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\u4E00-\u9FFF]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .substring(0, min(key.length, 64));
  }
}

class RuleBasedMemoryMerger implements MemoryMerger {
  RuleBasedMemoryMerger({
    required MemorySLMService slmService,
    required MemoryPolicy policy,
  })  : _slmService = slmService,
        _policy = policy;

  final MemorySLMService _slmService;
  final MemoryPolicy _policy;

  @override
  Future<MemoryUnit> mergeUnits(
    MemoryUnit left,
    MemoryUnit right, {
    MemoryMergeStrategy strategy = MemoryMergeStrategy.smartMerge,
  }) async {
    // 根据策略选择 summary 内容
    final String summaryContent;
    switch (strategy) {
      case MemoryMergeStrategy.keepOld:
        // 保留旧版本（左边）的内容，不压缩
        summaryContent = left.summary;
        break;
      case MemoryMergeStrategy.keepNew:
        // 保留新版本（右边）的内容，不压缩
        summaryContent = right.summary;
        break;
      case MemoryMergeStrategy.smartMerge:
        // 智能合并：执行压缩逻辑
        summaryContent =
            _compressSummary(<String>[left.summary, right.summary]);
        break;
    }

    // 1. 先调用 SLM 获取语义画像（用于 topic 和 keywords）
    final combinedProfile = _slmService.describeTextSemantics(
      title: '${left.topic}\n${right.topic}',
      content: summaryContent,
      tags: <String>[], // ← 不直接传入原始 tags，避免污染
    );

    // 2. 确定 topic
    final topic = _stableTopicFromParts(
      preferredTopic: combinedProfile.displayTopic,
      fallbackTopic: left.topic.isNotEmpty ? left.topic : right.topic,
      profile: combinedProfile,
      content: summaryContent,
    );

    // 3. 智能合并 keywords
    final keywords = _mergeKeywordsIntelligently(
      leftKeywords: left.keywords,
      rightKeywords: right.keywords,
      slmKeywords: combinedProfile.keywords,
      slmTags: combinedProfile.tags,
      topic: topic,
      maxKeywords: _policy.maxKeywordsPerRecord,
    );

    final sourceIds = <String>{...left.sourceIds, ...right.sourceIds}.toList()
      ..sort();
    return MemoryUnit(
      id: _buildUnitId(sourceIds),
      summary: summaryContent,
      topic: topic,
      keywords: keywords,
      importance: _calculateMergedImportance(left, right),
      sourceIds: sourceIds,
      createdAt: left.createdAt.isBefore(right.createdAt)
          ? left.createdAt
          : right.createdAt,
      updatedAt: left.updatedAt.isAfter(right.updatedAt)
          ? left.updatedAt
          : right.updatedAt,
      confidence: max(left.confidence, right.confidence),
    );
  }

  @override
  bool shouldMerge(MemoryUnit left, MemoryUnit right) {
    // 1. 首先检查 topic 是否完全相同（快速路径）
    if (left.topic.isNotEmpty &&
        right.topic.isNotEmpty &&
        _normalize(left.topic) == _normalize(right.topic)) {
      return true;
    }

    // 2. 检查时间接近性（7 天内的记录更容易合并）
    final timeDiff = left.createdAt.difference(right.createdAt).abs().inDays;
    final timeBonus = timeDiff <= 7 ? 0.15 : (timeDiff <= 30 ? 0.05 : 0.0);

    // 3. 检查关键词重叠度
    final commonKeywords =
        left.keywords.toSet().intersection(right.keywords.toSet());
    final keywordOverlapRatio = commonKeywords.length /
        max(left.keywords.length, right.keywords.length);
    if (keywordOverlapRatio >= 0.5) {
      return true; // 关键词重叠度超过 50% 直接合并
    }

    // 4. SLM 语义分析（如果有）
    final leftProfile = _slmService.describeTextSemantics(
      title: left.topic,
      content: left.summary,
      tags: left.keywords,
    );
    final rightProfile = _slmService.describeTextSemantics(
      title: right.topic,
      content: right.summary,
      tags: right.keywords,
    );

    // 5. 检查语义对齐
    if (_slmService.hasStableSemanticAlignment(leftProfile, rightProfile)) {
      return true;
    }

    // 6. 综合评分
    final profileSimilarity = _slmService.calculateSemanticProfileSimilarity(
      leftProfile,
      rightProfile,
    );
    final textSimilarity = SimilarityUtils.calculateMemorySimilarity(
      left.topic,
      left.summary,
      right.topic,
      right.summary,
    );

    // 应用时间奖励
    final adjustedThreshold = _policy.memoryUnitMergeThreshold - timeBonus;

    return max(profileSimilarity, textSimilarity) >= adjustedThreshold;
  }

  @override
  String compressSummaryForMerge(String content1, String content2) {
    // 直接调用内部的压缩方法
    return _compressSummary(<String>[content1, content2]);
  }

  /// 智能压缩摘要
  ///
  /// 根据 SLM 可用性选择策略：
  /// - SLM 开启：使用语义分析进行智能合并
  /// - SLM 关闭：使用基于规则的结构化合并（拆分→归一化→去重→去噪→保留要点）
  String _compressSummary(List<String> parts) {
    // 检查 SLM 是否已初始化（可用）
    final slmAvailable = _slmService.isInitialized;

    if (slmAvailable) {
      // SLM 路径：使用语义分析
      return _compressSummaryWithSLM(parts);
    } else {
      // 规则路径：基于结构化合并
      return _compressSummaryWithRules(parts);
    }
  }

  /// 使用 SLM 进行智能压缩
  ///
  /// 核心思路：利用 SLM 语义分析结果指导规则压缩
  /// 1. 先尝试直接拼接，如果不超过限制就直接返回
  /// 2. 超过限制时，使用 SLM 语义信息指导压缩优先级
  String _compressSummaryWithSLM(List<String> parts) {
    // 1. 先尝试直接拼接，如果不超过限制就直接返回
    final directJoin = parts.where((p) => p.trim().isNotEmpty).join('\n\n');

    // 合并时使用合理的字符限制（原始限制的 2 倍，最少 400 字符）
    final mergeCharLimit = max(
      _policy.maxCompressedSummaryChars * 2,
      400,
    );

    if (directJoin.length <= mergeCharLimit) {
      return directJoin;
    }

    // 2. SLM 辅助路径：使用语义分析增强压缩效果
    debugPrint(
        '🔍 [MemoryRuntime] Using SLM-assisted compression for ${parts.length} parts (${directJoin.length} chars)');

    // 3. 利用 SLM 提取的语义信息指导压缩
    // 将多个部分合并后提取语义画像，用于后续的句子评分
    final combinedText = parts.join(' ');
    final semanticProfile = _slmService.describeTextSemantics(
      title: 'Memory Merge',
      content: combinedText,
      tags: [],
    );

    // 4. 使用语义增强的规则引擎进行压缩
    return _compressSummaryWithRules(parts, semanticProfile: semanticProfile);
  }

  /// 使用规则进行结构化合并
  ///
  /// 遵循原则：压缩 = 结构 + 去重（不是重写）
  ///
  /// 参数:
  /// - parts: 待合并的文本片段列表
  /// - semanticProfile: 可选的语义画像，用于增强句子评分
  String _compressSummaryWithRules(
    List<String> parts, {
    RuleSemanticProfile? semanticProfile,
  }) {
    // 1. 将内容拆分成句子
    final sentences = <String>[];
    for (final part in parts) {
      final normalizedPart = part.trim();
      if (normalizedPart.isEmpty) continue;

      // 按多种标点符号分割句子
      final splitSentences = normalizedPart.split(RegExp(r'[。！？.!?]'));
      for (final sentence in splitSentences) {
        final clean = sentence.trim();
        if (clean.isNotEmpty && clean.length > 5) {
          // 过滤过短的句子
          sentences.add(clean);
        }
      }
    }

    // 2. 归一化（小写，修整）并去重
    final seenNormalized = <String>{};
    final uniqueSentences = <String>[];
    for (final sentence in sentences) {
      final normalized = _normalize(sentence);
      if (!seenNormalized.contains(normalized)) {
        seenNormalized.add(normalized);
        uniqueSentences.add(sentence);
      }
    }

    // 3. 去除相似的行（基于编辑距离或关键词重叠）
    final filteredSentences = _removeSimilarLines(uniqueSentences);

    // 4. 移除信号较低的行
    final highSignalSentences = _filterLowSignalLines(filteredSentences);

    // 5. 基于语义画像和重要性评分选择前 N 条要点
    final topSentences = _selectTopPoints(
      highSignalSentences,
      min: 5,
      max: 10,
      semanticProfile: semanticProfile,
    );

    // 6. 输出为结构化项目符号，而非段落
    return _formatAsBulletPoints(topSentences);
  }

  /// 去除相似的行
  List<String> _removeSimilarLines(List<String> lines) {
    if (lines.length <= 1) return lines;

    final result = <String>[];
    final normalizedLines = lines.map((l) => _normalize(l)).toList();
    final used = List<bool>.filled(lines.length, false);

    for (int i = 0; i < lines.length; i++) {
      if (used[i]) continue;

      result.add(lines[i]);

      // 标记与当前行相似的所有行为已使用
      for (int j = i + 1; j < lines.length; j++) {
        if (!used[j] &&
            _areLinesSimilar(normalizedLines[i], normalizedLines[j])) {
          used[j] = true;
        }
      }
    }

    return result;
  }

  /// 判断两行是否相似（基于关键词重叠度）
  bool _areLinesSimilar(String normalizedA, String normalizedB) {
    // 简单的相似度判断：共同的词占比
    final wordsA = normalizedA.split(RegExp(r'\s+')).toSet();
    final wordsB = normalizedB.split(RegExp(r'\s+')).toSet();

    if (wordsA.isEmpty || wordsB.isEmpty) return false;

    final intersection = wordsA.intersection(wordsB);
    final union = wordsA.union(wordsB);

    // Jaccard 相似度 >= 0.5 认为相似
    return intersection.length / union.length >= 0.5;
  }

  /// 过滤低信号行
  List<String> _filterLowSignalLines(List<String> lines) {
    // 低信号模式：模糊、空洞的表达
    final lowSignalPatterns = [
      RegExp(r'^这个.*'), // "这个..."
      RegExp(r'^那个.*'), // "那个..."
      RegExp(r'^一些.*'), // "一些..."
      RegExp(r'^可能.*'), // "可能..."
      RegExp(r'^也许.*'), // "也许..."
      RegExp(r'^好像.*'), // "好像..."
      RegExp(r'^似乎.*'), // "似乎..."
      RegExp(r'^一般来说.*'), // "一般来说..."
      RegExp(r'^通常情况下.*'), // "通常情况下..."
      RegExp(r'^总的来说.*'), // "总的来说..."
      RegExp(r'^总之.*'), // "总之..."
      RegExp(r'^简单来说.*'), // "简单来说..."
      RegExp(r'^基本上.*'), // "基本上..."
      RegExp(r'^大概.*'), // "大概..."
      RegExp(r'^大约.*'), // "大约..."
    ];

    return lines.where((line) {
      final normalized = _normalize(line);
      return !lowSignalPatterns.any((pattern) => pattern.hasMatch(normalized));
    }).toList();
  }

  /// 选择前 N 条要点
  ///
  /// 参数:
  /// - points: 候选要点列表
  /// - min: 最少保留数量
  /// - max: 最多保留数量
  /// - semanticProfile: 可选的语义画像，用于增强评分
  List<String> _selectTopPoints(
    List<String> points, {
    required int min,
    required int max,
    RuleSemanticProfile? semanticProfile,
  }) {
    if (points.isEmpty) return [];

    // 按信息量排序（长度 + 包含数字/关键词 + 语义相关性）
    final scored = points.map((point) {
      double score = 0;

      // 长度适中得分高（20-100 字）
      final length = point.length;
      if (length >= 20 && length <= 100) {
        score += 1.0;
      } else if (length > 100) {
        score += 0.5;
      } else if (length >= 10) {
        score += 0.3;
      }

      // 包含数字得分高（数据、版本等）
      if (RegExp(r'\d').hasMatch(point)) {
        score += 0.5;
      }

      // 包含关键词得分高
      final importantKeywords = [
        '核心',
        '关键',
        '重要',
        '必须',
        '应该',
        '建议',
        '主要',
        '重点'
      ];
      if (importantKeywords.any((kw) => point.contains(kw))) {
        score += 0.3;
      }

      // 以动词开头得分高
      final actionVerbs = ['实现', '完成', '创建', '建立', '设置', '配置', '优化', '改进'];
      if (actionVerbs.any((verb) => point.startsWith(verb))) {
        score += 0.2;
      }

      // 如果有语义画像，检查与主题的相關性
      if (semanticProfile != null) {
        // 包含主题关键词的句子得分更高
        final topicKeywords = [
          if (semanticProfile.displayTopic.isNotEmpty)
            semanticProfile.displayTopic,
          ...semanticProfile.keywords,
          ...semanticProfile.tags,
        ];

        final normalizedPoint = point.toLowerCase();
        for (final keyword in topicKeywords) {
          if (keyword.isNotEmpty &&
              normalizedPoint.contains(keyword.toLowerCase())) {
            score += 0.4;
            break;
          }
        }

        // 包含画像中的高权重关键词额外加分
        if (semanticProfile.facetKey.isNotEmpty &&
            point.contains(semanticProfile.facetKey)) {
          score += 0.3;
        }
      }

      return MapEntry(point, score);
    }).toList();

    // 按分数降序排序
    scored.sort((a, b) => b.value.compareTo(a.value));

    // 取前 max 个，至少保留 min 个
    final count = scored.length.clamp(min, max);
    return scored.take(count).map((e) => e.key).toList();
  }

  /// 格式化为结构化项目符号
  String _formatAsBulletPoints(List<String> points) {
    if (points.isEmpty) return '';

    // 每个要点一行，使用 • 符号
    return points.map((point) => '• $point').join('\n');
  }

  /// 计算合并后的重要性
  double _calculateMergedImportance(MemoryUnit left, MemoryUnit right) {
    // 1. 基础重要性（取最大值）
    final baseImportance = max(left.importance, right.importance);

    // 2. 访问频率奖励（基于 sourceIds 数量）
    final maxAccessCount = max(left.sourceIds.length, right.sourceIds.length);
    final accessBonus =
        min(0.2, maxAccessCount * 0.02); // 每个 source +0.02，最多 0.2

    // 3. 时效性奖励（最近的记录）
    final now = DateTime.now();
    final leftAge = now.difference(left.updatedAt).inDays;
    final rightAge = now.difference(right.updatedAt).inDays;
    final recencyBonus = max(
      0.1 * (1 - leftAge / 30), // 30 天内衰减
      0.1 * (1 - rightAge / 30),
    ).clamp(0.0, 0.1);

    // 4. 综合计算
    final mergedImportance = baseImportance + accessBonus + recencyBonus;

    return mergedImportance.clamp(0.0, 1.0);
  }

  /// 智能合并 keywords
  List<String> _mergeKeywordsIntelligently({
    required List<String> leftKeywords,
    required List<String> rightKeywords,
    required List<String> slmKeywords,
    required List<String> slmTags,
    required String topic,
    required int maxKeywords,
  }) {
    // 1. 过滤掉低质量的 tags（完整句子、片段词等）
    final filteredUserTags = <String>[];
    for (final tag in [...leftKeywords, ...rightKeywords]) {
      if (_isValidKeyword(tag)) {
        filteredUserTags.add(tag);
      }
    }

    // 2. 合并所有来源
    final allKeywords = <String>{
      ...filteredUserTags,
      ...slmKeywords,
      ...slmTags,
      if (topic.isNotEmpty) topic,
    };

    // 3. 去除语义重复（简化版：基于包含关系）
    final deduplicated = <String>{};
    final sortedKeywords = allKeywords.toList()
      ..sort((a, b) => a.length.compareTo(b.length)); // 短的在前

    for (final keyword in sortedKeywords) {
      final normalized = keyword.toLowerCase().trim();
      if (normalized.isEmpty) continue;

      // 检查是否已被更长的词包含
      final isContained = deduplicated.any(
        (existing) => existing.toLowerCase().contains(normalized),
      );

      if (!isContained) {
        deduplicated.add(keyword);
      }
    }

    // 4. 按重要性排序并截取
    final ranked = deduplicated.toList()
      ..sort((a, b) {
        // topic 优先级最高
        if (a == topic) return -1;
        if (b == topic) return 1;

        // SLM 生成的关键词优先
        final aIsSlm = slmKeywords.contains(a) || slmTags.contains(a);
        final bIsSlm = slmKeywords.contains(b) || slmTags.contains(b);
        if (aIsSlm && !bIsSlm) return -1;
        if (!aIsSlm && bIsSlm) return 1;

        // 否则按长度排序（适中的更好）
        final aScore = (a.length - 5).abs();
        final bScore = (b.length - 5).abs();
        return aScore.compareTo(bScore);
      });

    return ranked.take(maxKeywords).toList();
  }

  /// 判断是否是有效的关键词
  bool _isValidKeyword(String keyword) {
    final trimmed = keyword.trim();

    // 太短或太长都不是好关键词
    if (trimmed.length < 2 || trimmed.length > 30) {
      return false;
    }

    // 包含完整句子标点的不是关键词
    if (RegExp(r'[,.!?;:]').hasMatch(trimmed)) {
      return false;
    }

    // 以括号结尾的不是关键词
    if (trimmed.endsWith(')') || trimmed.endsWith('）')) {
      return false;
    }

    return true;
  }
}

class RuleBasedMemoryRetriever implements MemoryRetriever {
  RuleBasedMemoryRetriever({
    required MemorySidecarRepository sidecarRepository,
    required MemorySLMService slmService,
    required MemoryPolicy policy,
  })  : _sidecarRepository = sidecarRepository,
        _slmService = slmService,
        _policy = policy;

  final MemorySidecarRepository _sidecarRepository;
  final MemorySLMService _slmService;
  final MemoryPolicy _policy;

  @override
  Future<MemoryRetrievalResult> retrieve(MemoryRetrievalRequest request) async {
    final queryProfile = _slmService.describeTextSemantics(
      title: request.topic,
      content: request.query,
      tags: request.keywords,
    );
    final maxItems = request.maxItems.clamp(1, _policy.maxContextItems);
    final maxStateItems = request.maxStateItems.clamp(0, maxItems);

    final stateScores = _sidecarRepository
        .getAllStateRecords()
        .map((record) =>
            MapEntry(record, _scoreStateRecord(record, request, queryProfile)))
        .where((entry) => entry.value > 0.05)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final selectedStates = stateScores
        .take(maxStateItems)
        .map((entry) => entry.key)
        .toList(growable: false);

    final memoryScores = _sidecarRepository
        .getAllMemoryUnits()
        .where(
          (unit) => !selectedStates.any(
            (record) => _normalize(record.topic) == _normalize(unit.topic),
          ),
        )
        .map((unit) =>
            MapEntry(unit, _scoreMemoryUnit(unit, request, queryProfile)))
        .where((entry) => entry.value > 0.05)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final remainingSlots = max(0, maxItems - selectedStates.length);
    final selectedUnits = memoryScores
        .take(remainingSlots)
        .map((entry) => entry.key)
        .toList(growable: false);

    return MemoryRetrievalResult(
      states: selectedStates,
      memoryUnits: selectedUnits,
      queryProfile: queryProfile,
    );
  }

  double _scoreMemoryUnit(
    MemoryUnit unit,
    MemoryRetrievalRequest request,
    RuleSemanticProfile queryProfile,
  ) {
    final unitProfile = _slmService.describeTextSemantics(
      title: unit.topic,
      content: unit.summary,
      tags: unit.keywords,
    );
    final semanticScore = _slmService.calculateSemanticProfileSimilarity(
      queryProfile,
      unitProfile,
    );
    final keywordScore = SimilarityUtils.tokenOverlapCoefficient(
      request.keywords.join(' '),
      unit.keywords.join(' '),
    );
    final textScore = SimilarityUtils.calculateMemorySimilarity(
      request.topic,
      request.query,
      unit.topic,
      unit.summary,
    );
    final recencyScore = _recencyScore(unit.updatedAt);
    return (semanticScore * 0.35) +
        (keywordScore * 0.2) +
        (textScore * 0.15) +
        (unit.importance * 0.2) +
        (recencyScore * 0.1);
  }

  double _scoreStateRecord(
    StateRecord record,
    MemoryRetrievalRequest request,
    RuleSemanticProfile queryProfile,
  ) {
    final stateProfile = _slmService.describeTextSemantics(
      title: record.topic,
      content: record.summary,
      tags: record.keywords,
    );
    final semanticScore = _slmService.calculateSemanticProfileSimilarity(
      queryProfile,
      stateProfile,
    );
    final keywordScore = SimilarityUtils.tokenOverlapCoefficient(
      request.keywords.join(' '),
      record.keywords.join(' '),
    );
    final textScore = SimilarityUtils.calculateMemorySimilarity(
      request.topic,
      request.query,
      record.topic,
      record.summary,
    );
    final recencyScore = _recencyScore(record.updatedAt);
    return (semanticScore * 0.3) +
        (keywordScore * 0.2) +
        (textScore * 0.2) +
        (record.importance * 0.2) +
        (recencyScore * 0.1);
  }

  double _recencyScore(DateTime updatedAt) {
    final days = DateTime.now().difference(updatedAt).inDays;
    return max(0.1, 1.0 - (days / 30.0));
  }
}

class DefaultContextAssembler implements ContextAssembler {
  DefaultContextAssembler({
    required MemoryPolicy policy,
  }) : _policy = policy;

  final MemoryPolicy _policy;

  @override
  MemoryContextBundle assemble(MemoryRetrievalResult result) {
    final buffer = StringBuffer();
    if (result.states.isNotEmpty) {
      buffer.writeln('Current state:');
      for (final record in result.states.take(_policy.preferredStateItems)) {
        buffer.writeln(
          '- [${record.namespace}] ${record.topic.isEmpty ? record.key : record.topic}: ${record.summary}',
        );
      }
    }

    if (result.memoryUnits.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.writeln('Relevant memory:');
      for (final unit in result.memoryUnits.take(_policy.maxContextItems)) {
        buffer.writeln(
          '- ${unit.topic.isEmpty ? unit.summary : unit.topic}: ${unit.summary}',
        );
      }
    }

    return MemoryContextBundle(
      states: result.states,
      memoryUnits: result.memoryUnits,
      contextText: buffer.toString().trim(),
    );
  }
}

class _SessionBatch {
  _SessionBatch({
    required this.profile,
    required this.sessions,
    required this.sessionProfiles,
    required this.matchScores,
  });

  RuleSemanticProfile profile;
  final List<SummaryEntity> sessions;
  final List<RuleSemanticProfile> sessionProfiles;
  final List<double> matchScores;

  String get topic => profile.displayTopic;
}

String _buildUnitId(List<String> sourceIds) {
  final sorted = List<String>.from(sourceIds)..sort();
  final joined = sorted.join('|');
  final checksum = joined.codeUnits.fold<int>(
    0,
    (sum, value) => (sum * 31 + value) & 0x7fffffff,
  );
  return 'unit_$checksum';
}

bool _containsAny(String text, Set<String> signals) {
  for (final signal in signals) {
    if (text.contains(signal)) {
      return true;
    }
  }
  return false;
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _normalizeKey(String value) {
  return _normalize(value)
      .replaceAll(RegExp(r'[^a-z0-9\u4E00-\u9FFF]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

String _stableTopic(SummaryEntity summary, RuleSemanticProfile profile) {
  debugPrint('🔍 [MemoryRuntime] _stableTopic called');
  debugPrint('  - summary.topic: "${summary.topic}"');
  debugPrint('  - profile.displayTopic: "${profile.displayTopic}"');
  debugPrint('  - summary.title: "${summary.title}"');

  final result = _stableTopicFromParts(
    preferredTopic: summary.topic?.trim() ?? '',
    fallbackTopic: summary.title.trim(),
    profile: profile,
    content: summary.content,
  );

  debugPrint('  → Final topic: "$result"');
  return result;
}

String _stableTopicFromParts({
  required String preferredTopic,
  required String fallbackTopic,
  required RuleSemanticProfile profile,
  required String? content,
}) {
  final preferred = preferredTopic.trim();

  // 1. 优先使用显式指定的 topic
  if (preferred.isNotEmpty &&
      !TopicPlaceholderUtils.isPlaceholderTopic(preferred)) {
    return preferred;
  }

  // 2. 使用 SLM 语义分析结果
  if (profile.displayTopic.isNotEmpty &&
      !TopicPlaceholderUtils.isPlaceholderTopic(profile.displayTopic)) {
    return profile.displayTopic.trim();
  }

  // 3. 使用 title 兜底
  final fallback = fallbackTopic.trim();
  if (fallback.isNotEmpty && !SummaryTextUtils.isUnnamedTitleValue(fallback)) {
    return fallback;
  }

  // 4. 终极兜底：从 content 提取或返回默认值
  return _getDefaultTopic(content);
}

/// 根据语言返回默认主题（终极兜底）
String _getDefaultTopic(String? content) {
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
