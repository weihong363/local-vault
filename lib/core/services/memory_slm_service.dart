import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:local_vault/core/domain/entities/rule_semantic_profile.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/providers/locale_provider.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:local_vault/core/services/memory_slm_config.dart';
import 'package:local_vault/core/utils/similarity_utils.dart';
import 'package:local_vault/core/utils/summary_text_utils.dart';
import 'package:local_vault/core/utils/topic_placeholder_utils.dart';
import 'package:local_vault/l10n/app_localizations.dart';

typedef ModelDownloadProgressCallback = void Function(double progress);

enum MemorySlmFallbackMode {
  none,
  cache,
  rules,
  disabled,
}

class MemorySlmResponse<T> {
  const MemorySlmResponse({
    required this.success,
    required this.data,
    required this.fallbackUsed,
    required this.latencyMs,
    this.errorCode,
  });

  final bool success;
  final T data;
  final MemorySlmFallbackMode fallbackUsed;
  final int latencyMs;
  final String? errorCode;
}

class MemorySlmConfiguration {
  const MemorySlmConfiguration({
    this.requestTimeout,
    this.maxQueueWait,
    this.maxCacheEntries,
    this.maxTokens,
    this.temperature,
    this.topK,
  });

  final Duration? requestTimeout;
  final Duration? maxQueueWait;
  final int? maxCacheEntries;
  final int? maxTokens;
  final double? temperature;
  final int? topK;
}

class MemorySlmMergeResult {
  const MemorySlmMergeResult({
    required this.title,
    required this.content,
    required this.tags,
  });

  final String title;
  final String content;
  final List<String> tags;
}

class MemorySlmSummaryMetadata {
  const MemorySlmSummaryMetadata({
    required this.title,
    required this.tags,
  });

  final String title;
  final List<String> tags;
}

class MemorySLMService {
  MemorySLMService({
    MemorySlmConfiguration configuration = const MemorySlmConfiguration(),
    AppSettingsService? settingsService,
    RuleSemanticProfile? Function({
      required String title,
      required String content,
      List<String> tags,
    })? semanticProfileResolver,
  })  : _configuration = configuration,
        _settingsService = settingsService ?? AppSettingsService(),
        _semanticProfileResolver = semanticProfileResolver;

  final MemorySlmConfiguration _configuration;
  final AppSettingsService _settingsService;
  final RuleSemanticProfile? Function({
    required String title,
    required String content,
    List<String> tags,
  })? _semanticProfileResolver;

  static const Set<String> _supportedBundledModelExtensions = <String>{
    'gguf',
  };
  static const Set<String> _ragDirectAliases = <String>{
    '检索增强生成',
    '検索拡張生成',
    '검색 증강 생성',
    'retrieval augmented generation',
    'generación aumentada por recuperación',
    'generacion aumentada por recuperacion',
    'génération augmentée par récupération',
    'generation augmentee par recuperation',
  };
  static final List<Pattern> _ragSecondarySignals = <Pattern>[
    '向量',
    '召回',
    '重排',
    '检索',
    '知识库',
    'ベクトル',
    '検索',
    'リランキング',
    '知識ベース',
    '벡터',
    '검색',
    '리랭크',
    '재정렬',
    '지식베이스',
    'recuperación',
    'recuperacion',
    'reordenación',
    'reordenacion',
    'base de conocimiento',
    'recherche vectorielle',
    'reclassement',
    'base de connaissances',
    'vektor',
    'neubewertung',
    'wissensbasis',
    RegExp(r'\bembedding\b'),
    RegExp(r'\bembeddings\b'),
    RegExp(r'\bchunk\b'),
    RegExp(r'\brerank\b'),
    RegExp(r'\bfaiss\b'),
    RegExp(r'\bmilvus\b'),
    RegExp(r'\bqdrant\b'),
  ];
  static const Set<String> _llmAliases = <String>{
    '大语言模型',
    '大規模言語モデル',
    '대규모 언어 모델',
    'modelo de lenguaje grande',
    'grand modèle de langage',
    'grand modele de langage',
    'großes sprachmodell',
    'grosses sprachmodell',
  };
  static const Set<String> _slmAliases = <String>{
    '小语言模型',
    '小規模言語モデル',
    '소형 언어 모델',
    'modelo de lenguaje pequeño',
    'modelo de lenguaje pequeno',
    'petit modèle de langage',
    'petit modele de langage',
    'kleines sprachmodell',
  };
  static const Set<String> _ocrAliases = <String>{
    '文字识别',
    '光学文字認識',
    '텍스트 인식',
    '광학 문자 인식',
    'reconocimiento óptico de caracteres',
    'reconocimiento optico de caracteres',
    'reconnaissance optique de caractères',
    'reconnaissance optique de caracteres',
    'optische zeichenerkennung',
  };
  static final RegExp _latinScriptRegex = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿĀ-žẞß]');
  static const List<String> _cjkTopicTemplateSuffixes = <String>[
    '登录页改版',
    '发布计划',
    '发布节奏',
    '回滚预案',
    '权限诊断',
    '白名单配置',
    '数据库查询',
    '数据库检查',
    '模板管理',
    '记忆管理',
    '清单',
    '方案',
    '计划',
    '问题',
    '决策',
    '流程',
    '改版',
    '优化',
    '修复',
    '发布',
    '上线',
    '回滚',
    '诊断',
    '备份',
    '数据库',
    '模板',
    '记忆',
    '配置',
    '权限',
    '同步',
    '会议',
    '复盘',
    '需求',
  ];
  static const List<String> _latinTopicTemplateSuffixes = <String>[
    'plan',
    'issue',
    'decision',
    'review',
    'checklist',
    'redesign',
    'launch',
    'release',
    'rollback',
    'diagnostics',
    'diagnostic',
    'permission',
    'permissions',
    'backup',
    'database',
    'template',
    'memory',
    'sync',
  ];
  static const Set<String> _genericTopicKeywords = <String>{
    '计划',
    '方案',
    '问题',
    '会议',
    '同步',
    '任务',
    '待办',
    '内容',
    '记录',
    '更新',
    'plan',
    'issue',
    'meeting',
    'sync',
    'task',
    'todo',
    'content',
    'record',
    'update',
    'review',
    'summary',
    '計画',
    '会議',
    '同期',
    '記録',
    '회의',
    '계획',
    '기록',
    '동기화',
  };

  final LinkedHashMap<String, String> _topicCache = LinkedHashMap();
  final LinkedHashMap<String, String> _upgradeReasonCache = LinkedHashMap();

  Future<void>? _initializing;
  bool _isInitialized = false;
  Future<void> _requestQueue = Future<void>.value();
  bool _runtimeSlmInferenceEnabled = false;
  bool _runtimeSlmInferenceEnabledLoaded = false;
  Future<void>? _runtimeSlmInferenceEnabledLoading;
  MemorySlmConfig? _slmConfig;
  Future<MemorySlmConfig>? _slmConfigLoading;

  bool get isInitialized => _isInitialized;

  bool get isModelAvailable => false;

  bool get experimentalNativeInferenceEnabled => false;

  bool get nativeInferenceSupported => false;

  bool get nativeSymbolsAvailable => false;

  bool isSupportedNativeModelFileName(String fileName) {
    final extension = _extractFileExtension(fileName);
    return _supportedBundledModelExtensions.contains(extension);
  }

  Future<String> describeNativeModelFileSupport(String fileName) async {
    final localizations = await AppLocalizations.delegate.load(
      await _resolvePreferredLocale(),
    );
    final extension = _extractFileExtension(fileName);
    if (_supportedBundledModelExtensions.contains(extension)) {
      return localizations.modelFormatBundledSupported(extension);
    }
    if (extension.isEmpty) {
      return localizations.unknownModelFormat;
    }
    return localizations.modelFormatUnsupportedForLocalRules(extension);
  }

  Future<MemorySlmConfig> resolveConfig() => _loadSlmConfig();

  Future<bool> isSlmInferenceEnabled() async {
    await _ensureRuntimeSlmInferencePreferenceLoaded();
    return _runtimeSlmInferenceEnabled;
  }

  Future<void> setSlmInferenceEnabled(bool enabled) async {
    await _settingsService.setSlmInferenceEnabled(enabled);
    _runtimeSlmInferenceEnabled = enabled;
    _runtimeSlmInferenceEnabledLoaded = true;
    _isInitialized = false;
    _initializing = null;
  }

  Future<void> initialize({
    ModelDownloadProgressCallback? onProgress,
  }) {
    if (_isInitialized) {
      return Future<void>.value();
    }
    final pending = _initializing;
    if (pending != null) {
      return pending;
    }

    _initializing = _initializeInternal(onProgress: onProgress);
    return _initializing!;
  }

  Future<void> _initializeInternal({
    ModelDownloadProgressCallback? onProgress,
  }) async {
    try {
      await _ensureRuntimeSlmInferencePreferenceLoaded();
      await _loadSlmConfig();
      _isInitialized = true;
      onProgress?.call(1.0);
      debugPrint(
        '🧠 [MemorySLMService] Initialization completed in local rule mode.',
      );
    } catch (error, stackTrace) {
      _isInitialized = true;
      debugPrint(
          '⚠️ [MemorySLMService] Initialization failed, degraded mode enabled: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _initializing = null;
    }
  }

  RuleSemanticProfile describeSummarySemantics(SummaryEntity summary) {
    return describeTextSemantics(
      title: summary.title,
      content: summary.content,
      tags: summary.tags,
    );
  }

  RuleSemanticProfile describeBatchSemantics(Iterable<SummaryEntity> sessions) {
    final normalizedSessions = sessions
        .where(
          (session) =>
              session.title.trim().isNotEmpty ||
              session.content.trim().isNotEmpty,
        )
        .toList(growable: false);
    if (normalizedSessions.isEmpty) {
      return const RuleSemanticProfile.empty();
    }

    final stableTopics = normalizedSessions
        .map((session) => session.topic?.trim() ?? '')
        .where(
          (topic) =>
              topic.isNotEmpty &&
              !TopicPlaceholderUtils.isPlaceholderTopic(topic),
        )
        .toSet();
    final uniqueTitles = normalizedSessions
        .map((session) => session.title.trim())
        .where((title) => title.isNotEmpty)
        .toSet();
    final combinedTitle = stableTopics.length == 1
        ? stableTopics.first
        : uniqueTitles.length == 1
            ? uniqueTitles.first
            : normalizedSessions
                .map((session) => session.title.trim())
                .where((title) => title.isNotEmpty)
                .join('\n');
    final combinedContent = normalizedSessions
        .map((session) => session.content.trim())
        .where((content) => content.isNotEmpty)
        .join('\n');
    final combinedTags =
        normalizedSessions.expand((session) => session.tags).toList();

    return describeTextSemantics(
      title: combinedTitle,
      content: combinedContent,
      tags: combinedTags,
    );
  }

  RuleSemanticProfile describeTextSemantics({
    required String title,
    required String content,
    List<String> tags = const <String>[],
  }) {
    final injectedProfile = _semanticProfileResolver?.call(
      title: title,
      content: content,
      tags: tags,
    );
    if (injectedProfile != null) {
      return injectedProfile;
    }

    final localizations = _fallbackLocalizationsForText('$title $content');
    final canonicalTopic = _extractCanonicalTopicAlias(title, content) ?? '';
    final canonicalKey = _normalizeText(canonicalTopic);
    final candidates = _collectSemanticCandidates(
      title: title,
      content: content,
      tags: tags,
      canonicalTopic: canonicalTopic,
      localizations: localizations,
    );
    final bestFacet = _pickBestSemanticFacet(
      candidates,
      canonicalKey: canonicalKey,
    );
    final displayTopic = _renderSemanticTopic(
      title: title,
      content: content,
      canonicalTopic: canonicalTopic,
      facet: bestFacet?.label ?? '',
      localizations: localizations,
    );
    final displayTitle = _renderSemanticTitle(
      title: title,
      content: content,
      canonicalTopic: canonicalTopic,
      facet: bestFacet?.label ?? '',
      displayTopic: displayTopic,
    );
    final resolvedTags = _buildSemanticTags(
      title: displayTitle,
      content: content,
      canonicalTopic: canonicalTopic,
      facet: bestFacet?.label ?? '',
      explicitTags: tags,
    );
    final keywords = _collectSemanticKeywords(
      displayTopic: displayTopic,
      displayTitle: displayTitle,
      canonicalTopic: canonicalTopic,
      facet: bestFacet?.label ?? '',
      tags: resolvedTags,
      content: content,
    );
    final confidence = _estimateSemanticConfidence(
      canonicalTopic: canonicalTopic,
      bestFacet: bestFacet,
      displayTopic: displayTopic,
      tags: resolvedTags,
      title: title,
    );

    return RuleSemanticProfile(
      language: _detectPrimaryLanguage('$displayTopic $displayTitle') ==
              _PrimaryLanguage.cjk
          ? RuleSemanticLanguage.cjk
          : RuleSemanticLanguage.latin,
      domainKey: canonicalKey,
      domainLabel: canonicalTopic,
      facetKey: _normalizeText(bestFacet?.label ?? ''),
      facetLabel: bestFacet?.label ?? '',
      displayTopic: displayTopic,
      displayTitle: displayTitle,
      tags: resolvedTags,
      keywords: keywords,
      confidence: confidence,
    );
  }

  double calculateSemanticProfileSimilarity(
    RuleSemanticProfile left,
    RuleSemanticProfile right,
  ) {
    if (left.semanticKey.isEmpty || right.semanticKey.isEmpty) {
      return SimilarityUtils.jaccardSimilarity(
        '${left.displayTopic} ${left.displayTitle}',
        '${right.displayTopic} ${right.displayTitle}',
      );
    }

    double score = 0.0;
    if (left.domainKey.isNotEmpty && left.domainKey == right.domainKey) {
      score += 0.35;
    }
    if (left.facetKey.isNotEmpty && left.facetKey == right.facetKey) {
      score += 0.35;
    } else if (_isContainedTopic(left.facetKey, right.facetKey)) {
      score += 0.18;
    }

    final keywordOverlap = SimilarityUtils.tokenOverlapCoefficient(
      left.keywords.join(' '),
      right.keywords.join(' '),
    );
    final titleSimilarity = SimilarityUtils.calculateMemorySimilarity(
      left.displayTitle,
      left.displayTopic,
      right.displayTitle,
      right.displayTopic,
    );
    score += keywordOverlap * 0.15;
    score += titleSimilarity * 0.15;
    return score.clamp(0.0, 1.0);
  }

  bool hasStableSemanticAlignment(
    RuleSemanticProfile left,
    RuleSemanticProfile right, {
    int? minTagOverlap,
  }) {
    if (left.semanticKey.isNotEmpty && left.semanticKey == right.semanticKey) {
      return true;
    }

    if (left.domainKey.isNotEmpty &&
        left.domainKey == right.domainKey &&
        left.hasSpecificFacet &&
        right.hasSpecificFacet &&
        _isContainedTopic(left.facetKey, right.facetKey)) {
      return true;
    }

    final effectiveMinTagOverlap =
        minTagOverlap ?? _effectiveSlmConfig.heuristics.sameTopicMinTagOverlap;
    final tagOverlap =
        left.tags.toSet().intersection(right.tags.toSet()).length;
    if (tagOverlap >= effectiveMinTagOverlap &&
        left.domainKey.isNotEmpty &&
        left.domainKey == right.domainKey) {
      return true;
    }

    return calculateSemanticProfileSimilarity(left, right) >= 0.72;
  }

  Future<MemorySlmResponse<String>> extractTopic(
    String title,
    String content,
  ) async {
    final cacheKey = '${title.trim()}::${content.trim()}';
    final cached = _topicCache[cacheKey];
    if (cached != null) {
      return MemorySlmResponse<String>(
        success: true,
        data: cached,
        fallbackUsed: MemorySlmFallbackMode.cache,
        latencyMs: 0,
      );
    }

    final fallbackTopic = describeTextSemantics(
      title: title,
      content: content,
    ).displayTopic;
    return _runWithFallback<String>(
      operation: 'extractTopic',
      fallbackData: fallbackTopic,
      errorCode: 'extract_topic_failed',
      action: () {
        return _runQueued<MemorySlmResponse<String>>(() async {
          await initialize();
          final stopwatch = Stopwatch()..start();
          _setCache(_topicCache, cacheKey, fallbackTopic);
          stopwatch.stop();
          return MemorySlmResponse<String>(
            success: true,
            data: fallbackTopic,
            fallbackUsed: MemorySlmFallbackMode.rules,
            latencyMs: stopwatch.elapsedMilliseconds,
            errorCode: 'slm_rule_mode',
          );
        });
      },
    );
  }

  Future<MemorySlmResponse<bool>> isSameTopic(
    SummaryEntity entityA,
    SummaryEntity entityB,
  ) async {
    final profileA = describeSummarySemantics(entityA);
    final profileB = describeSummarySemantics(entityB);
    final fallback = hasStableSemanticAlignment(profileA, profileB);
    return _runWithFallback<bool>(
      operation: 'isSameTopic',
      fallbackData: fallback,
      errorCode: 'same_topic_failed',
      action: () {
        return _runQueued<MemorySlmResponse<bool>>(() async {
          await initialize();
          final stopwatch = Stopwatch()..start();
          stopwatch.stop();
          return MemorySlmResponse<bool>(
            success: true,
            data: fallback,
            fallbackUsed: MemorySlmFallbackMode.rules,
            latencyMs: stopwatch.elapsedMilliseconds,
            errorCode: 'slm_rule_mode',
          );
        });
      },
    );
  }

  Future<MemorySlmResponse<MemorySlmMergeResult>> mergeSessions(
    List<SummaryEntity> sessions,
  ) async {
    final fallback = _mergeSessionsFallback(sessions);
    if (sessions.isEmpty) {
      return MemorySlmResponse<MemorySlmMergeResult>(
        success: false,
        data: fallback,
        fallbackUsed: MemorySlmFallbackMode.rules,
        latencyMs: 0,
        errorCode: 'empty_sessions',
      );
    }

    return _runWithFallback<MemorySlmMergeResult>(
      operation: 'mergeSessions',
      fallbackData: fallback,
      errorCode: 'merge_sessions_failed',
      action: () {
        return _runQueued<MemorySlmResponse<MemorySlmMergeResult>>(() async {
          await initialize();
          final stopwatch = Stopwatch()..start();
          stopwatch.stop();
          return MemorySlmResponse<MemorySlmMergeResult>(
            success: true,
            data: fallback,
            fallbackUsed: MemorySlmFallbackMode.rules,
            latencyMs: stopwatch.elapsedMilliseconds,
            errorCode: 'slm_rule_mode',
          );
        });
      },
    );
  }

  Future<MemorySlmResponse<String>> generateUpgradeReason(
    SummaryEntity fact,
  ) async {
    final locale = await _resolvePreferredLocale();
    final languageCode = locale.languageCode;
    final cacheKey =
        '${fact.id}_${fact.accessCount}_${fact.importance.toStringAsFixed(2)}_$languageCode';
    final cached = _upgradeReasonCache[cacheKey];
    if (cached != null) {
      return MemorySlmResponse<String>(
        success: true,
        data: cached,
        fallbackUsed: MemorySlmFallbackMode.cache,
        latencyMs: 0,
      );
    }

    final fallback = await _generateUpgradeReasonFallback(
      fact,
      locale: locale,
    );
    return _runWithFallback<String>(
      operation: 'generateUpgradeReason',
      fallbackData: fallback,
      errorCode: 'upgrade_reason_failed',
      action: () {
        return _runQueued<MemorySlmResponse<String>>(() async {
          await initialize();
          final stopwatch = Stopwatch()..start();
          _setCache(_upgradeReasonCache, cacheKey, fallback);
          stopwatch.stop();
          return MemorySlmResponse<String>(
            success: true,
            data: fallback,
            fallbackUsed: MemorySlmFallbackMode.rules,
            latencyMs: stopwatch.elapsedMilliseconds,
            errorCode: 'slm_rule_mode',
          );
        });
      },
    );
  }

  Future<MemorySlmResponse<MemorySlmSummaryMetadata>> generateSummaryMetadata({
    String title = '',
    required String content,
    List<String> tags = const [],
  }) async {
    final slmConfig = await _loadSlmConfig();
    final locale = await _resolvePreferredLocale();
    final localizations = lookupAppLocalizations(locale);
    final fallback = _generateSummaryMetadataFallback(
      title: title,
      content: content,
      tags: tags,
      localizations: localizations,
      slmConfig: slmConfig,
    );

    try {
      return await _runQueued<MemorySlmResponse<MemorySlmSummaryMetadata>>(
        () async {
          await initialize();
          final stopwatch = Stopwatch()..start();
          stopwatch.stop();
          return MemorySlmResponse<MemorySlmSummaryMetadata>(
            success: true,
            data: fallback,
            fallbackUsed: MemorySlmFallbackMode.rules,
            latencyMs: stopwatch.elapsedMilliseconds,
            errorCode: 'slm_rule_mode',
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint(
        '⚠️ [MemorySLMService] generateSummaryMetadata failed, returning the minimal fallback result: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return MemorySlmResponse<MemorySlmSummaryMetadata>(
        success: true,
        data: fallback,
        fallbackUsed: MemorySlmFallbackMode.disabled,
        latencyMs: 0,
        errorCode: 'summary_metadata_failed',
      );
    }
  }

  Future<void> dispose() async {
    _topicCache.clear();
    _upgradeReasonCache.clear();
    _slmConfig = null;
    _isInitialized = false;
  }

  Future<T> _runQueued<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final requestEnqueuedAt = DateTime.now();

    _requestQueue = _requestQueue.catchError((Object _) {}).then((_) async {
      final slmConfig = _effectiveSlmConfig;
      final queuedFor = DateTime.now().difference(requestEnqueuedAt);
      if (queuedFor > slmConfig.maxQueueWait) {
        completer.completeError(
          TimeoutException(
            'SLM request queue timeout',
            slmConfig.maxQueueWait,
          ),
        );
        return;
      }

      try {
        final result = await action().timeout(slmConfig.requestTimeout);
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }
    });

    return completer.future;
  }

  Future<MemorySlmResponse<T>> _runWithFallback<T>({
    required String operation,
    required T fallbackData,
    required String errorCode,
    required Future<MemorySlmResponse<T>> Function() action,
  }) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      debugPrint(
          '⚠️ [MemorySLMService] $operation failed, falling back to rule-based mode: $error');
      debugPrintStack(stackTrace: stackTrace);
      return MemorySlmResponse<T>(
        success: true,
        data: fallbackData,
        fallbackUsed: MemorySlmFallbackMode.rules,
        latencyMs: 0,
        errorCode: errorCode,
      );
    }
  }

  String _extractFileExtension(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    final lastDotIndex = normalized.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == normalized.length - 1) {
      return '';
    }
    return normalized.substring(lastDotIndex + 1);
  }

  Future<void> _ensureRuntimeSlmInferencePreferenceLoaded() async {
    if (_runtimeSlmInferenceEnabledLoaded) {
      return;
    }

    final pending = _runtimeSlmInferenceEnabledLoading;
    if (pending != null) {
      return pending;
    }

    final loading = _loadRuntimeSlmInferencePreference();
    _runtimeSlmInferenceEnabledLoading = loading;
    await loading;
  }

  Future<void> _loadRuntimeSlmInferencePreference() async {
    try {
      _runtimeSlmInferenceEnabled =
          await _settingsService.isSlmInferenceEnabled();
      _runtimeSlmInferenceEnabledLoaded = true;
    } finally {
      _runtimeSlmInferenceEnabledLoading = null;
    }
  }

  MemorySlmSummaryMetadata _generateSummaryMetadataFallback({
    required String title,
    required String content,
    required List<String> tags,
    required AppLocalizations localizations,
    required MemorySlmConfig slmConfig,
  }) {
    final explicitTitle = title.trim();
    final generatedTitle = SummaryTextUtils.generateTitle(content).trim();
    final resolvedTitle = explicitTitle.isNotEmpty
        ? explicitTitle
        : generatedTitle.isNotEmpty &&
                !SummaryTextUtils.isUnnamedTitleValue(generatedTitle)
            ? generatedTitle
            : localizations.pendingSummary;

    final explicitTags =
        tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
    final resolvedTags = explicitTags.isNotEmpty
        ? explicitTags.take(slmConfig.limits.summaryMetadataTagCount).toList()
        : SummaryTextUtils.generateTags(
            resolvedTitle,
            content,
            maxTags: slmConfig.limits.summaryMetadataTagCount,
          );

    return MemorySlmSummaryMetadata(
      title: resolvedTitle,
      tags: resolvedTags,
    );
  }

  List<_RuleSemanticCandidate> _collectSemanticCandidates({
    required String title,
    required String content,
    required List<String> tags,
    required String canonicalTopic,
    required AppLocalizations localizations,
  }) {
    final normalizedTitle = title.trim();
    final normalizedContent = content.trim();
    final canonicalKey = _normalizeText(canonicalTopic);
    final candidates = <String, _RuleSemanticCandidate>{};

    void addCandidate(
      String raw,
      double baseScore, {
      bool fromTitle = false,
      bool fromTemplate = false,
      bool fromExplicitTag = false,
    }) {
      final normalizedCandidate = _normalizeSemanticFacetCandidate(
        raw,
        content,
        canonicalTopic: canonicalTopic,
        localizations: localizations,
      );
      if (!_isMeaningfulRuleTopic(normalizedCandidate)) {
        return;
      }

      var score = baseScore;
      final lowerRaw = raw.toLowerCase();
      final lowerCandidate = normalizedCandidate.toLowerCase();
      final lowerTitle = normalizedTitle.toLowerCase();
      final lowerFullText = '$normalizedTitle $normalizedContent'.toLowerCase();

      if (lowerTitle.contains(lowerRaw) ||
          lowerTitle.contains(lowerCandidate)) {
        score += 3.0;
      }

      final lowerToken = lowerCandidate.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (lowerToken.isNotEmpty && lowerFullText.contains(lowerToken)) {
        score += _countPlainOccurrences(lowerFullText, lowerToken).toDouble();
      }

      score += _topicLengthScore(normalizedCandidate) / 2;

      if (fromExplicitTag) {
        score += 2.0;
      }

      if (fromTemplate || _looksLikeTemplateTopic(normalizedCandidate)) {
        score += 1.5;
      }

      if (_isCanonicalRuleTopic(lowerCandidate)) {
        score -= canonicalKey.isEmpty ? 0.5 : 1.0;
      }

      if (canonicalKey.isNotEmpty &&
          _normalizeText(normalizedCandidate) == canonicalKey) {
        score -= 2.5;
      }

      candidates.update(
        normalizedCandidate,
        (previous) => previous.score >= score
            ? previous
            : previous.copyWith(score: score),
        ifAbsent: () => _RuleSemanticCandidate(
          label: normalizedCandidate,
          normalizedKey: _normalizeText(normalizedCandidate),
          score: score,
          fromTitle: fromTitle,
          fromTemplate: fromTemplate,
          fromExplicitTag: fromExplicitTag,
        ),
      );
    }

    for (final match in _extractTemplateTopicMatches(normalizedTitle)) {
      addCandidate(match, 14.0, fromTitle: true, fromTemplate: true);
    }
    for (final match in _extractTemplateTopicMatches(normalizedContent)) {
      addCandidate(match, 9.0, fromTemplate: true);
    }

    if (normalizedTitle.isNotEmpty) {
      addCandidate(SummaryTextUtils.compressTitle(normalizedTitle), 7.0,
          fromTitle: true);
      addCandidate(normalizedTitle, 5.5, fromTitle: true);
    }
    addCandidate(SummaryTextUtils.generateTitle(normalizedContent), 6.5);
    addCandidate(
      SummaryTextUtils.generateTitle('$normalizedTitle\n$normalizedContent'),
      6.0,
      fromTitle: normalizedTitle.isNotEmpty,
    );

    final seedTitle = normalizedTitle.isNotEmpty
        ? normalizedTitle
        : SummaryTextUtils.generateTitle(normalizedContent);
    for (final tag in tags) {
      addCandidate(tag, 10.0, fromExplicitTag: true);
    }
    for (final tag in SummaryTextUtils.generateTags(
      seedTitle,
      normalizedContent,
      maxTags: 4,
    )) {
      addCandidate(tag, 8.0, fromTitle: normalizedTitle.contains(tag));
    }

    final ranked = candidates.values.toList()
      ..sort((left, right) {
        final scoreDiff = right.score.compareTo(left.score);
        if (scoreDiff != 0) {
          return scoreDiff;
        }
        final rightInTitle =
            _candidateAppearsInTitle(right.label, normalizedTitle);
        final leftInTitle =
            _candidateAppearsInTitle(left.label, normalizedTitle);
        final titleDiff = (rightInTitle ? 1 : 0) - (leftInTitle ? 1 : 0);
        if (titleDiff != 0) {
          return titleDiff;
        }
        final rightTemplate = _looksLikeTemplateTopic(right.label);
        final leftTemplate = _looksLikeTemplateTopic(left.label);
        final templateDiff = (rightTemplate ? 1 : 0) - (leftTemplate ? 1 : 0);
        if (templateDiff != 0) {
          return templateDiff;
        }
        final lengthDiff = _topicLengthScore(right.label)
            .compareTo(_topicLengthScore(left.label));
        if (lengthDiff != 0) {
          return lengthDiff;
        }
        return left.label.length.compareTo(right.label.length);
      });

    return ranked;
  }

  _RuleSemanticCandidate? _pickBestSemanticFacet(
    List<_RuleSemanticCandidate> candidates, {
    required String canonicalKey,
  }) {
    for (final candidate in candidates) {
      if (candidate.normalizedKey != canonicalKey) {
        return candidate;
      }
    }
    return candidates.isEmpty ? null : candidates.first;
  }

  String _renderSemanticTopic({
    required String title,
    required String content,
    required String canonicalTopic,
    required String facet,
    required AppLocalizations localizations,
  }) {
    if (canonicalTopic.isNotEmpty && facet.isNotEmpty) {
      var rendered = _isContainedTopic(
        _normalizeText(facet),
        _normalizeText(canonicalTopic),
      )
          ? facet
          : '$canonicalTopic $facet';
      rendered = SummaryTextUtils.compressTitle(rendered);
      if (_isSemanticTopicTooLong(rendered)) {
        final shortenedFacet = SummaryTextUtils.generateTags(
          canonicalTopic,
          content,
          maxTags: 4,
        ).firstWhere(
          (candidate) =>
              _normalizeText(candidate) != _normalizeText(canonicalTopic) &&
              _isMeaningfulRuleTopic(candidate),
          orElse: () => '',
        );
        if (shortenedFacet.isNotEmpty) {
          final compact = SummaryTextUtils.compressTitle(
            '$canonicalTopic $shortenedFacet',
          );
          if (!_isSemanticTopicTooLong(compact)) {
            return compact;
          }
        }
        return canonicalTopic;
      }
      return rendered;
    }
    if (facet.isNotEmpty) {
      return SummaryTextUtils.compressTitle(facet);
    }
    if (canonicalTopic.isNotEmpty) {
      return canonicalTopic;
    }

    final fallbackSeed =
        title.trim().isNotEmpty ? title.trim() : content.trim();
    return _normalizeFallbackTopicCandidate(
      fallbackSeed,
      content,
      localizations: localizations,
    );
  }

  String _renderSemanticTitle({
    required String title,
    required String content,
    required String canonicalTopic,
    required String facet,
    required String displayTopic,
  }) {
    final explicitTitle =
        title.contains('\n') ? '' : SummaryTextUtils.compressTitle(title);
    final generatedTitle = SummaryTextUtils.generateTitle('$title\n$content');
    final candidates = <String>[
      if (_isReusableSemanticTitle(
        explicitTitle,
        canonicalTopic: canonicalTopic,
        facet: facet,
      ))
        explicitTitle,
      if (displayTopic.trim().isNotEmpty) displayTopic,
      if (_isReusableSemanticTitle(
        generatedTitle,
        canonicalTopic: canonicalTopic,
        facet: facet,
      ))
        generatedTitle,
      if (canonicalTopic.isNotEmpty) canonicalTopic,
      SummaryTextUtils.generateTitle(content),
    ];

    for (final candidate in candidates) {
      final normalized = SummaryTextUtils.compressTitle(candidate);
      if (_isMeaningfulRuleTopic(normalized) ||
          _isCanonicalRuleTopic(_normalizeText(normalized))) {
        return normalized;
      }
    }

    return displayTopic.trim().isNotEmpty
        ? displayTopic
        : SummaryTextUtils.generateTitle(content);
  }

  List<String> _buildSemanticTags({
    required String title,
    required String content,
    required String canonicalTopic,
    required String facet,
    required List<String> explicitTags,
  }) {
    final combinedTags = <String>[
      ...explicitTags,
      if (canonicalTopic.isNotEmpty) canonicalTopic,
      if (facet.isNotEmpty) facet,
      ...SummaryTextUtils.generateTags(
        title,
        content,
        maxTags: _effectiveSlmConfig.limits.summaryMetadataTagCount,
      ),
    ];

    return SummaryTextUtils.sanitizeTags(
      combinedTags,
      maxTags: _effectiveSlmConfig.limits.summaryMetadataTagCount,
      fallbackTitle: title,
    );
  }

  List<String> _collectSemanticKeywords({
    required String displayTopic,
    required String displayTitle,
    required String canonicalTopic,
    required String facet,
    required List<String> tags,
    required String content,
  }) {
    final keywords = <String>{
      if (canonicalTopic.isNotEmpty) canonicalTopic,
      if (facet.isNotEmpty) facet,
      if (displayTopic.isNotEmpty) displayTopic,
      if (displayTitle.isNotEmpty) displayTitle,
      ...tags,
      ...SummaryTextUtils.generateTags(
        displayTitle,
        content,
        maxTags: _effectiveSlmConfig.limits.summaryMetadataTagCount,
      ),
    };

    return keywords
        .map((keyword) => SummaryTextUtils.compressTitle(keyword))
        .where((keyword) => keyword.isNotEmpty)
        .toList(growable: false);
  }

  double _estimateSemanticConfidence({
    required String canonicalTopic,
    required _RuleSemanticCandidate? bestFacet,
    required String displayTopic,
    required List<String> tags,
    required String title,
  }) {
    var confidence = 0.2;
    if (canonicalTopic.isNotEmpty) {
      confidence += 0.2;
    }
    if (bestFacet != null) {
      confidence += min(0.35, bestFacet.score / 40);
    }
    if (_candidateAppearsInTitle(displayTopic, title)) {
      confidence += 0.1;
    }
    if (tags.isNotEmpty) {
      confidence += 0.1;
    }
    return confidence.clamp(0.0, 1.0);
  }

  String _normalizeSemanticFacetCandidate(
    String candidate,
    String content, {
    required String canonicalTopic,
    required AppLocalizations localizations,
  }) {
    var normalized = SummaryTextUtils.compressTitle(candidate).trim();
    if (normalized.isEmpty ||
        SummaryTextUtils.isUnnamedTitleValue(normalized) ||
        TopicPlaceholderUtils.isPlaceholderTopic(normalized)) {
      return '';
    }

    normalized =
        TopicPlaceholderUtils.stripLeadingPlaceholder(normalized).trim();
    if (canonicalTopic.isNotEmpty) {
      normalized = normalized
          .replaceFirst(
            RegExp(
              '^${RegExp.escape(canonicalTopic)}(?:\\s+|(?=[\\u4E00-\\u9FFF\\u3040-\\u30FF\\uAC00-\\uD7AF]))',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
    }

    if (normalized.isEmpty) {
      return canonicalTopic.isNotEmpty
          ? canonicalTopic
          : _normalizeFallbackTopicCandidate(
              content,
              content,
              localizations: localizations,
            );
    }

    return _normalizeFallbackTopicCandidate(
      normalized,
      content,
      localizations: localizations,
    );
  }

  bool _isReusableSemanticTitle(
    String title, {
    required String canonicalTopic,
    required String facet,
  }) {
    final normalized = title.trim();
    if (normalized.isEmpty ||
        SummaryTextUtils.isUnnamedTitleValue(normalized) ||
        TopicPlaceholderUtils.isPlaceholderTopic(normalized)) {
      return false;
    }
    if (canonicalTopic.isNotEmpty &&
        facet.isNotEmpty &&
        _normalizeText(normalized) == _normalizeText(canonicalTopic)) {
      return false;
    }
    return true;
  }

  bool _isSemanticTopicTooLong(String topic) {
    if (_detectPrimaryLanguage(topic) == _PrimaryLanguage.cjk) {
      return topic.length > 14;
    }
    final wordCount =
        topic.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    return wordCount > 4;
  }

  bool _isContainedTopic(String left, String right) {
    if (left.isEmpty || right.isEmpty) {
      return false;
    }
    if (left == right) {
      return true;
    }
    final shorter = left.length <= right.length ? left : right;
    final longer = shorter == left ? right : left;
    return shorter.length >= 3 && longer.contains(shorter);
  }

  AppLocalizations _fallbackLocalizationsForText(String text) {
    return lookupAppLocalizations(_detectLocaleForText(text));
  }

  ui.Locale _detectLocaleForText(String text) {
    if (RegExp(r'[\uAC00-\uD7AF]').hasMatch(text)) {
      return const ui.Locale('ko');
    }
    if (RegExp(r'[\u3040-\u30FF]').hasMatch(text)) {
      return const ui.Locale('ja');
    }
    if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(text)) {
      return const ui.Locale('zh');
    }
    if (_latinScriptRegex.hasMatch(text)) {
      return const ui.Locale('en');
    }
    return _supportedLocale(ui.PlatformDispatcher.instance.locale);
  }

  String? _extractCanonicalTopicAlias(String title, String content) {
    final normalized = '$title $content'.toLowerCase();

    if (RegExp(r'\brag\b').hasMatch(normalized) ||
        _containsAnyAlias(normalized, _ragDirectAliases)) {
      return 'RAG';
    }

    final ragSignalCount =
        _countMatchingSignals(normalized, _ragSecondarySignals);
    if (ragSignalCount >= 2) {
      return 'RAG';
    }

    if (RegExp(r'\bllm\b').hasMatch(normalized) ||
        _containsAnyAlias(normalized, _llmAliases)) {
      return 'LLM';
    }
    if (RegExp(r'\bslm\b').hasMatch(normalized) ||
        _containsAnyAlias(normalized, _slmAliases)) {
      return 'SLM';
    }
    if (RegExp(r'\bocr\b').hasMatch(normalized) ||
        _containsAnyAlias(normalized, _ocrAliases)) {
      return 'OCR';
    }

    return null;
  }

  MemorySlmMergeResult _mergeSessionsFallback(List<SummaryEntity> sessions) {
    if (sessions.isEmpty) {
      return MemorySlmMergeResult(
        title: _effectiveSlmConfig.fallbacks.emptyFactTitle,
        content: '',
        tags: <String>[],
      );
    }

    final orderedSessions = List<SummaryEntity>.from(sessions)
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    final mergeUnits = _extractStructuredMergeUnits(orderedSessions);
    final mergedContent = _buildStructuredMergeContent(mergeUnits);
    final mergedProfile = describeBatchSemantics(orderedSessions);
    final mergedTitle = mergedProfile.displayTitle.trim().isEmpty
        ? _effectiveSlmConfig.fallbacks.emptyFactTitle
        : mergedProfile.displayTitle;
    final mergedTags = _buildMergedSessionTags(
      orderedSessions,
      title: mergedTitle,
      topic: mergedProfile.displayTopic,
      content: mergedContent,
    );

    return MemorySlmMergeResult(
      title: mergedTitle,
      content: mergedContent,
      tags: mergedTags,
    );
  }

  List<String> _extractStructuredMergeUnits(List<SummaryEntity> sessions) {
    final units = <String>[];

    for (final session in sessions) {
      final rawSegments = session.content
          .split(RegExp(r'\n+|(?<=[。！？!?；;])\s*'))
          .map(_normalizeMergeUnit)
          .where((segment) => segment.isNotEmpty);

      for (final segment in rawSegments) {
        if (_isDuplicateMergeUnit(segment, units)) {
          continue;
        }
        units.add(segment);
      }
    }

    if (units.isNotEmpty) {
      return units;
    }

    return sessions
        .map((session) => _normalizeMergeUnit(session.content))
        .where((segment) => segment.isNotEmpty)
        .toList();
  }

  String _normalizeMergeUnit(String raw) {
    return raw
        .trim()
        .replaceFirst(RegExp(r'^[-*•\d.)(一二三四五六七八九十、\s]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[。；;]+$'), '')
        .trim();
  }

  bool _isDuplicateMergeUnit(String candidate, List<String> existingUnits) {
    final normalizedCandidate = _normalizeText(candidate);
    if (normalizedCandidate.isEmpty) {
      return true;
    }

    for (final existing in existingUnits) {
      final normalizedExisting = _normalizeText(existing);
      if (normalizedExisting == normalizedCandidate ||
          normalizedExisting.contains(normalizedCandidate) ||
          normalizedCandidate.contains(normalizedExisting)) {
        return true;
      }

      if (SimilarityUtils.jaccardSimilarity(existing, candidate) >= 0.92) {
        return true;
      }
    }

    return false;
  }

  String _buildStructuredMergeContent(List<String> units) {
    if (units.isEmpty) {
      return '';
    }

    final paragraphs = <String>[];
    final currentUnits = <String>[];
    var currentLength = 0;
    final separator =
        _detectPrimaryLanguage(units.join(' ')) == _PrimaryLanguage.cjk
            ? '；'
            : '; ';

    void flush() {
      if (currentUnits.isEmpty) {
        return;
      }
      paragraphs.add(currentUnits.join(separator));
      currentUnits.clear();
      currentLength = 0;
    }

    for (final unit in units) {
      final extraLength =
          currentUnits.isEmpty ? unit.length : unit.length + separator.length;
      final shouldFlush =
          currentUnits.length >= 2 || (currentLength + extraLength) > 120;
      if (shouldFlush) {
        flush();
      }

      currentUnits.add(unit);
      currentLength += extraLength;

      if (paragraphs.length >= 2 && currentUnits.length >= 2) {
        flush();
      }
    }
    flush();

    final merged = paragraphs.take(3).join('\n\n').trim();
    if (merged.length <= 300) {
      return merged;
    }
    return '${merged.substring(0, 297).trim()}...';
  }

  List<String> _buildMergedSessionTags(
    List<SummaryEntity> sessions, {
    required String title,
    required String topic,
    required String content,
  }) {
    final combinedTags = <String>[
      ...sessions.expand((session) => session.tags),
      if (_isMeaningfulRuleTopic(topic)) topic,
      ...SummaryTextUtils.generateTags(
        title,
        content,
        maxTags: _effectiveSlmConfig.limits.mergeResultTagCount,
      ),
    ];

    return SummaryTextUtils.sanitizeTags(
      combinedTags,
      maxTags: _effectiveSlmConfig.limits.mergeResultTagCount,
      fallbackTitle: SummaryTextUtils.isUnnamedTitleValue(title) ? null : title,
    );
  }

  Future<String> _generateUpgradeReasonFallback(
    SummaryEntity fact, {
    ui.Locale? locale,
  }) async {
    final targetLocale = locale ?? await _resolvePreferredLocale();
    final slmConfig = _effectiveSlmConfig;
    final localizations = await AppLocalizations.delegate.load(targetLocale);
    if (fact.accessCount >= slmConfig.heuristics.upgradeAccessCountThreshold) {
      return localizations.upgradeReasonHighAccess;
    }
    if (fact.importance >= slmConfig.heuristics.upgradeImportanceThreshold) {
      return localizations.upgradeReasonHighImportance;
    }
    return localizations.defaultPromotionReason;
  }

  Future<ui.Locale> _resolvePreferredLocale() async {
    final appLocale = await LocaleManager.loadLocale();
    final savedLocale = LocaleManager.getLocale(appLocale);
    if (savedLocale != null) {
      return _supportedLocale(savedLocale);
    }
    return _supportedLocale(ui.PlatformDispatcher.instance.locale);
  }

  ui.Locale _supportedLocale(ui.Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return const ui.Locale('zh');
      case 'ja':
        return const ui.Locale('ja');
      case 'ko':
        return const ui.Locale('ko');
      case 'es':
        return const ui.Locale('es');
      case 'fr':
        return const ui.Locale('fr');
      case 'de':
        return const ui.Locale('de');
      default:
        return const ui.Locale('en');
    }
  }

  String _fallbackCjkTopic(String input, {required AppLocalizations loc}) {
    final slmConfig = _effectiveSlmConfig;
    final cleaned = input.replaceAll(
      RegExp(r'[^\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF0-9A-Za-z]'),
      '',
    );
    if (cleaned.isEmpty) {
      return loc.temporaryTopic;
    }
    final take = cleaned.length >= slmConfig.limits.fallbackChineseTopicChars
        ? slmConfig.limits.fallbackChineseTopicChars
        : cleaned.length
            .clamp(
              slmConfig.limits.topicChineseMinChars,
              slmConfig.limits.fallbackChineseTopicChars,
            )
            .toInt();
    return cleaned.substring(0, take);
  }

  String _fallbackEnglishTopic(String input, {required AppLocalizations loc}) {
    final slmConfig = _effectiveSlmConfig;
    final words = input
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.replaceAll(
            RegExp(r'[^A-Za-zÀ-ÖØ-öø-ÿĀ-žẞß0-9]'),
            '',
          ),
        )
        .where((word) => word.isNotEmpty)
        .take(slmConfig.limits.topicEnglishWordCount)
        .toList();
    if (words.isEmpty) {
      return loc.generalTopic;
    }
    return words.join(' ');
  }

  String _normalizeFallbackTopicCandidate(
    String candidate,
    String content, {
    required AppLocalizations localizations,
  }) {
    final trimmed = candidate.trim();
    final strippedPlaceholder = TopicPlaceholderUtils.stripLeadingPlaceholder(
      trimmed,
    );
    if (trimmed.isEmpty ||
        SummaryTextUtils.isUnnamedTitleValue(trimmed) ||
        TopicPlaceholderUtils.isPlaceholderTopic(trimmed)) {
      final language = _detectPrimaryLanguage(content);
      return language == _PrimaryLanguage.cjk
          ? _fallbackCjkTopic(content, loc: localizations)
          : _fallbackEnglishTopic(content, loc: localizations);
    }

    final language = _detectPrimaryLanguage(strippedPlaceholder);
    if (language == _PrimaryLanguage.cjk) {
      final cleaned = strippedPlaceholder
          .replaceAll(
            RegExp(r'[^\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AFA-Za-z0-9]'),
            '',
          )
          .trim();
      if (cleaned.isEmpty) {
        return _fallbackCjkTopic(content, loc: localizations);
      }
      final maxLength = _effectiveSlmConfig.limits.topicChineseMaxChars;
      return cleaned.length > maxLength
          ? cleaned.substring(0, maxLength)
          : cleaned;
    }

    final words = strippedPlaceholder
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(_effectiveSlmConfig.limits.topicEnglishWordCount)
        .toList();
    if (words.isEmpty) {
      return _fallbackEnglishTopic(content, loc: localizations);
    }
    return words.join(' ');
  }

  _PrimaryLanguage _detectPrimaryLanguage(String text) {
    final cjkMatches = RegExp(r'[\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF]')
        .allMatches(text)
        .length;
    final latinMatches = _latinScriptRegex.allMatches(text).length;
    return cjkMatches >= latinMatches
        ? _PrimaryLanguage.cjk
        : _PrimaryLanguage.english;
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(
          RegExp(
            r'[^A-Za-zÀ-ÖØ-öø-ÿĀ-žẞß0-9_\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF ]',
          ),
          '',
        )
        .trim();
  }

  bool _containsAnyAlias(String normalized, Set<String> aliases) {
    return aliases.any(normalized.contains);
  }

  int _countMatchingSignals(String normalized, Iterable<Pattern> patterns) {
    return patterns
        .where(
          (pattern) => pattern is String
              ? normalized.contains(pattern)
              : (pattern as RegExp).hasMatch(normalized),
        )
        .length;
  }

  Iterable<String> _extractTemplateTopicMatches(String text) sync* {
    if (text.trim().isEmpty) {
      return;
    }

    final seen = <String>{};
    for (final suffix in _cjkTopicTemplateSuffixes) {
      final pattern = RegExp(
        '[\\u4E00-\\u9FFF\\u3040-\\u30FF\\uAC00-\\uD7AFA-Za-z0-9]{2,18}'
        '${RegExp.escape(suffix)}',
      );
      for (final match in pattern.allMatches(text)) {
        final value = match.group(0)?.trim();
        if (value != null && value.isNotEmpty && seen.add(value)) {
          yield value;
        }
      }
    }

    final latinPattern = RegExp(
      '\\b(?:[A-Za-zÀ-ÖØ-öø-ÿĀ-žẞß0-9]+(?:\\s+[A-Za-zÀ-ÖØ-öø-ÿĀ-žẞß0-9]+){0,3})\\s+'
      '(?:${_latinTopicTemplateSuffixes.join('|')})\\b',
      caseSensitive: false,
    );
    for (final match in latinPattern.allMatches(text)) {
      final value = match.group(0)?.trim();
      if (value != null && value.isNotEmpty && seen.add(value)) {
        yield value;
      }
    }
  }

  bool _looksLikeTemplateTopic(String candidate) {
    final lower = candidate.toLowerCase();
    return _cjkTopicTemplateSuffixes.any(candidate.endsWith) ||
        _latinTopicTemplateSuffixes.any(lower.endsWith);
  }

  bool _isMeaningfulRuleTopic(String candidate) {
    final normalized = candidate.trim();
    if (normalized.isEmpty ||
        SummaryTextUtils.isUnnamedTitleValue(normalized) ||
        TopicPlaceholderUtils.isPlaceholderTopic(normalized)) {
      return false;
    }

    if (_genericTopicKeywords.contains(normalized.toLowerCase()) ||
        _genericTopicKeywords.contains(normalized)) {
      return false;
    }

    if (_detectPrimaryLanguage(normalized) == _PrimaryLanguage.cjk) {
      return normalized.length >= 2 && normalized.length <= 16;
    }

    final words = normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    return words.isNotEmpty && words.length <= 4;
  }

  bool _isCanonicalRuleTopic(String topic) {
    return switch (topic) {
      'rag' || 'llm' || 'slm' || 'ocr' => true,
      _ => false,
    };
  }

  bool _candidateAppearsInTitle(String candidate, String title) {
    if (title.trim().isEmpty) {
      return false;
    }
    final lowerCandidate = candidate.toLowerCase();
    final lowerTitle = title.toLowerCase();
    return lowerTitle.contains(lowerCandidate);
  }

  int _topicLengthScore(String candidate) {
    if (_detectPrimaryLanguage(candidate) == _PrimaryLanguage.cjk) {
      final delta = (candidate.length - 6).abs();
      return -delta;
    }

    final wordCount =
        candidate.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    final delta = (wordCount - 2).abs();
    return -delta;
  }

  int _countPlainOccurrences(String haystack, String needle) {
    if (needle.isEmpty || haystack.isEmpty) {
      return 0;
    }

    var count = 0;
    var cursor = 0;
    while (true) {
      final next = haystack.indexOf(needle, cursor);
      if (next == -1) {
        return count;
      }
      count += 1;
      cursor = next + needle.length;
    }
  }

  void _setCache(
    LinkedHashMap<String, String> cache,
    String key,
    String value,
  ) {
    cache.remove(key);
    cache[key] = value;
    while (cache.length > _effectiveSlmConfig.runtime.maxCacheEntries) {
      cache.remove(cache.keys.first);
    }
  }

  MemorySlmConfig get _effectiveSlmConfig =>
      _slmConfig?.withRuntimeOverrides(
        requestTimeout: _configuration.requestTimeout,
        maxQueueWait: _configuration.maxQueueWait,
        maxCacheEntries: _configuration.maxCacheEntries,
        maxTokens: _configuration.maxTokens,
        temperature: _configuration.temperature,
        topK: _configuration.topK,
      ) ??
      MemorySlmConfig.fallback.withRuntimeOverrides(
        requestTimeout: _configuration.requestTimeout,
        maxQueueWait: _configuration.maxQueueWait,
        maxCacheEntries: _configuration.maxCacheEntries,
        maxTokens: _configuration.maxTokens,
        temperature: _configuration.temperature,
        topK: _configuration.topK,
      );

  Future<MemorySlmConfig> _loadSlmConfig() async {
    final cached = _slmConfig;
    if (cached != null) {
      return cached;
    }

    final loading = _slmConfigLoading;
    if (loading != null) {
      return loading;
    }

    _slmConfigLoading = _loadSlmConfigInternal();
    return _slmConfigLoading!;
  }

  Future<MemorySlmConfig> _loadSlmConfigInternal() async {
    try {
      final loaded = await MemorySlmConfig.load();
      final resolved = loaded.withRuntimeOverrides(
        requestTimeout: _configuration.requestTimeout,
        maxQueueWait: _configuration.maxQueueWait,
        maxCacheEntries: _configuration.maxCacheEntries,
        maxTokens: _configuration.maxTokens,
        temperature: _configuration.temperature,
        topK: _configuration.topK,
      );
      _slmConfig = resolved;
      return resolved;
    } catch (error, stackTrace) {
      debugPrint(
          '⚠️ [MemorySLMService] Failed to load SLM config, falling back to defaults: $error');
      debugPrintStack(stackTrace: stackTrace);
      final fallback = _effectiveSlmConfig;
      _slmConfig = fallback;
      return fallback;
    } finally {
      _slmConfigLoading = null;
    }
  }
}

enum _PrimaryLanguage {
  cjk,
  english,
}

class _RuleSemanticCandidate {
  const _RuleSemanticCandidate({
    required this.label,
    required this.normalizedKey,
    required this.score,
    required this.fromTitle,
    required this.fromTemplate,
    required this.fromExplicitTag,
  });

  final String label;
  final String normalizedKey;
  final double score;
  final bool fromTitle;
  final bool fromTemplate;
  final bool fromExplicitTag;

  _RuleSemanticCandidate copyWith({
    double? score,
  }) {
    return _RuleSemanticCandidate(
      label: label,
      normalizedKey: normalizedKey,
      score: score ?? this.score,
      fromTitle: fromTitle,
      fromTemplate: fromTemplate,
      fromExplicitTag: fromExplicitTag,
    );
  }
}
