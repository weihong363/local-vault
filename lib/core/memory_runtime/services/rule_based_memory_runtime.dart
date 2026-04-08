import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:local_vault/core/config/memory_policy_config.dart';
import 'package:local_vault/core/domain/entities/rule_semantic_profile.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';
import 'package:local_vault/core/memory_runtime/repositories/memory_sidecar_repository.dart';
import 'package:local_vault/core/memory_runtime/repositories/state_repository.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/utils/memory_multilingual_keywords.dart';
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
    required StateRepository stateRepository,
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
        _stateRepository = stateRepository,
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
  final StateRepository _stateRepository;
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
        // Note: Auto-promotion logic has been moved to SummaryUseCases for unified management
        // This place no longer performs real-time checks, but waits for background periodic scanning
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
        final previousRecords = _stateRepository.getAllStateRecords();
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

        await _stateRepository.applyUpdates(_toStateUpdates(finalStates));
      } else {
        final rebuiltUnits = await _rebuildMemoryUnits();
        final rebuiltStates = _rebuildStateRecords(
          rebuiltUnits,
          previousRecords: _stateRepository.getAllStateRecords(),
        );

        await _sidecarRepository.replaceMemoryUnits(rebuiltUnits);
        await _stateRepository.applyUpdates(_toStateUpdates(rebuiltStates));
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
    final stateCount = _stateRepository.getAllStateRecords().length;
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

  List<StateUpdate> _toStateUpdates(List<StateRecord> records) {
    final previous = <String, StateRecord>{
      for (final record in _stateRepository.getAllStateRecords())
        record.storageKey: record,
    };
    final next = <String, StateRecord>{
      for (final record in records) record.storageKey: record,
    };
    final updates = <StateUpdate>[];

    for (final entry in next.entries) {
      final existing = previous[entry.key];
      final value = entry.value.toJson();
      if (existing == null) {
        updates.add(StateUpdate.append(entry.key, value));
        continue;
      }

      if (_hasMeaningfulStateDelta(existing, entry.value)) {
        updates.add(StateUpdate.overwrite(entry.key, value));
      } else {
        updates.add(
          StateUpdate.dedup(
            entry.key,
            <String, dynamic>{
              'updatedAt': value['updatedAt'],
            },
          ),
        );
      }
    }

    final removedKeys = previous.keys.toSet().difference(next.keys.toSet());
    for (final key in removedKeys) {
      updates.add(StateUpdate.defer(key));
    }

    return updates;
  }

  bool _hasMeaningfulStateDelta(StateRecord previous, StateRecord next) {
    return previous.summary != next.summary ||
        previous.topic != next.topic ||
        (previous.importance - next.importance).abs() > 0.001 ||
        !_sameStrings(previous.keywords, next.keywords);
  }

  /// Rebuild state records, supporting multi-type state derivation
  ///
  /// Enhanced state derivation logic:
  /// - task_state: tasks, todos, follow-ups
  /// - project_state: projects, releases, milestones
  /// - user_preference_state: user preferences, habits
  /// - topic_state: general topic states
  List<StateRecord> _rebuildStateRecords(
    List<MemoryUnit> units, {
    required List<StateRecord> previousRecords,
  }) {
    final previousByKey = <String, StateRecord>{
      for (final record in previousRecords) record.storageKey: record,
    };
    final groupedPatches = <String, List<StatePatch>>{};

    // Round 1: Collect all state patches
    for (final unit in units) {
      final patch = _deriveStatePatch(unit);
      if (patch == null ||
          patch.metadata.classificationStatus == ClassificationStatus.deferred ||
          patch.confidence < _policy.stateConfidenceThreshold) {
        continue;
      }
      groupedPatches.putIfAbsent(patch.storageKey, () => <StatePatch>[]).add(
            patch,
          );
    }

    // Round 2: Merge patches with same key and build records
    final records = <StateRecord>[];
    for (final entry in groupedPatches.entries) {
      final mergedPatch = _mergeStatePatches(entry.value);
      final previous = previousByKey[entry.key];

      // Check if changes occurred
      final changed = previous == null ||
          previous.summary != mergedPatch.summary ||
          previous.topic != mergedPatch.topic ||
          !_sameStrings(previous.keywords, mergedPatch.keywords) ||
          (previous.importance - mergedPatch.importance).abs() > 0.001;

      // Version control: v1 for first creation, increment on change, keep unchanged otherwise (optimized: simplified expression)
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
          coreMemoryMetadata: mergedPatch.metadata,
        ),
      );
    }

    // Sort by importance descending
    records.sort((a, b) => b.importance.compareTo(a.importance));
    return records;
  }

  Future<List<MemoryUnit>> _rebuildMemoryUnits() async {
    final sourceSummaries = _summaryRepository
        .getAllSummaries()
        .where((summary) => summary.type != MemoryType.session)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Optimization: group by topic first, then merge within groups
    final byTopic = <String, List<SummaryEntity>>{};
    for (final summary in sourceSummaries) {
      final profile = _slmService.describeSummarySemantics(summary);
      final topic = _stableTopic(summary, profile);
      final normalizedTopic = _normalize(topic);

      byTopic.putIfAbsent(normalizedTopic, () => []).add(summary);
    }

    final units = <MemoryUnit>[];

    // Merge within each topic group
    for (final entries in byTopic.entries) {
      final groupUnits = <MemoryUnit>[];

      for (final summary in entries.value) {
        final candidate = _buildCandidateUnit(summary);
        var merged = false;

        // Find best merge target within group (not just the first one)
        MemoryUnit? bestMatch;
        int bestMatchIndex = -1;
        double bestScore = 0.0;

        for (var index = 0; index < groupUnits.length; index++) {
          final existing = groupUnits[index];
          if (_merger.shouldMerge(existing, candidate)) {
            // Calculate merge priority score
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

      // Add merged results from group to total list
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

    if (_containsAny(normalized, StateSignals.preferenceSignals)) {
      namespace = 'user_preference_state';
    } else if (_containsAny(normalized, StateSignals.taskSignals)) {
      namespace = 'task_state';
    } else if (_containsAny(normalized, StateSignals.projectSignals)) {
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
      metadata: CoreMemoryMetadata.fromTopicClassification(
        unit.topic,
        confidence: profile.confidence,
      ),
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
      metadata: primary.metadata,
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

  /// Calculate merge priority score
  double _calculateMergePriority(MemoryUnit existing, MemoryUnit candidate) {
    double score = 0.0;

    // Same topic gets highest priority
    if (_normalize(existing.topic) == _normalize(candidate.topic)) {
      score += 1.0;
    }

    // Time proximity gets higher priority
    final timeDiff =
        existing.createdAt.difference(candidate.createdAt).abs().inDays;
    if (timeDiff <= 1) {
      score += 0.5;
    } else if (timeDiff <= 7) {
      score += 0.3;
    } else if (timeDiff <= 30) {
      score += 0.1;
    }

    // Keyword overlap
    final commonKeywords =
        existing.keywords.toSet().intersection(candidate.keywords.toSet());
    final overlapRatio = commonKeywords.length /
        max(existing.keywords.length, candidate.keywords.length);
    score += overlapRatio * 0.5;

    return score;
  }
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
  static const double _classificationConfidenceThreshold = 0.5;

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

      // New: Process directly generated state records
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

  /// Compress from SummaryEntity to StateRecord
  ///
  /// Implements session → summary → state three-layer compression pipeline
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
      coreMemoryMetadata: _buildCoreMemoryMetadata(topic, profile.confidence),
    );

    final patch = _deriveStatePatchWithProfile(unit, profile);

    if (patch == null ||
        patch.metadata.classificationStatus == ClassificationStatus.deferred ||
        patch.confidence < _policy.stateConfidenceThreshold) {
      return null;
    }

    // Build new state record, version is 1
    return StateRecord(
      namespace: patch.namespace,
      key: patch.key,
      summary: patch.summary,
      topic: patch.topic,
      keywords: patch.keywords,
      importance: patch.importance,
      version: 1,
      updatedAt: DateTime.now(),
      coreMemoryMetadata: patch.metadata,
    );
  }

  /// Derive state patch using existing semantic profile
  /// Avoids repeated calls to describeTextSemantics
  StatePatch? _deriveStatePatchWithProfile(
    MemoryUnit unit,
    RuleSemanticProfile profile,
  ) {
    final normalized =
        _normalize('${unit.topic} ${unit.summary} ${unit.keywords.join(' ')}');
    String namespace = '';

    if (_containsAny(normalized, StateSignals.preferenceSignals)) {
      namespace = 'user_preference_state';
    } else if (_containsAny(normalized, StateSignals.taskSignals)) {
      namespace = 'task_state';
    } else if (_containsAny(normalized, StateSignals.projectSignals)) {
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
      metadata: _buildCoreMemoryMetadata(unit.topic, profile.confidence),
    );
  }

  CoreMemoryMetadata _buildCoreMemoryMetadata(
    String topic,
    double confidence,
  ) {
    return CoreMemoryMetadata.fromTopicClassification(
      topic,
      confidence: confidence,
      threshold: _classificationConfidenceThreshold,
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

  /// Compress merged content
  String _compressSummary(List<String> parts) {
    // Check if SLM has been initialized (available)
    final slmAvailable = _slmService.isInitialized;

    if (slmAvailable) {
      // SLM path: use semantic analysis
      return _compressSummaryWithSLM(parts);
    } else {
      // Rule path: structural merge based on rules
      return _compressSummaryWithRules(parts);
    }
  }

  /// Intelligent compression using SLM
  String _compressSummaryWithSLM(List<String> parts) {
    // 1. Try direct concatenation first, return directly if within limit
    final directJoin = parts.where((p) => p.trim().isNotEmpty).join('\n\n');

    // Use reasonable character limit for merge (2x original limit, minimum 400 chars)
    final mergeCharLimit = max(
      _policy.maxCompressedSummaryChars * 2,
      400,
    );

    if (directJoin.length <= mergeCharLimit) {
      return directJoin;
    }

    // 2. SLM-assisted path: use semantic analysis for enhanced compression
    debugPrint(
        '🔍 [MemoryRuntime] Using SLM-assisted compression for ${parts.length} parts (${directJoin.length} chars)');

    // 3. Use semantic information extracted by SLM to guide compression
    final combinedText = parts.join(' ');
    final semanticProfile = _slmService.describeTextSemantics(
      title: 'Memory Merge',
      content: combinedText,
      tags: [],
    );

    // 4. Use semantically enhanced rule engine for compression
    return _compressSummaryWithRules(parts, semanticProfile: semanticProfile);
  }

  /// Structural merge using rules
  String _compressSummaryWithRules(
    List<String> parts, {
    RuleSemanticProfile? semanticProfile,
  }) {
    // 1. Split content into sentences
    final sentences = <String>[];
    for (final part in parts) {
      final normalizedPart = part.trim();
      if (normalizedPart.isEmpty) continue;

      // Split sentences by multiple punctuation marks
      final splitSentences = normalizedPart.split(RegExp(r'[。！？.!?]'));
      for (final sentence in splitSentences) {
        final clean = sentence.trim();
        if (clean.isNotEmpty && clean.length > 5) {
          sentences.add(clean);
        }
      }
    }

    // 2. Normalize and deduplicate
    final seenNormalized = <String>{};
    final uniqueSentences = <String>[];
    for (final sentence in sentences) {
      final normalized = _normalize(sentence);
      if (!seenNormalized.contains(normalized)) {
        seenNormalized.add(normalized);
        uniqueSentences.add(sentence);
      }
    }

    // 3. Remove similar lines
    final filteredSentences = _removeSimilarLines(uniqueSentences);

    // 4. Remove low-signal lines
    final highSignalSentences = _filterLowSignalLines(filteredSentences);

    // 5. Select top N points based on semantic profile and importance scoring
    final topSentences = _selectTopPoints(
      highSignalSentences,
      min: 5,
      max: 10,
      semanticProfile: semanticProfile,
    );

    // 6. Output as structured bullet points
    return _formatAsBulletPoints(topSentences);
  }

  /// Remove similar lines
  List<String> _removeSimilarLines(List<String> lines) {
    if (lines.length <= 1) return lines;

    final result = <String>[];
    final normalizedLines = lines.map((l) => _normalize(l)).toList();
    final used = List<bool>.filled(lines.length, false);

    for (int i = 0; i < lines.length; i++) {
      if (used[i]) continue;

      result.add(lines[i]);

      // Mark all lines similar to current line as used
      for (int j = i + 1; j < lines.length; j++) {
        if (!used[j] &&
            _areLinesSimilar(normalizedLines[i], normalizedLines[j])) {
          used[j] = true;
        }
      }
    }

    return result;
  }

  /// Determine if two lines are similar
  bool _areLinesSimilar(String normalizedA, String normalizedB) {
    final wordsA = normalizedA.split(RegExp(r'\s+')).toSet();
    final wordsB = normalizedB.split(RegExp(r'\s+')).toSet();

    if (wordsA.isEmpty || wordsB.isEmpty) return false;

    final intersection = wordsA.intersection(wordsB);
    final union = wordsA.union(wordsB);

    return intersection.length / union.length >= 0.5;
  }

  /// Filter low-signal lines
  /// Filter low-signal lines
  List<String> _filterLowSignalLines(List<String> lines) {
    final lowSignalPatterns = LowSignalPatterns.getAllPatterns();

    return lines.where((line) {
      final normalized = _normalize(line);
      return !lowSignalPatterns.any((pattern) => pattern.hasMatch(normalized));
    }).toList();
  }

  /// Select top N points
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

      // Contains important keywords scores high
      if (ImportantKeywords.containsAny(point)) {
        score += 0.3;
      }

      // Starts with action verb scores high
      if (ActionVerbs.startsWithAny(point)) {
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

  /// Format as bullet points
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

    // Compress the merged content returned by SLM to avoid keeping the full text
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

  /// Normalize text for pattern matching
  String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Check if text contains any keyword
  bool _containsAny(String normalized, Set<String> signals) {
    return signals.any((signal) => normalized.contains(signal));
  }

  /// Normalize key name
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
    /// Select summary content based on strategy
    final String summaryContent;
    switch (strategy) {
      case MemoryMergeStrategy.keepOld:
        // Keep old version (left) content, no compression
        summaryContent = left.summary;
        break;
      case MemoryMergeStrategy.keepNew:
        // Keep new version (right) content, no compression
        summaryContent = right.summary;
        break;
      case MemoryMergeStrategy.smartMerge:
        // Smart merge: execute compression logic
        summaryContent =
            _compressSummary(<String>[left.summary, right.summary]);
        break;
    }

    // 1. Call SLM first to get semantic profile (for topic and keywords)
    final combinedProfile = _slmService.describeTextSemantics(
      title: '${left.topic}\n${right.topic}',
      content: summaryContent,
      tags: <String>[], // ← Don't pass raw tags directly to avoid pollution
    );

    // 2. Determine topic
    final topic = _stableTopicFromParts(
      preferredTopic: combinedProfile.displayTopic,
      fallbackTopic: left.topic.isNotEmpty ? left.topic : right.topic,
      profile: combinedProfile,
      content: summaryContent,
    );

    // 3. Intelligently merge keywords
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
    // 1. Check if topics are exactly the same first (fast path)
    if (left.topic.isNotEmpty &&
        right.topic.isNotEmpty &&
        _normalize(left.topic) == _normalize(right.topic)) {
      return true;
    }

    // 2. Check time proximity (records within 7 days are easier to merge)
    final timeDiff = left.createdAt.difference(right.createdAt).abs().inDays;
    final timeBonus = timeDiff <= 7 ? 0.15 : (timeDiff <= 30 ? 0.05 : 0.0);

    // 3. Check keyword overlap
    final commonKeywords =
        left.keywords.toSet().intersection(right.keywords.toSet());
    final keywordOverlapRatio = commonKeywords.length /
        max(left.keywords.length, right.keywords.length);
    if (keywordOverlapRatio >= 0.5) {
      return true; // Direct merge if keyword overlap exceeds 50%
    }

    // 4. SLM semantic analysis (if available)
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

    // 5. Check semantic alignment
    if (_slmService.hasStableSemanticAlignment(leftProfile, rightProfile)) {
      return true;
    }

    // 6. Comprehensive scoring
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

    // Apply time bonus
    final adjustedThreshold = _policy.memoryUnitMergeThreshold - timeBonus;

    return max(profileSimilarity, textSimilarity) >= adjustedThreshold;
  }

  @override
  String compressSummaryForMerge(String content1, String content2) {
    // Directly call internal compression method
    return _compressSummary(<String>[content1, content2]);
  }

  /// Intelligent summary compression
  ///
  /// Strategy selection based on SLM availability:
  /// - SLM enabled: use semantic analysis for intelligent merge
  /// - SLM disabled: use rule-based structural merge (split → normalize → deduplicate → denoise → keep key points)
  String _compressSummary(List<String> parts) {
    // Check if SLM has been initialized (available)
    final slmAvailable = _slmService.isInitialized;

    if (slmAvailable) {
      // SLM path: use semantic analysis
      return _compressSummaryWithSLM(parts);
    } else {
      // Rule path: structural merge based on rules
      return _compressSummaryWithRules(parts);
    }
  }

  /// Intelligent compression using SLM
  ///
  /// Core idea: Use SLM semantic analysis results to guide rule compression
  /// 1. Try direct concatenation first, return directly if within limit
  /// 2. When exceeding limit, use SLM semantic information to guide compression priority
  String _compressSummaryWithSLM(List<String> parts) {
    // 1. Try direct concatenation first, return directly if within limit
    final directJoin = parts.where((p) => p.trim().isNotEmpty).join('\n\n');

    // Use reasonable character limit for merge (2x original limit, minimum 400 chars)
    final mergeCharLimit = max(
      _policy.maxCompressedSummaryChars * 2,
      400,
    );

    if (directJoin.length <= mergeCharLimit) {
      return directJoin;
    }

    // 2. SLM-assisted path: use semantic analysis for enhanced compression
    debugPrint(
        '🔍 [MemoryRuntime] Using SLM-assisted compression for ${parts.length} parts (${directJoin.length} chars)');

    // 3. Use semantic information extracted by SLM to guide compression
    // Combine multiple parts and extract semantic profile for subsequent sentence scoring
    final combinedText = parts.join(' ');
    final semanticProfile = _slmService.describeTextSemantics(
      title: 'Memory Merge',
      content: combinedText,
      tags: [],
    );

    // 4. Use semantically enhanced rule engine for compression
    return _compressSummaryWithRules(parts, semanticProfile: semanticProfile);
  }

  /// Structural merge using rules
  ///
  /// Follows principle: Compression = Structure + Deduplication (not rewriting)
  ///
  /// Parameters:
  /// - parts: Text fragments to merge
  /// - semanticProfile: Optional semantic profile for enhanced sentence scoring
  String _compressSummaryWithRules(
    List<String> parts, {
    RuleSemanticProfile? semanticProfile,
  }) {
    // 1. Split content into sentences
    final sentences = <String>[];
    for (final part in parts) {
      final normalizedPart = part.trim();
      if (normalizedPart.isEmpty) continue;

      // Split sentences by multiple punctuation marks
      final splitSentences = normalizedPart.split(RegExp(r'[。！？.!?]'));
      for (final sentence in splitSentences) {
        final clean = sentence.trim();
        if (clean.isNotEmpty && clean.length > 5) {
          // Filter too short sentences
          sentences.add(clean);
        }
      }
    }

    // 2. Normalize (lowercase, trim) and deduplicate
    final seenNormalized = <String>{};
    final uniqueSentences = <String>[];
    for (final sentence in sentences) {
      final normalized = _normalize(sentence);
      if (!seenNormalized.contains(normalized)) {
        seenNormalized.add(normalized);
        uniqueSentences.add(sentence);
      }
    }

    // 3. Remove similar lines (based on edit distance or keyword overlap)
    final filteredSentences = _removeSimilarLines(uniqueSentences);

    // 4. Remove low-signal lines
    final highSignalSentences = _filterLowSignalLines(filteredSentences);

    // 5. Select top N points based on semantic profile and importance scoring
    final topSentences = _selectTopPoints(
      highSignalSentences,
      min: 5,
      max: 10,
      semanticProfile: semanticProfile,
    );

    // 6. Output as structured bullet points, not paragraphs
    return _formatAsBulletPoints(topSentences);
  }

  /// Remove similar lines
  List<String> _removeSimilarLines(List<String> lines) {
    if (lines.length <= 1) return lines;

    final result = <String>[];
    final normalizedLines = lines.map((l) => _normalize(l)).toList();
    final used = List<bool>.filled(lines.length, false);

    for (int i = 0; i < lines.length; i++) {
      if (used[i]) continue;

      result.add(lines[i]);

      // Mark all lines similar to current line as used
      for (int j = i + 1; j < lines.length; j++) {
        if (!used[j] &&
            _areLinesSimilar(normalizedLines[i], normalizedLines[j])) {
          used[j] = true;
        }
      }
    }

    return result;
  }

  /// Determine if two lines are similar (based on keyword overlap)
  bool _areLinesSimilar(String normalizedA, String normalizedB) {
    // Simple similarity judgment: common word proportion
    final wordsA = normalizedA.split(RegExp(r'\s+')).toSet();
    final wordsB = normalizedB.split(RegExp(r'\s+')).toSet();

    if (wordsA.isEmpty || wordsB.isEmpty) return false;

    final intersection = wordsA.intersection(wordsB);
    final union = wordsA.union(wordsB);

    // Jaccard similarity >= 0.5 considered similar
    return intersection.length / union.length >= 0.5;
  }

  /// Filter low-signal lines
  /// Filter low-signal lines
  List<String> _filterLowSignalLines(List<String> lines) {
    final lowSignalPatterns = LowSignalPatterns.getAllPatterns();

    return lines.where((line) {
      final normalized = _normalize(line);
      return !lowSignalPatterns.any((pattern) => pattern.hasMatch(normalized));
    }).toList();
  }

  /// Select top N points
  ///
  /// Parameters:
  /// - points: Candidate points list
  /// - min: Minimum number to keep
  /// - max: Maximum number to keep
  /// - semanticProfile: Optional semantic profile for enhanced scoring
  List<String> _selectTopPoints(
    List<String> points, {
    required int min,
    required int max,
    RuleSemanticProfile? semanticProfile,
  }) {
    if (points.isEmpty) return [];

    // Score by information content (length + contains numbers/keywords + semantic relevance)
    final scored = points.map((point) {
      double score = 0;

      // Medium length scores high (20-100 chars)
      final length = point.length;
      if (length >= 20 && length <= 100) {
        score += 1.0;
      } else if (length > 100) {
        score += 0.5;
      } else if (length >= 10) {
        score += 0.3;
      }

      // Contains numbers scores high (data, versions, etc.)
      if (RegExp(r'\d').hasMatch(point)) {
        score += 0.5;
      }

      // Contains important keywords scores high
      if (ImportantKeywords.containsAny(point)) {
        score += 0.3;
      }

      // Starts with verb scores high
      if (ActionVerbs.startsWithAny(point)) {
        score += 0.2;
      }

      // If has semantic profile, check relevance to topic
      if (semanticProfile != null) {
        // Sentences containing topic keywords score higher
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

        // Extra points for containing high-weight keywords from profile
        if (semanticProfile.facetKey.isNotEmpty &&
            point.contains(semanticProfile.facetKey)) {
          score += 0.3;
        }
      }

      return MapEntry(point, score);
    }).toList();

    // Sort by score descending
    scored.sort((a, b) => b.value.compareTo(a.value));

    // Take top max items, at least min items
    final count = scored.length.clamp(min, max);
    return scored.take(count).map((e) => e.key).toList();
  }

  /// Format as structured bullet points
  String _formatAsBulletPoints(List<String> points) {
    if (points.isEmpty) return '';

    // Each point on one line, using • symbol
    return points.map((point) => '• $point').join('\n');
  }

  /// Calculate merged importance
  double _calculateMergedImportance(MemoryUnit left, MemoryUnit right) {
    // 1. Base importance (take maximum)
    final baseImportance = max(left.importance, right.importance);

    // 2. Access frequency reward (based on sourceIds count)
    final maxAccessCount = max(left.sourceIds.length, right.sourceIds.length);
    final accessBonus =
        min(0.2, maxAccessCount * 0.02); // +0.02 per source, max 0.2

    // 3. Recency reward (recent records)
    final now = DateTime.now();
    final leftAge = now.difference(left.updatedAt).inDays;
    final rightAge = now.difference(right.updatedAt).inDays;
    final recencyBonus = max(
      0.1 * (1 - leftAge / 30), // Decay within 30 days
      0.1 * (1 - rightAge / 30),
    ).clamp(0.0, 0.1);

    // 4. Comprehensive calculation
    final mergedImportance = baseImportance + accessBonus + recencyBonus;

    return mergedImportance.clamp(0.0, 1.0);
  }

  /// Intelligently merge keywords
  List<String> _mergeKeywordsIntelligently({
    required List<String> leftKeywords,
    required List<String> rightKeywords,
    required List<String> slmKeywords,
    required List<String> slmTags,
    required String topic,
    required int maxKeywords,
  }) {
    // 1. Filter low-quality tags (complete sentences, fragments, etc.)
    final filteredUserTags = <String>[];
    for (final tag in [...leftKeywords, ...rightKeywords]) {
      if (_isValidKeyword(tag)) {
        filteredUserTags.add(tag);
      }
    }

    // 2. Merge all sources
    final allKeywords = <String>{
      ...filteredUserTags,
      ...slmKeywords,
      ...slmTags,
      if (topic.isNotEmpty) topic,
    };

    // 3. Remove semantic duplicates (simplified version: based on containment)
    final deduplicated = <String>{};
    final sortedKeywords = allKeywords.toList()
      ..sort((a, b) => a.length.compareTo(b.length)); // Shorter first

    for (final keyword in sortedKeywords) {
      final normalized = keyword.toLowerCase().trim();
      if (normalized.isEmpty) continue;

      // Check if contained by longer word
      final isContained = deduplicated.any(
        (existing) => existing.toLowerCase().contains(normalized),
      );

      if (!isContained) {
        deduplicated.add(keyword);
      }
    }

    // 4. Rank by importance and truncate
    final ranked = deduplicated.toList()
      ..sort((a, b) {
        // topic priority highest
        if (a == topic) return -1;
        if (b == topic) return 1;

        // SLM generated keywords prioritized
        final aIsSlm = slmKeywords.contains(a) || slmTags.contains(a);
        final bIsSlm = slmKeywords.contains(b) || slmTags.contains(b);
        if (aIsSlm && !bIsSlm) return -1;
        if (!aIsSlm && bIsSlm) return 1;

        // Otherwise sort by length (medium is better)
        final aScore = (a.length - 5).abs();
        final bScore = (b.length - 5).abs();
        return aScore.compareTo(bScore);
      });

    return ranked.take(maxKeywords).toList();
  }

  /// Determine if it's a valid keyword
  bool _isValidKeyword(String keyword) {
    final trimmed = keyword.trim();

    // Too short or too long are not good keywords
    if (trimmed.length < 2 || trimmed.length > 30) {
      return false;
    }

    // Contains complete sentence punctuation is not a keyword
    if (RegExp(r'[,.!?;:]').hasMatch(trimmed)) {
      return false;
    }

    // Ends with parenthesis is not a keyword
    if (trimmed.endsWith(')') || trimmed.endsWith('）')) {
      return false;
    }

    return true;
  }
}

class RuleBasedMemoryRetriever implements MemoryRetriever {
  RuleBasedMemoryRetriever({
    required MemorySidecarRepository sidecarRepository,
    required StateRepository stateRepository,
    required MemorySLMService slmService,
    required MemoryPolicy policy,
  })  : _sidecarRepository = sidecarRepository,
        _stateRepository = stateRepository,
        _slmService = slmService,
        _policy = policy;

  final MemorySidecarRepository _sidecarRepository;
  final StateRepository _stateRepository;
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

    final stateScores = _stateRepository
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
            (record) =>
                _normalize(record.effectiveTopic) ==
                _normalize(unit.effectiveTopic),
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
      title: unit.effectiveTopic,
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
      unit.effectiveTopic,
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
      title: record.effectiveTopic,
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
      record.effectiveTopic,
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
          '- [${record.namespace}] ${record.effectiveTopic.isEmpty ? record.key : record.effectiveTopic}: ${record.summary}',
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
          '- ${unit.effectiveTopic.isEmpty ? unit.summary : unit.effectiveTopic}: ${unit.summary}',
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

  // 1. Prioritize explicitly specified topic
  if (preferred.isNotEmpty &&
      !TopicPlaceholderUtils.isPlaceholderTopic(preferred)) {
    return preferred;
  }

  // 2. Use SLM semantic analysis result
  if (profile.displayTopic.isNotEmpty &&
      !TopicPlaceholderUtils.isPlaceholderTopic(profile.displayTopic)) {
    return profile.displayTopic.trim();
  }

  // 3. Fallback to title
  final fallback = fallbackTopic.trim();
  if (fallback.isNotEmpty && !SummaryTextUtils.isUnnamedTitleValue(fallback)) {
    return fallback;
  }

  // 4. Ultimate fallback: extract from content or return default value
  return _getDefaultTopic(content);
}

/// Get default topic based on language (ultimate fallback)
String _getDefaultTopic(String? content) {
  if (content != null && content.trim().isNotEmpty) {
    // Try to extract from first sentence
    final firstSentence =
        content.trim().split(RegExp(r'[.!？!.!?.\n,,;]')).first.trim();

    if (firstSentence.length >= 2 && firstSentence.length <= 20) {
      return firstSentence;
    }

    // If first sentence is too long, try to take first 20 characters as topic
    if (firstSentence.length > 20) {
      // For Chinese content, directly take first 20 characters
      return firstSentence.substring(0, 20);
    }

    // Or take first 10 words (applicable for English)
    final words = content.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      final preview = words.take(10).join(' ');
      if (preview.length <= 20) return preview;
    }
  }

  // Final default value (by language)
  final hasCJK = content != null &&
      RegExp(r'[\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF]').hasMatch(content);
  return hasCJK ? 'Unnamed Memory' : 'Untitled Memory';
}
