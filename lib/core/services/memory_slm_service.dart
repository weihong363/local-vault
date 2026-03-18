import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, PlatformException;
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/providers/locale_provider.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:local_vault/core/services/memory_slm_config.dart';
import 'package:local_vault/core/utils/summary_text_utils.dart';
import 'package:local_vault/l10n/app_localizations.dart';
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
    AppSettingsService? settingsService,
  })  : _configuration = configuration,
        _settingsService = settingsService ?? AppSettingsService();

  final MemorySlmConfiguration _configuration;
  final AppSettingsService _settingsService;

  static const MethodChannel _modelAssetChannel =
      MethodChannel('local_vault/model_assets');
  static const bool _experimentalNativeInferenceEnabled = bool.fromEnvironment(
    'ENABLE_MEDIAPIPE_SLM',
    defaultValue: true,
  );
  static const String _nativeInferenceFlagName = 'ENABLE_MEDIAPIPE_SLM';
  static const Set<String> _supportedNativeModelExtensions = <String>{
    'task',
    'bin',
    'litertlm',
  };

  final LinkedHashMap<String, String> _topicCache = LinkedHashMap();
  final LinkedHashMap<String, String> _upgradeReasonCache = LinkedHashMap();

  Future<void>? _initializing;
  bool _isInitialized = false;
  bool _isModelAvailable = false;
  Future<void> _requestQueue = Future<void>.value();
  bool _runtimeSlmInferenceEnabled = false;
  bool _runtimeSlmInferenceEnabledLoaded = false;
  Future<void>? _runtimeSlmInferenceEnabledLoading;
  bool? _nativeSymbolsAvailable;
  DynamicLibrary? _nativeLibrary;
  MemorySlmConfig? _slmConfig;
  Future<MemorySlmConfig>? _slmConfigLoading;

  LlmInferenceEngine? _engine;

  bool get isInitialized => _isInitialized;

  bool get isModelAvailable => _isModelAvailable;

  bool get experimentalNativeInferenceEnabled =>
      _experimentalNativeInferenceEnabled && _runtimeSlmInferenceEnabled;

  bool get nativeInferenceSupported => _supportsNativeInference;

  bool get nativeSymbolsAvailable => _hasRequiredNativeSymbols();

  bool isSupportedNativeModelFileName(String fileName) {
    final extension = _extractFileExtension(fileName);
    return _supportedNativeModelExtensions.contains(extension);
  }

  String describeNativeModelFileSupport(String fileName) {
    final extension = _extractFileExtension(fileName);
    if (_supportedNativeModelExtensions.contains(extension)) {
      return 'Compatible .$extension model';
    }
    if (extension.isEmpty) {
      return 'Unknown model format';
    }
    return 'Unsupported .$extension model for the current Android native SLM runtime';
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
    _resetRuntimeInferenceState();
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
      if (!_supportsNativeInference) {
        _isInitialized = true;
        _isModelAvailable = false;
        debugPrint(
          'ℹ️ [MemorySLMService] No available SLM inference entry point is enabled in this build, '
          'falling back to rule-based mode.'
          '${_experimentalNativeInferenceEnabled ? '' : ' To re-enable it, add --dart-define=$_nativeInferenceFlagName=true.'}',
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
            'ℹ️ [MemorySLMService] Bundled model asset not found: '
            '${_effectiveSlmConfig.model.bundledAssetPath}; falling back to rule-based mode.',
          );
        }
      }

      await _initializeEngineIfSupported(modelFile);
      _isInitialized = true;
      debugPrint(
        '🧠 [MemorySLMService] Initialization completed, SLM ${_isModelAvailable ? 'available' : 'running in fallback mode'}',
      );
    } catch (error, stackTrace) {
      _isInitialized = true;
      _isModelAvailable = false;
      debugPrint(
          '⚠️ [MemorySLMService] Initialization failed, degraded mode enabled: $error');
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
          final prompt = await _buildUpgradeReasonPrompt(
            fact,
            locale: locale,
          );
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
      debugPrint(
          '📦 [MemorySLMService] Copied model from bundled assets to ${copiedFile.path}');
      return true;
    } on PlatformException catch (error) {
      debugPrint(
          '⚠️ [MemorySLMService] Native model copy failed: ${error.message}');
      return false;
    } on MissingPluginException {
      debugPrint(
          'ℹ️ [MemorySLMService] Bundled model not found, trying another loading path');
      return false;
    }
  }

  Future<void> _initializeEngineIfSupported(File modelFile) async {
    final slmConfig = await _loadSlmConfig();
    _isModelAvailable = false;
    if (!_supportsNativeInference || !await modelFile.exists()) {
      return;
    }

    if (!isSupportedNativeModelFileName(modelFile.path)) {
      debugPrint(
        'ℹ️ [MemorySLMService] Current model ${slmConfig.model.bundledFileName} '
        'is not in a format supported by the current Android native SLM runtime; '
        'falling back to rule-based mode. The runtime currently only supports '
        '${_supportedNativeModelExtensions.map((value) => '.$value').join(', ')}.',
      );
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
        'Native inference engine initialization failed: $error',
        stackTrace: stackTrace,
      );
    }
  }

  bool get _supportsNativeInference {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }
    if (!experimentalNativeInferenceEnabled) {
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
        'Model inference failed, switching to rule-based fallback: $error',
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

  bool _hasRequiredNativeSymbols() {
    final cached = _nativeSymbolsAvailable;
    if (cached != null) {
      return cached;
    }

    Object? lastError;
    final libraries = <DynamicLibrary>[DynamicLibrary.process()];
    try {
      libraries.insert(0, _resolveNativeLibrary());
    } catch (error) {
      lastError = error;
    }

    for (final library in libraries) {
      try {
        library.lookup<NativeFunction<Void Function()>>(
          'LlmInferenceEngine_CreateSession',
        );
        library.lookup<NativeFunction<Void Function()>>(
          'LlmInferenceEngine_Session_PredictAsync',
        );
        _nativeSymbolsAvailable = true;
        return true;
      } catch (error) {
        lastError = error;
      }
    }

    _nativeSymbolsAvailable = false;
    debugPrint(
      'ℹ️ [MemorySLMService] Required native symbols for the current SLM inference path were not detected, '
      'this build will use rule-based mode.'
      '${lastError == null ? '' : ' Details: $lastError'}',
    );

    return _nativeSymbolsAvailable ?? false;
  }

  DynamicLibrary _resolveNativeLibrary() {
    final cached = _nativeLibrary;
    if (cached != null) {
      return cached;
    }

    if (Platform.isAndroid) {
      final library = DynamicLibrary.open('libllm_inference_engine.so');
      debugPrint(
        '✅ [MemorySLMService] Explicitly loaded libllm_inference_engine.so',
      );
      _nativeLibrary = library;
      return library;
    }

    final library = DynamicLibrary.process();
    _nativeLibrary = library;
    return library;
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

  void _resetRuntimeInferenceState() {
    _engine?.dispose();
    _engine = null;
    _isInitialized = false;
    _isModelAvailable = false;
    _initializing = null;
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

  Future<String> _buildUpgradeReasonPrompt(
    SummaryEntity fact, {
    ui.Locale? locale,
  }) async {
    final slmConfig = _effectiveSlmConfig;
    final targetLocale = locale ?? await _resolvePreferredLocale();
    return slmConfig.renderTemplate(
      slmConfig.prompts.upgradeReason,
      <String, String>{
        ..._sharedPromptVariables(slmConfig),
        'outputLanguageInstruction':
            _upgradeReasonOutputLanguageInstruction(targetLocale),
        'accessCountLabel': _upgradeReasonMetricLabel(
          targetLocale,
          english: 'Access count',
          zh: '访问次数',
          ja: 'アクセス数',
          ko: '방문 수',
          es: 'Número de accesos',
          fr: 'Nombre de consultations',
          de: 'Anzahl der Aufrufe',
        ),
        'importanceLabel': _upgradeReasonMetricLabel(
          targetLocale,
          english: 'Importance',
          zh: '重要度',
          ja: '重要度',
          ko: '중요도',
          es: 'Importancia',
          fr: 'Importance',
          de: 'Wichtigkeit',
        ),
        'createdAtLabel': _upgradeReasonMetricLabel(
          targetLocale,
          english: 'Created at',
          zh: '创建时间',
          ja: '作成日時',
          ko: '생성 시각',
          es: 'Creado el',
          fr: 'Créé le',
          de: 'Erstellt am',
        ),
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
    final canonicalTopic = _extractCanonicalTopicAlias(title, content);
    if (canonicalTopic != null) {
      return canonicalTopic;
    }

    final candidate = title.trim().isNotEmpty ? title.trim() : content.trim();
    final generatedTitle = SummaryTextUtils.generateTitle(candidate);
    final generatedTags = SummaryTextUtils.generateTags(
      generatedTitle,
      content,
      maxTags: 1,
    );
    final semanticCandidate =
        generatedTags.isNotEmpty ? generatedTags.first : generatedTitle;
    return _normalizeFallbackTopicCandidate(semanticCandidate, content);
  }

  String? _extractCanonicalTopicAlias(String title, String content) {
    final normalized = '$title $content'.toLowerCase();

    if (RegExp(r'\brag\b').hasMatch(normalized) ||
        normalized.contains('检索增强生成') ||
        normalized.contains('retrieval augmented generation')) {
      return 'RAG';
    }

    final ragSecondarySignals = <Pattern>[
      '向量',
      '召回',
      '重排',
      '检索',
      '知识库',
      RegExp(r'\bembedding\b'),
      RegExp(r'\bchunk\b'),
      RegExp(r'\brerank\b'),
      RegExp(r'\bfaiss\b'),
      RegExp(r'\bmilvus\b'),
      RegExp(r'\bqdrant\b'),
    ];
    final ragSignalCount = ragSecondarySignals
        .where(
          (pattern) => pattern is String
              ? normalized.contains(pattern)
              : (pattern as RegExp).hasMatch(normalized),
        )
        .length;
    if (ragSignalCount >= 2) {
      return 'RAG';
    }

    if (RegExp(r'\bllm\b').hasMatch(normalized) ||
        normalized.contains('大语言模型')) {
      return 'LLM';
    }
    if (RegExp(r'\bslm\b').hasMatch(normalized) ||
        normalized.contains('小语言模型')) {
      return 'SLM';
    }
    if (RegExp(r'\bocr\b').hasMatch(normalized) ||
        normalized.contains('文字识别')) {
      return 'OCR';
    }

    return null;
  }

  bool _isSameTopicFallback(SummaryEntity a, SummaryEntity b) {
    final topicA = _normalizeText(a.topic ?? a.title);
    final topicB = _normalizeText(b.topic ?? b.title);
    if (_isStableTopicValue(topicA) &&
        _isStableTopicValue(topicB) &&
        topicA == topicB) {
      return true;
    }

    final titleA = _normalizeText(a.title);
    final titleB = _normalizeText(b.title);
    if (!_isStableTopicValue(titleA) || !_isStableTopicValue(titleB)) {
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

  String _upgradeReasonOutputLanguageInstruction(ui.Locale locale) {
    final languageName = switch (locale.languageCode) {
      'zh' => 'Simplified Chinese',
      'ja' => 'Japanese',
      'ko' => 'Korean',
      'es' => 'Spanish',
      'fr' => 'French',
      'de' => 'German',
      _ => 'English',
    };
    return 'Write the sentence in $languageName.';
  }

  String _upgradeReasonMetricLabel(
    ui.Locale locale, {
    required String english,
    required String zh,
    required String ja,
    required String ko,
    required String es,
    required String fr,
    required String de,
  }) {
    switch (locale.languageCode) {
      case 'zh':
        return zh;
      case 'ja':
        return ja;
      case 'ko':
        return ko;
      case 'es':
        return es;
      case 'fr':
        return fr;
      case 'de':
        return de;
      default:
        return english;
    }
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

  String _normalizeFallbackTopicCandidate(String candidate, String content) {
    final trimmed = candidate.trim();
    if (trimmed.isEmpty || trimmed == SummaryTextUtils.unnamedTitle) {
      final language = _detectPrimaryLanguage(content);
      return language == _PrimaryLanguage.chinese
          ? _fallbackChineseTopic(content)
          : _fallbackEnglishTopic(content);
    }

    final language = _detectPrimaryLanguage(trimmed);
    if (language == _PrimaryLanguage.chinese) {
      final cleaned = trimmed
          .replaceAll(RegExp(r'^(待整理|未命名|临时)'), '')
          .replaceAll(RegExp(r'[^\u4E00-\u9FFFA-Za-z0-9]'), '')
          .trim();
      if (cleaned.isEmpty) {
        return _fallbackChineseTopic(content);
      }
      final maxLength = _effectiveSlmConfig.limits.topicChineseMaxChars;
      return cleaned.length > maxLength
          ? cleaned.substring(0, maxLength)
          : cleaned;
    }

    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(_effectiveSlmConfig.limits.topicEnglishWordCount)
        .toList();
    if (words.isEmpty) {
      return _fallbackEnglishTopic(content);
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

  bool _isStableTopicValue(String value) {
    if (value.isEmpty) {
      return false;
    }

    final normalizedFallbackTitle = _normalizeText(
      _effectiveSlmConfig.fallbacks.summaryMetadataTitle,
    );
    final normalizedChineseTopic = _normalizeText(
      _effectiveSlmConfig.fallbacks.emptyChineseTopic,
    );
    final normalizedEnglishTopic = _normalizeText(
      _effectiveSlmConfig.fallbacks.emptyEnglishTopic,
    );

    return value != _normalizeText(SummaryTextUtils.unnamedTitle) &&
        value != normalizedFallbackTitle &&
        value != normalizedChineseTopic &&
        value != normalizedEnglishTopic;
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

// TODO SLM API的入口
get LlmInferenceOptions => null;

class LlmInferenceEngine {
  LlmInferenceEngine(engineOptions);

  void dispose() {}

  generateResponse(String prompt) {}
}

enum _PrimaryLanguage {
  chinese,
  english,
}
