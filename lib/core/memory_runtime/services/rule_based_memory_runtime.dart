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
    required MemoryPolicyConfig legacyPolicyConfig,
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
        _legacyPolicyConfig = legacyPolicyConfig,
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
  final MemoryPolicyConfig _legacyPolicyConfig;
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
        final nextFact = fact.shouldUpgradeToCoreWithPolicy(_legacyPolicyConfig)
            ? fact.copyWith(type: MemoryType.core)
            : fact;
        await _summaryRepository.addSummary(nextFact);
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

    final units = <MemoryUnit>[];
    for (final summary in sourceSummaries) {
      final candidate = _buildCandidateUnit(summary);
      var merged = false;
      for (var index = 0; index < units.length; index++) {
        final existing = units[index];
        if (!_merger.shouldMerge(existing, candidate)) {
          continue;
        }
        units[index] = await _merger.mergeUnits(existing, candidate);
        merged = true;
        break;
      }
      if (!merged) {
        units.add(candidate);
      }
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
  Future<MemoryUnit> mergeUnits(MemoryUnit left, MemoryUnit right) async {
    final combinedSummary =
        _compressSummary(<String>[left.summary, right.summary]);
    final combinedProfile = _slmService.describeTextSemantics(
      title: '${left.topic}\n${right.topic}',
      content: combinedSummary,
      tags: <String>[...left.keywords, ...right.keywords],
    );
    final topic = _stableTopicFromParts(
      preferredTopic: combinedProfile.displayTopic,
      fallbackTopic: left.topic.isNotEmpty ? left.topic : right.topic,
      profile: combinedProfile,
    );
    final keywords = SummaryTextUtils.sanitizeTags(
      <String>[
        ...left.keywords,
        ...right.keywords,
        ...combinedProfile.keywords,
        ...combinedProfile.tags,
        if (topic.isNotEmpty) topic,
      ],
      maxTags: _policy.maxKeywordsPerRecord,
      fallbackTitle: topic,
    );

    final sourceIds = <String>{...left.sourceIds, ...right.sourceIds}.toList()
      ..sort();
    return MemoryUnit(
      id: _buildUnitId(sourceIds),
      summary: combinedSummary,
      topic: topic,
      keywords: keywords,
      importance: max(left.importance, right.importance),
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
    if (_slmService.hasStableSemanticAlignment(leftProfile, rightProfile)) {
      return true;
    }
    return max(profileSimilarity, textSimilarity) >=
        _policy.memoryUnitMergeThreshold;
  }

  String _compressSummary(List<String> parts) {
    final clauses = <String>[];
    final seen = <String>{};
    for (final part in parts) {
      final normalizedPart = part.trim();
      if (normalizedPart.isEmpty) {
        continue;
      }
      for (final rawClause in normalizedPart.split(RegExp(r'[\n。！？!?；;]'))) {
        final clause = rawClause.trim();
        if (clause.isEmpty) {
          continue;
        }
        final key = _normalize(clause);
        if (!seen.add(key)) {
          continue;
        }
        clauses.add(clause);
      }
    }

    clauses.sort((a, b) => b.length.compareTo(a.length));
    final selected = clauses.take(_policy.maxCompressedClauses).toList();
    final joined = selected.join('；');
    if (joined.length <= _policy.maxCompressedSummaryChars) {
      return joined;
    }
    return joined.substring(0, _policy.maxCompressedSummaryChars).trimRight();
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
  return _stableTopicFromParts(
    preferredTopic: summary.topic?.trim() ?? '',
    fallbackTopic: summary.title.trim(),
    profile: profile,
  );
}

String _stableTopicFromParts({
  required String preferredTopic,
  required String fallbackTopic,
  required RuleSemanticProfile profile,
}) {
  final preferred = preferredTopic.trim();
  if (preferred.isNotEmpty &&
      !TopicPlaceholderUtils.isPlaceholderTopic(preferred)) {
    return preferred;
  }
  if (profile.displayTopic.trim().isNotEmpty &&
      !TopicPlaceholderUtils.isPlaceholderTopic(profile.displayTopic)) {
    return profile.displayTopic.trim();
  }
  if (fallbackTopic.trim().isNotEmpty &&
      !SummaryTextUtils.isUnnamedTitleValue(fallbackTopic)) {
    return fallbackTopic.trim();
  }
  return preferred;
}
