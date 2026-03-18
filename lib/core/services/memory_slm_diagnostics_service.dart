import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:path_provider/path_provider.dart';

class MemorySlmDiagnosticsSnapshot {
  const MemorySlmDiagnosticsSnapshot({
    required this.runningOnAndroid,
    required this.runningOnWeb,
    required this.initialized,
    required this.modelAvailable,
    required this.experimentalNativeInferenceEnabled,
    required this.nativeInferenceSupported,
    required this.nativeSymbolsAvailable,
    required this.modelFormatSupported,
    required this.modelFormatDescription,
    required this.bundledFileName,
    required this.bundledAssetPath,
    required this.modelFilePath,
    required this.modelFileExists,
    required this.modelBytes,
    required this.cacheDirectoryPath,
    required this.cacheBytes,
    required this.requestTimeoutSeconds,
    required this.maxQueueWaitSeconds,
    required this.maxCacheEntries,
    required this.maxTokens,
  });

  final bool runningOnAndroid;
  final bool runningOnWeb;
  final bool initialized;
  final bool modelAvailable;
  final bool experimentalNativeInferenceEnabled;
  final bool nativeInferenceSupported;
  final bool nativeSymbolsAvailable;
  final bool modelFormatSupported;
  final String modelFormatDescription;
  final String bundledFileName;
  final String bundledAssetPath;
  final String modelFilePath;
  final bool modelFileExists;
  final int modelBytes;
  final String cacheDirectoryPath;
  final int cacheBytes;
  final int requestTimeoutSeconds;
  final int maxQueueWaitSeconds;
  final int maxCacheEntries;
  final int maxTokens;
}

class MemorySlmSelfCheckResult {
  const MemorySlmSelfCheckResult({
    required this.completedAt,
    required this.initializeCompleted,
    required this.topic,
    required this.topicFallbackMode,
    required this.topicLatencyMs,
    required this.title,
    required this.tags,
    required this.metadataFallbackMode,
    required this.metadataLatencyMs,
  });

  final DateTime completedAt;
  final bool initializeCompleted;
  final String topic;
  final MemorySlmFallbackMode topicFallbackMode;
  final int topicLatencyMs;
  final String title;
  final List<String> tags;
  final MemorySlmFallbackMode metadataFallbackMode;
  final int metadataLatencyMs;

  bool get usedNativeModel =>
      topicFallbackMode == MemorySlmFallbackMode.none ||
      metadataFallbackMode == MemorySlmFallbackMode.none;

  bool get completedSuccessfully => topic.isNotEmpty && title.isNotEmpty;
}

class MemorySlmDiagnosticsService {
  MemorySlmDiagnosticsService({
    required MemorySLMService slmService,
    Future<Directory> Function()? appSupportDirectoryResolver,
    DateTime Function()? nowProvider,
  })  : _slmService = slmService,
        _appSupportDirectoryResolver =
            appSupportDirectoryResolver ?? getApplicationSupportDirectory,
        _nowProvider = nowProvider ?? DateTime.now;

  final MemorySLMService _slmService;
  final Future<Directory> Function() _appSupportDirectoryResolver;
  final DateTime Function() _nowProvider;

  Future<MemorySlmDiagnosticsSnapshot> collectSnapshot() async {
    final slmInferenceEnabled = await _slmService.isSlmInferenceEnabled();
    final config = await _slmService.resolveConfig();
    final appSupportDirectory = await _appSupportDirectoryResolver();
    final modelFile = File(
      '${appSupportDirectory.path}/${config.model.modelDirectoryName}/'
      '${config.model.bundledFileName}',
    );
    final cacheDirectory = Directory(
      '${appSupportDirectory.path}/${config.model.cacheDirectoryName}',
    );

    final modelFileExists = await modelFile.exists();

    return MemorySlmDiagnosticsSnapshot(
      runningOnAndroid: !kIsWeb && Platform.isAndroid,
      runningOnWeb: kIsWeb,
      initialized: _slmService.isInitialized,
      modelAvailable: _slmService.isModelAvailable,
      experimentalNativeInferenceEnabled:
          slmInferenceEnabled && _slmService.experimentalNativeInferenceEnabled,
      nativeInferenceSupported: _slmService.nativeInferenceSupported,
      nativeSymbolsAvailable: _slmService.nativeSymbolsAvailable,
      modelFormatSupported: _slmService
          .isSupportedNativeModelFileName(config.model.bundledFileName),
      modelFormatDescription: _slmService
          .describeNativeModelFileSupport(config.model.bundledFileName),
      bundledFileName: config.model.bundledFileName,
      bundledAssetPath: config.model.bundledAssetPath,
      modelFilePath: modelFile.path,
      modelFileExists: modelFileExists,
      modelBytes: modelFileExists ? await modelFile.length() : 0,
      cacheDirectoryPath: cacheDirectory.path,
      cacheBytes: await _sizeOfDirectory(cacheDirectory),
      requestTimeoutSeconds: config.runtime.requestTimeoutSeconds,
      maxQueueWaitSeconds: config.runtime.maxQueueWaitSeconds,
      maxCacheEntries: config.runtime.maxCacheEntries,
      maxTokens: config.runtime.maxTokens,
    );
  }

  Future<MemorySlmSelfCheckResult> runSelfCheck() async {
    await _slmService.initialize();

    final topicResponse = await _slmService.extractTopic(
      'Local Vault SLM 自检',
      '请提取这段诊断样例的主题，用于验证当前设备上的 SLM 推理或规则回退链路是否可用。',
    );
    final metadataResponse = await _slmService.generateSummaryMetadata(
      content:
          '这是一条用于验证 Local Vault 当前设备环境中标题与标签生成能力的自检样例，请输出一个可检索的标题和 2 到 4 个标签。',
    );

    return MemorySlmSelfCheckResult(
      completedAt: _nowProvider(),
      initializeCompleted: _slmService.isInitialized,
      topic: topicResponse.data.trim(),
      topicFallbackMode: topicResponse.fallbackUsed,
      topicLatencyMs: topicResponse.latencyMs,
      title: metadataResponse.data.title.trim(),
      tags: metadataResponse.data.tags,
      metadataFallbackMode: metadataResponse.fallbackUsed,
      metadataLatencyMs: metadataResponse.latencyMs,
    );
  }

  Future<int> _sizeOfDirectory(Directory directory) async {
    if (!await directory.exists()) {
      return 0;
    }

    var totalBytes = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes;
  }
}
