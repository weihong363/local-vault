import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, PlatformException;
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/services/memory_slm_config.dart';
import 'package:mediapipe_genai/mediapipe_genai.dart';
import 'package:path_provider/path_provider.dart';

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
  }) : _configuration = configuration;

  final MemorySlmConfiguration _configuration;

  static const MethodChannel _modelAssetChannel =
      MethodChannel('local_vault/model_assets');
  static const bool _experimentalNativeInferenceEnabled = bool.fromEnvironment(
    'ENABLE_MEDIAPIPE_SLM',
    defaultValue: false,
  );
  static const String _nativeInferenceFlagName = 'ENABLE_MEDIAPIPE_SLM';

  final LinkedHashMap<String, String> _topicCache = LinkedHashMap();
  final LinkedHashMap<String, String> _upgradeReasonCache = LinkedHashMap();

  Future<void>? _initializing;
  bool _isInitialized = false;
  bool _isModelAvailable = false;
  Future<void> _requestQueue = Future<void>.value();
  bool? _nativeSymbolsAvailable;
  MemorySlmConfig? _slmConfig;
  Future<MemorySlmConfig>? _slmConfigLoading;

  LlmInferenceEngine? _engine;

  bool get isInitialized => _isInitialized;

  bool get isModelAvailable => _isModelAvailable;

  Future<MemorySlmConfig> resolveConfig() => _loadSlmConfig();

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
      await _loadSlmConfig();
      if (!_supportsNativeInference) {
        _isInitialized = true;
        _isModelAvailable = false;
        debugPrint(
          'ℹ️ [MemorySLMService] 当前构建未启用可用的 MediaPipe 原生推理，'
          '已使用规则模式回退。'
          '${_experimentalNativeInferenceEnabled ? '' : ' 如需实验性启用，请添加 --dart-define=$_nativeInferenceFlagName=true。'}',
        );
        return;
      }

      final modelFile = await _resolveModelFile();
      if (!await modelFile.exists()) {
        final copied = await _tryCopyBundledModel(
          modelFile,
          onProgress: onProgress,
        );
        if (!copied) {
          debugPrint(
            'ℹ️ [MemorySLMService] 未找到内置模型资源 '
            '${_effectiveSlmConfig.model.bundledAssetPath}，已回退到规则模式。',
          );
        }
      }

      await _initializeEngineIfSupported(modelFile);
      _isInitialized = true;
      debugPrint(
        '🧠 [MemorySLMService] 初始化完成，SLM${_isModelAvailable ? '可用' : '已回退到规则模式'}',
      );
    } catch (error, stackTrace) {
      _isInitialized = true;
      _isModelAvailable = false;
      debugPrint('⚠️ [MemorySLMService] 初始化失败，已启用降级模式: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _initializing = null;
    }
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

    final fallbackTopic = _extractTopicFallback(title, content);
    return _runWithFallback<String>(
      operation: 'extractTopic',
      fallbackData: fallbackTopic,
      errorCode: 'extract_topic_failed',
      action: () {
        return _runQueued<MemorySlmResponse<String>>(() async {
          await initialize();
          final stopwatch = Stopwatch()..start();
          final prompt = _buildTopicPrompt(title, content);
          final generated = await _runModelPrompt(prompt);
          final topic = _sanitizeTopicResponse(generated, fallbackTopic);
          _setCache(_topicCache, cacheKey, topic);
          stopwatch.stop();
          final usedModel = generated != null && generated.trim().isNotEmpty;
          return MemorySlmResponse<String>(
            success: true,
            data: topic,
            fallbackUsed: usedModel
                ? MemorySlmFallbackMode.none
                : MemorySlmFallbackMode.rules,
            latencyMs: stopwatch.elapsedMilliseconds,
            errorCode: usedModel ? null : 'slm_model_unavailable',
          );
        });
      },
    );
  }

  Future<MemorySlmResponse<bool>> isSameTopic(
    SummaryEntity entityA,
    SummaryEntity entityB,
  ) async {
    final fallback = _isSameTopicFallback(entityA, entityB);
    return _runWithFallback<bool>(
      operation: 'isSameTopic',
      fallbackData: fallback,
      errorCode: 'same_topic_failed',
      action: () {
        return _runQueued<MemorySlmResponse<bool>>(() async {
          await initialize();
          final stopwatch = Stopwatch()..start();
          final prompt = _buildSameTopicPrompt(entityA, entityB);
          final generated = await _runModelPrompt(prompt);
          final parsed = _parseYesNo(generated);
          stopwatch.stop();
          final usedModel = parsed != null;
          return MemorySlmResponse<bool>(
            success: true,
            data: parsed ?? fallback,
            fallbackUsed: usedModel
                ? MemorySlmFallbackMode.none
                : MemorySlmFallbackMode.rules,
            latencyMs: stopwatch.elapsedMilliseconds,
            errorCode: usedModel ? null : 'slm_model_unavailable',
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
          final prompt = _buildMergePrompt(sessions);
          final generated = await _runModelPrompt(prompt);
          final parsed = _parseMergeResult(generated);
          stopwatch.stop();
          final usedModel = parsed != null;
          return MemorySlmResponse<MemorySlmMergeResult>(
            success: true,
            data: parsed ?? fallback,
            fallbackUsed: usedModel
                ? MemorySlmFallbackMode.none
                : MemorySlmFallbackMode.rules,
            latencyMs: stopwatch.elapsedMilliseconds,
            errorCode: usedModel ? null : 'slm_model_unavailable',
          );
        });
      },
    );
  }

  Future<MemorySlmResponse<String>> generateUpgradeReason(
    SummaryEntity fact,
  ) async {
    final cacheKey =
        '${fact.id}_${fact.accessCount}_${fact.importance.toStringAsFixed(2)}';
    final cached = _upgradeReasonCache[cacheKey];
    if (cached != null) {
      return MemorySlmResponse<String>(
        success: true,
        data: cached,
        fallbackUsed: MemorySlmFallbackMode.cache,
        latencyMs: 0,
      );
    }

    final fallback = _generateUpgradeReasonFallback(fact);
    return _runWithFallback<String>(
      operation: 'generateUpgradeReason',
      fallbackData: fallback,
      errorCode: 'upgrade_reason_failed',
      action: () {
        return _runQueued<MemorySlmResponse<String>>(() async {
          await initialize();
          final stopwatch = Stopwatch()..start();
          final prompt = _buildUpgradeReasonPrompt(fact);
          final generated = await _runModelPrompt(prompt);
          final reason = _sanitizeSingleLine(generated) ?? fallback;
          _setCache(_upgradeReasonCache, cacheKey, reason);
          stopwatch.stop();
          final usedModel = generated != null && generated.trim().isNotEmpty;
          return MemorySlmResponse<String>(
            success: true,
            data: reason,
            fallbackUsed: usedModel
                ? MemorySlmFallbackMode.none
                : MemorySlmFallbackMode.rules,
            latencyMs: stopwatch.elapsedMilliseconds,
            errorCode: usedModel ? null : 'slm_model_unavailable',
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
    final fallback = MemorySlmSummaryMetadata(
      title: title.trim().isEmpty
          ? slmConfig.fallbacks.summaryMetadataTitle
          : title.trim(),
      tags: tags
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .take(slmConfig.limits.summaryMetadataTagCount)
          .toList(),
    );

    try {
      return await _runQueued<MemorySlmResponse<MemorySlmSummaryMetadata>>(
        () async {
          await initialize();
          final stopwatch = Stopwatch()..start();
          final prompt = _buildSummaryMetadataPrompt(
            title: title,
            content: content,
            tags: tags,
          );
          final generated = await _runModelPrompt(prompt);
          final parsed = _parseSummaryMetadata(generated);
          stopwatch.stop();

          final usedModel = parsed != null;
          return MemorySlmResponse<MemorySlmSummaryMetadata>(
            success: true,
            data: MemorySlmSummaryMetadata(
              title: parsed?.title.trim().isNotEmpty == true
                  ? parsed!.title.trim()
                  : fallback.title,
              tags: parsed?.tags.isNotEmpty == true
                  ? parsed!.tags
                  : fallback.tags,
            ),
            fallbackUsed: usedModel
                ? MemorySlmFallbackMode.none
                : MemorySlmFallbackMode.disabled,
            latencyMs: stopwatch.elapsedMilliseconds,
            errorCode: usedModel ? null : 'slm_model_unavailable',
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint(
        '⚠️ [MemorySLMService] generateSummaryMetadata 失败，返回最小回退结果: $error',
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
    _engine?.dispose();
    _engine = null;
    _slmConfig = null;
    _isInitialized = false;
    _isModelAvailable = false;
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

  Future<File> _resolveModelFile() async {
    final slmConfig = await _loadSlmConfig();
    final baseDirectory = await getApplicationSupportDirectory();
    final modelDirectory = Directory(
      '${baseDirectory.path}/${slmConfig.model.modelDirectoryName}',
    );
    if (!await modelDirectory.exists()) {
      await modelDirectory.create(recursive: true);
    }
    return File('${modelDirectory.path}/${slmConfig.model.bundledFileName}');
  }

  Future<bool> _tryCopyBundledModel(
    File targetFile, {
    ModelDownloadProgressCallback? onProgress,
  }) async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final slmConfig = await _loadSlmConfig();
      final copiedPath = await _modelAssetChannel.invokeMethod<String>(
        'copyBundledModelToFiles',
        <String, dynamic>{
          'assetPath': slmConfig.model.bundledAssetPath,
          'fileName': slmConfig.model.bundledFileName,
          'targetPath': targetFile.path,
        },
      );
      if (copiedPath == null || copiedPath.isEmpty) {
        return false;
      }

      final copiedFile = File(copiedPath);
      if (!await copiedFile.exists()) {
        return false;
      }
      onProgress?.call(1.0);
      debugPrint('📦 [MemorySLMService] 已从资源目录复制模型到 ${copiedFile.path}');
      return true;
    } on PlatformException catch (error) {
      debugPrint('⚠️ [MemorySLMService] 原生复制模型失败: ${error.message}');
      return false;
    } on MissingPluginException {
      debugPrint('ℹ️ [MemorySLMService] 未找到资源模型，尝试其他加载方式');
      return false;
    }
  }

  Future<void> _initializeEngineIfSupported(File modelFile) async {
    final slmConfig = await _loadSlmConfig();
    _isModelAvailable = false;
    if (!_supportsNativeInference || !await modelFile.exists()) {
      return;
    }

    try {
      final appDirectory = await getApplicationSupportDirectory();
      final cacheDirectory = Directory(
        '${appDirectory.path}/${slmConfig.model.cacheDirectoryName}',
      );
      if (!await cacheDirectory.exists()) {
        await cacheDirectory.create(recursive: true);
      }

      final engineOptions = LlmInferenceOptions.cpu(
        modelPath: modelFile.path,
        cacheDir: cacheDirectory.path,
        maxTokens: slmConfig.runtime.maxTokens,
        temperature: slmConfig.runtime.temperature,
        topK: slmConfig.runtime.topK,
      );
      _engine = LlmInferenceEngine(engineOptions);
      _isModelAvailable = true;
    } catch (error, stackTrace) {
      _disableNativeInference(
        '原生推理引擎初始化失败: $error',
        stackTrace: stackTrace,
      );
    }
  }

  bool get _supportsNativeInference {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }
    if (!_experimentalNativeInferenceEnabled) {
      return false;
    }
    return _hasRequiredNativeSymbols();
  }

  Future<String?> _runModelPrompt(String prompt) async {
    final engine = _engine;
    if (!_isModelAvailable || engine == null) {
      return null;
    }

    try {
      final response = await engine.generateResponse(prompt).join();
      final trimmed = response.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (error, stackTrace) {
      _disableNativeInference(
        '模型推理失败，转用规则回退: $error',
        stackTrace: stackTrace,
      );
      return null;
    }
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
      debugPrint('⚠️ [MemorySLMService] $operation 失败，已回退到规则模式: $error');
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

  bool _hasRequiredNativeSymbols() {
    final cached = _nativeSymbolsAvailable;
    if (cached != null) {
      return cached;
    }

    try {
      DynamicLibrary.process().lookup<NativeFunction<Void Function()>>(
        'LlmInferenceEngine_CreateSession',
      );
      DynamicLibrary.process().lookup<NativeFunction<Void Function()>>(
        'LlmInferenceEngine_Session_PredictAsync',
      );
      _nativeSymbolsAvailable = true;
    } catch (_) {
      _nativeSymbolsAvailable = false;
      debugPrint(
        'ℹ️ [MemorySLMService] 未检测到 MediaPipe 所需原生符号，'
        '当前构建将使用规则模式。',
      );
    }

    return _nativeSymbolsAvailable ?? false;
  }

  void _disableNativeInference(
    String reason, {
    StackTrace? stackTrace,
  }) {
    debugPrint('⚠️ [MemorySLMService] $reason');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
    _engine?.dispose();
    _engine = null;
    _isModelAvailable = false;
  }

  String _buildTopicPrompt(String title, String content) {
    final slmConfig = _effectiveSlmConfig;
    return slmConfig.renderTemplate(
      slmConfig.prompts.extractTopic,
      <String, String>{
        ..._sharedPromptVariables(slmConfig),
        'title': title,
        'content': _truncate(content, slmConfig.limits.topicContentChars),
      },
    );
  }

  String _buildSameTopicPrompt(SummaryEntity entityA, SummaryEntity entityB) {
    final slmConfig = _effectiveSlmConfig;
    return slmConfig.renderTemplate(
      slmConfig.prompts.sameTopic,
      <String, String>{
        ..._sharedPromptVariables(slmConfig),
        'titleA': entityA.title,
        'contentA': _truncate(
          entityA.content,
          slmConfig.limits.sameTopicContentChars,
        ),
        'titleB': entityB.title,
        'contentB': _truncate(
          entityB.content,
          slmConfig.limits.sameTopicContentChars,
        ),
      },
    );
  }

  String _buildMergePrompt(List<SummaryEntity> sessions) {
    final slmConfig = _effectiveSlmConfig;
    final entries = sessions.asMap().entries.map((entry) {
      final item = entry.value;
      return slmConfig.renderTemplate(
        slmConfig.formatting.mergeSessionEntry,
        <String, String>{
          ..._sharedPromptVariables(slmConfig),
          'index': '${entry.key + 1}',
          'title': item.title,
          'content': _truncate(
            item.content,
            slmConfig.limits.mergeItemContentChars,
          ),
          'tags': item.tags.join(', '),
        },
      );
    }).join('\n');

    return slmConfig.renderTemplate(
      slmConfig.prompts.mergeSessions,
      <String, String>{
        ..._sharedPromptVariables(slmConfig),
        'entries': entries,
      },
    );
  }

  String _buildUpgradeReasonPrompt(SummaryEntity fact) {
    final slmConfig = _effectiveSlmConfig;
    return slmConfig.renderTemplate(
      slmConfig.prompts.upgradeReason,
      <String, String>{
        ..._sharedPromptVariables(slmConfig),
        'title': fact.title,
        'accessCount': fact.accessCount.toString(),
        'importance': fact.importance.toStringAsFixed(2),
        'createdAt': fact.createdAt.toIso8601String(),
      },
    );
  }

  String _buildSummaryMetadataPrompt({
    required String title,
    required String content,
    required List<String> tags,
  }) {
    final slmConfig = _effectiveSlmConfig;
    final emptyFieldPlaceholder = slmConfig.formatting.emptyFieldPlaceholder;
    final normalizedTitle = title.trim();
    final normalizedTags =
        tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).join(', ');
    return slmConfig.renderTemplate(
      slmConfig.prompts.summaryMetadata,
      <String, String>{
        ..._sharedPromptVariables(slmConfig),
        'title':
            normalizedTitle.isEmpty ? emptyFieldPlaceholder : normalizedTitle,
        'tags': normalizedTags.isEmpty ? emptyFieldPlaceholder : normalizedTags,
        'content': _truncate(
          content,
          slmConfig.limits.summaryMetadataContentChars,
        ),
      },
    );
  }

  String _extractTopicFallback(String title, String content) {
    final candidate = title.trim().isNotEmpty ? title.trim() : content.trim();
    final language = _detectPrimaryLanguage(candidate);
    return language == _PrimaryLanguage.chinese
        ? _fallbackChineseTopic(candidate)
        : _fallbackEnglishTopic(candidate);
  }

  bool _isSameTopicFallback(SummaryEntity a, SummaryEntity b) {
    final topicA = _normalizeText(a.topic ?? a.title);
    final topicB = _normalizeText(b.topic ?? b.title);
    if (topicA.isNotEmpty && topicA == topicB) {
      return true;
    }

    final titleA = _normalizeText(a.title);
    final titleB = _normalizeText(b.title);
    if (titleA.isEmpty || titleB.isEmpty) {
      return false;
    }
    if (titleA == titleB) {
      return true;
    }
    if (titleA.contains(titleB) || titleB.contains(titleA)) {
      return true;
    }

    final tagOverlap = a.tags.toSet().intersection(b.tags.toSet()).length;
    return tagOverlap >= _effectiveSlmConfig.heuristics.sameTopicMinTagOverlap;
  }

  MemorySlmMergeResult _mergeSessionsFallback(List<SummaryEntity> sessions) {
    if (sessions.isEmpty) {
      return MemorySlmMergeResult(
        title: _effectiveSlmConfig.fallbacks.emptyFactTitle,
        content: '',
        tags: <String>[],
      );
    }

    final mergedTags = <String>{};
    final buffer = StringBuffer();
    for (final session in sessions) {
      mergedTags.addAll(session.tags);
      if (buffer.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
      }
      buffer.write(session.content.trim());
    }

    final topic = _extractTopicFallback(
      sessions.first.title,
      buffer.toString(),
    );
    return MemorySlmMergeResult(
      title: sessions.first.title.trim().isEmpty
          ? topic
          : sessions.first.title.trim(),
      content: buffer.toString(),
      tags: mergedTags
          .take(_effectiveSlmConfig.limits.fallbackMergeTagCount)
          .toList(),
    );
  }

  MemorySlmMergeResult? _parseMergeResult(String? response) {
    if (response == null || response.trim().isEmpty) {
      return null;
    }

    final slmConfig = _effectiveSlmConfig;
    final titleMatch = _matchLabeledLine(
      response,
      slmConfig.formatting.titleLabel,
    );
    final tagsMatch = _matchLabeledLine(
      response,
      slmConfig.formatting.tagsLabel,
    );
    final contentMatch = _matchLabeledBlock(
      response,
      slmConfig.formatting.contentLabel,
    );
    final title = titleMatch?.group(1)?.trim();
    final content = contentMatch?.group(1)?.trim();
    if (title == null || title.isEmpty || content == null || content.isEmpty) {
      return null;
    }

    final tags = tagsMatch
            ?.group(1)
            ?.split(RegExp(r'[,，]'))
            .map((tag) {
              return tag.trim();
            })
            .where((tag) => tag.isNotEmpty)
            .take(slmConfig.limits.mergeResultTagCount)
            .toList() ??
        const <String>[];
    return MemorySlmMergeResult(
      title: title,
      content: content,
      tags: tags,
    );
  }

  MemorySlmSummaryMetadata? _parseSummaryMetadata(String? response) {
    if (response == null || response.trim().isEmpty) {
      return null;
    }

    final slmConfig = _effectiveSlmConfig;
    final titleMatch = _matchLabeledLine(
      response,
      slmConfig.formatting.titleLabel,
    );
    final tagsMatch = _matchLabeledLine(
      response,
      slmConfig.formatting.tagsLabel,
    );
    final title = _sanitizeSingleLine(titleMatch?.group(1));
    if (title == null || title.isEmpty) {
      return null;
    }

    final tags = tagsMatch
            ?.group(1)
            ?.split(RegExp(r'[,，]'))
            .map((tag) => _sanitizeSingleLine(tag) ?? '')
            .where((tag) => tag.isNotEmpty)
            .take(slmConfig.limits.summaryMetadataTagCount)
            .toList() ??
        const <String>[];

    return MemorySlmSummaryMetadata(
      title: title,
      tags: tags,
    );
  }

  String _generateUpgradeReasonFallback(SummaryEntity fact) {
    final slmConfig = _effectiveSlmConfig;
    if (fact.accessCount >= slmConfig.heuristics.upgradeAccessCountThreshold) {
      return slmConfig.fallbacks.upgradeReasonHighAccess;
    }
    if (fact.importance >= slmConfig.heuristics.upgradeImportanceThreshold) {
      return slmConfig.fallbacks.upgradeReasonHighImportance;
    }
    return slmConfig.fallbacks.upgradeReasonDefault;
  }

  String _sanitizeTopicResponse(String? response, String fallback) {
    final singleLine = _sanitizeSingleLine(response);
    if (singleLine == null) {
      return fallback;
    }
    final cleaned = singleLine
        .replaceAll(RegExp(r'^(主题|标签)[:：]\s*'), '')
        .replaceAll(RegExp("[\"'。，、；：,.!?！？]"), '')
        .trim();
    if (cleaned.isEmpty) {
      return fallback;
    }

    final language = _detectPrimaryLanguage(cleaned);
    if (language == _PrimaryLanguage.chinese) {
      final minChars = _effectiveSlmConfig.limits.topicChineseMinChars;
      final maxChars = _effectiveSlmConfig.limits.topicChineseMaxChars;
      final length = cleaned.length.clamp(minChars, maxChars).toInt();
      return cleaned.substring(0, length);
    }

    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(_effectiveSlmConfig.limits.topicEnglishWordCount);
    final topic = words.join(' ');
    return topic.isEmpty ? fallback : topic;
  }

  bool? _parseYesNo(String? response) {
    final singleLine = _sanitizeSingleLine(response);
    if (singleLine == null) {
      return null;
    }
    if (singleLine.startsWith('是') ||
        singleLine.toLowerCase().startsWith('yes')) {
      return true;
    }
    if (singleLine.startsWith('否') ||
        singleLine.toLowerCase().startsWith('no')) {
      return false;
    }
    return null;
  }

  String? _sanitizeSingleLine(String? response) {
    if (response == null) {
      return null;
    }
    final trimmed = response
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    return trimmed.isEmpty ? null : trimmed;
  }

  String _fallbackChineseTopic(String input) {
    final slmConfig = _effectiveSlmConfig;
    final cleaned = input.replaceAll(RegExp(r'[^\u4E00-\u9FFF0-9A-Za-z]'), '');
    if (cleaned.isEmpty) {
      return slmConfig.fallbacks.emptyChineseTopic;
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

  String _fallbackEnglishTopic(String input) {
    final slmConfig = _effectiveSlmConfig;
    final words = input
        .split(RegExp(r'\s+'))
        .map((word) => word.replaceAll(RegExp(r'[^A-Za-z0-9]'), ''))
        .where((word) => word.isNotEmpty)
        .take(slmConfig.limits.topicEnglishWordCount)
        .toList();
    if (words.isEmpty) {
      return slmConfig.fallbacks.emptyEnglishTopic;
    }
    return words.join(' ');
  }

  _PrimaryLanguage _detectPrimaryLanguage(String text) {
    final chineseMatches = RegExp(r'[\u4E00-\u9FFF]').allMatches(text).length;
    final latinMatches = RegExp(r'[A-Za-z]').allMatches(text).length;
    return chineseMatches >= latinMatches
        ? _PrimaryLanguage.chinese
        : _PrimaryLanguage.english;
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\u4E00-\u9FFF ]'), '')
        .trim();
  }

  String _truncate(String value, int maxLength) {
    final cleaned = value.trim();
    if (cleaned.length <= maxLength) {
      return cleaned;
    }
    return '${cleaned.substring(0, maxLength)}...';
  }

  Map<String, String> _sharedPromptVariables(MemorySlmConfig slmConfig) {
    return <String, String>{
      'titleLabel': slmConfig.formatting.titleLabel,
      'tagsLabel': slmConfig.formatting.tagsLabel,
      'contentLabel': slmConfig.formatting.contentLabel,
      'emptyFieldPlaceholder': slmConfig.formatting.emptyFieldPlaceholder,
    };
  }

  RegExpMatch? _matchLabeledLine(String response, String label) {
    return RegExp('${RegExp.escape(label)}[:：]\\s*(.+)').firstMatch(response);
  }

  RegExpMatch? _matchLabeledBlock(String response, String label) {
    return RegExp(
      '${RegExp.escape(label)}[:：]\\s*([\\s\\S]+)\$',
    ).firstMatch(response);
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
      debugPrint('⚠️ [MemorySLMService] 加载 SLM 配置失败，回退到默认配置: $error');
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
  chinese,
  english,
}
