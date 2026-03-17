import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, PlatformException;
import 'package:http/http.dart' as http;
import 'package:local_vault/core/domain/entities/summary_entity.dart';
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
    this.modelDownloadUrl,
    this.modelFileName = 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
    this.modelDirectoryName = 'models',
    this.bundledModelAssetPath = 'models/qwen2.5-1.5b-instruct-q4_k_m.gguf',
    this.cacheDirectoryName = 'mediapipe_cache',
    this.requestTimeout = const Duration(seconds: 10),
    this.maxConcurrentRequests = 1,
    this.maxQueueWait = const Duration(seconds: 10),
    this.maxCacheEntries = 128,
    this.maxTokens = 256,
    this.temperature = 0.2,
    this.topK = 40,
  });

  final String? modelDownloadUrl;
  final String modelFileName;
  final String modelDirectoryName;
  final String bundledModelAssetPath;
  final String cacheDirectoryName;
  final Duration requestTimeout;
  final int maxConcurrentRequests;
  final Duration maxQueueWait;
  final int maxCacheEntries;
  final int maxTokens;
  final double temperature;
  final int topK;
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

class MemorySLMService {
  MemorySLMService({
    MemorySlmConfiguration configuration = const MemorySlmConfiguration(),
    http.Client? httpClient,
  })  : _configuration = configuration,
        _httpClient = httpClient ?? http.Client();

  final MemorySlmConfiguration _configuration;
  final http.Client _httpClient;

  static const MethodChannel _modelAssetChannel =
      MethodChannel('local_vault/model_assets');

  final LinkedHashMap<String, String> _topicCache = LinkedHashMap();
  final LinkedHashMap<String, String> _upgradeReasonCache = LinkedHashMap();

  Future<void>? _initializing;
  bool _isInitialized = false;
  bool _isModelAvailable = false;
  int _activeRequests = 0;
  Future<void> _requestQueue = Future<void>.value();

  LlmInferenceEngine? _engine;
  LlmInferenceOptions? _engineOptions;

  bool get isInitialized => _isInitialized;

  bool get isModelAvailable => _isModelAvailable;

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
      final modelFile = await _resolveModelFile();
      if (!await modelFile.exists()) {
        final copied = await _tryCopyBundledModel(
          modelFile,
          onProgress: onProgress,
        );
        if (!copied) {
          await _tryDownloadModel(modelFile, onProgress: onProgress);
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

    return _runQueued<MemorySlmResponse<String>>(() async {
      await initialize();
      final stopwatch = Stopwatch()..start();
      final fallbackTopic = _extractTopicFallback(title, content);
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
  }

  Future<MemorySlmResponse<bool>> isSameTopic(
    SummaryEntity entityA,
    SummaryEntity entityB,
  ) async {
    return _runQueued<MemorySlmResponse<bool>>(() async {
      await initialize();
      final stopwatch = Stopwatch()..start();
      final fallback = _isSameTopicFallback(entityA, entityB);
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
  }

  Future<MemorySlmResponse<MemorySlmMergeResult>> mergeSessions(
    List<SummaryEntity> sessions,
  ) async {
    return _runQueued<MemorySlmResponse<MemorySlmMergeResult>>(() async {
      await initialize();
      final stopwatch = Stopwatch()..start();
      final fallback = _mergeSessionsFallback(sessions);
      if (sessions.isEmpty) {
        stopwatch.stop();
        return MemorySlmResponse<MemorySlmMergeResult>(
          success: false,
          data: fallback,
          fallbackUsed: MemorySlmFallbackMode.rules,
          latencyMs: stopwatch.elapsedMilliseconds,
          errorCode: 'empty_sessions',
        );
      }

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

    return _runQueued<MemorySlmResponse<String>>(() async {
      await initialize();
      final stopwatch = Stopwatch()..start();
      final fallback = _generateUpgradeReasonFallback(fact);
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
  }

  Future<void> dispose() async {
    _topicCache.clear();
    _upgradeReasonCache.clear();
    _engine?.dispose();
    _engine = null;
    _engineOptions = null;
    _httpClient.close();
    _isInitialized = false;
    _isModelAvailable = false;
  }

  Future<T> _runQueued<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final requestEnqueuedAt = DateTime.now();

    _requestQueue = _requestQueue.catchError((Object _) {}).then((_) async {
      if (_activeRequests >= _configuration.maxConcurrentRequests) {
        final queuedFor = DateTime.now().difference(requestEnqueuedAt);
        if (queuedFor > _configuration.maxQueueWait) {
          completer.completeError(
            TimeoutException(
              'SLM request queue timeout',
              _configuration.maxQueueWait,
            ),
          );
          return;
        }
      }

      _activeRequests += 1;
      try {
        final result = await action().timeout(_configuration.requestTimeout);
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      } finally {
        _activeRequests -= 1;
      }
    });

    return completer.future;
  }

  Future<File> _resolveModelFile() async {
    final baseDirectory = await getApplicationSupportDirectory();
    final modelDirectory = Directory(
      '${baseDirectory.path}/${_configuration.modelDirectoryName}',
    );
    if (!await modelDirectory.exists()) {
      await modelDirectory.create(recursive: true);
    }
    return File('${modelDirectory.path}/${_configuration.modelFileName}');
  }

  Future<bool> _tryCopyBundledModel(
    File targetFile, {
    ModelDownloadProgressCallback? onProgress,
  }) async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final copiedPath = await _modelAssetChannel.invokeMethod<String>(
        'copyBundledModelToFiles',
        <String, dynamic>{
          'assetPath': _configuration.bundledModelAssetPath,
          'fileName': _configuration.modelFileName,
        },
      );
      if (copiedPath == null || copiedPath.isEmpty) {
        return false;
      }

      final copiedFile = File(copiedPath);
      if (copiedFile.path != targetFile.path && await copiedFile.exists()) {
        await copiedFile.copy(targetFile.path);
      }
      onProgress?.call(1.0);
      debugPrint('📦 [MemorySLMService] 已从资源目录复制模型到 ${targetFile.path}');
      return true;
    } on PlatformException catch (error) {
      debugPrint('⚠️ [MemorySLMService] 原生复制模型失败: ${error.message}');
      return false;
    } on MissingPluginException {
      debugPrint('ℹ️ [MemorySLMService] 未找到资源模型，尝试其他加载方式');
      return false;
    }
  }

  Future<void> _tryDownloadModel(
    File targetFile, {
    ModelDownloadProgressCallback? onProgress,
  }) async {
    final downloadUrl = _configuration.modelDownloadUrl;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      debugPrint('ℹ️ [MemorySLMService] 未配置模型下载地址，跳过下载');
      return;
    }

    final request = http.Request('GET', Uri.parse(downloadUrl));
    final response = await _httpClient.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Model download failed: ${response.statusCode}');
    }

    final sink = targetFile.openWrite();
    final totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress(receivedBytes / totalBytes);
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  Future<void> _initializeEngineIfSupported(File modelFile) async {
    _isModelAvailable = false;
    if (!_supportsNativeInference || !await modelFile.exists()) {
      return;
    }

    try {
      final appDirectory = await getApplicationSupportDirectory();
      final cacheDirectory = Directory(
        '${appDirectory.path}/${_configuration.cacheDirectoryName}',
      );
      if (!await cacheDirectory.exists()) {
        await cacheDirectory.create(recursive: true);
      }

      _engineOptions = LlmInferenceOptions.cpu(
        modelPath: modelFile.path,
        cacheDir: cacheDirectory.path,
        maxTokens: _configuration.maxTokens,
        temperature: _configuration.temperature,
        topK: _configuration.topK,
      );
      _engine = LlmInferenceEngine(_engineOptions!);
      _isModelAvailable = true;
    } catch (error, stackTrace) {
      _engine?.dispose();
      _engine = null;
      _engineOptions = null;
      _isModelAvailable = false;
      debugPrint('⚠️ [MemorySLMService] 原生推理引擎初始化失败: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  bool get _supportsNativeInference => !kIsWeb && Platform.isAndroid;

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
      debugPrint('⚠️ [MemorySLMService] 模型推理失败，转用规则回退: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  String _buildTopicPrompt(String title, String content) {
    return '''
角色：记忆整理助手
任务：从以下标题和内容中提取一个精确的主题标签。
要求：
- 只输出一个主题标签
- 输出语言跟随输入主语言
- 不要使用标点符号
- 尽量简洁

标题：$title
内容：${_truncate(content, 240)}
''';
  }

  String _buildSameTopicPrompt(SummaryEntity entityA, SummaryEntity entityB) {
    return '''
角色：文本相似度判断助手
任务：判断两段文字是否讨论同一主题。
要求：
- 只回答“是”或“否”

文本 A 标题：${entityA.title}
文本 A 内容：${_truncate(entityA.content, 120)}

文本 B 标题：${entityB.title}
文本 B 内容：${_truncate(entityB.content, 120)}
''';
  }

  String _buildMergePrompt(List<SummaryEntity> sessions) {
    final entries = sessions.asMap().entries.map((entry) {
      final item = entry.value;
      return '''
记录 ${entry.key + 1}
标题：${item.title}
内容：${_truncate(item.content, 180)}
标签：${item.tags.join(', ')}
''';
    }).join('\n');

    return '''
角色：信息整理专家
任务：将多条记录合并为一条结构化事实记忆。
严格按以下格式输出：
标题：不超过 10 个字
标签：标签1, 标签2, 标签3
内容：
用 1 到 3 段话整理出合并后的核心信息，总字数控制在 300 字以内。

$entries
''';
  }

  String _buildUpgradeReasonPrompt(SummaryEntity fact) {
    return '''
角色：记忆管理顾问
任务：解释为什么这条记忆值得升级为核心记忆。
要求：
- 只输出一句话
- 语气积极、具体

标题：${fact.title}
访问次数：${fact.accessCount}
重要性：${fact.importance.toStringAsFixed(2)}
创建时间：${fact.createdAt.toIso8601String()}
''';
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
    return tagOverlap >= 2;
  }

  MemorySlmMergeResult _mergeSessionsFallback(List<SummaryEntity> sessions) {
    if (sessions.isEmpty) {
      return const MemorySlmMergeResult(
        title: '未命名事实',
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
      tags: mergedTags.take(5).toList(),
    );
  }

  MemorySlmMergeResult? _parseMergeResult(String? response) {
    if (response == null || response.trim().isEmpty) {
      return null;
    }

    final titleMatch = RegExp(r'标题[:：]\s*(.+)').firstMatch(response);
    final tagsMatch = RegExp(r'标签[:：]\s*(.+)').firstMatch(response);
    final contentMatch = RegExp(r'内容[:：]\s*([\s\S]+)$').firstMatch(response);
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
            .take(5)
            .toList() ??
        const <String>[];
    return MemorySlmMergeResult(
      title: title,
      content: content,
      tags: tags,
    );
  }

  String _generateUpgradeReasonFallback(SummaryEntity fact) {
    if (fact.accessCount >= 10) {
      return '这条记忆被频繁访问，已经表现出稳定的长期价值，适合升级为核心记忆。';
    }
    if (fact.importance >= 0.8) {
      return '这条记忆的重要性评分很高，值得作为核心记忆长期保留。';
    }
    return '这条记忆已经具备持续价值，升级后可以获得更稳定的保存与检索优先级。';
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
      final length = cleaned.length.clamp(2, 8).toInt();
      return cleaned.substring(0, length);
    }

    final words =
        cleaned.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).take(3);
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
    final cleaned = input.replaceAll(RegExp(r'[^\u4E00-\u9FFF0-9A-Za-z]'), '');
    if (cleaned.isEmpty) {
      return '临时主题';
    }
    final take = cleaned.length >= 6 ? 6 : cleaned.length.clamp(2, 6).toInt();
    return cleaned.substring(0, take);
  }

  String _fallbackEnglishTopic(String input) {
    final words = input
        .split(RegExp(r'\s+'))
        .map((word) => word.replaceAll(RegExp(r'[^A-Za-z0-9]'), ''))
        .where((word) => word.isNotEmpty)
        .take(3)
        .toList();
    if (words.isEmpty) {
      return 'General topic';
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

  void _setCache(
    LinkedHashMap<String, String> cache,
    String key,
    String value,
  ) {
    cache.remove(key);
    cache[key] = value;
    while (cache.length > _configuration.maxCacheEntries) {
      cache.remove(cache.keys.first);
    }
  }
}

enum _PrimaryLanguage {
  chinese,
  english,
}
