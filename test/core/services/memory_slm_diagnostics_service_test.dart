import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/services/memory_slm_config.dart';
import 'package:local_vault/core/services/memory_slm_diagnostics_service.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const <String, Object>{});

  group('MemorySlmDiagnosticsService', () {
    late Directory tempDirectory;
    late _FakeMemorySlmService slmService;
    late MemorySlmDiagnosticsService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'memory_slm_diagnostics_service_test',
      );
      slmService = _FakeMemorySlmService();
      service = MemorySlmDiagnosticsService(
        slmService: slmService,
        appSupportDirectoryResolver: () async => tempDirectory,
        nowProvider: () => DateTime.parse('2026-03-18T12:00:00.000Z'),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('collectSnapshot reads model and cache files from app support path',
        () async {
      final modelDirectory = Directory('${tempDirectory.path}/models');
      await modelDirectory.create(recursive: true);
      await File(
        '${modelDirectory.path}/qwen2.5-0.5b-instruct-q4_k_m.gguf',
      ).writeAsBytes(List<int>.filled(32, 1));

      final cacheDirectory = Directory('${tempDirectory.path}/mediapipe_cache');
      await cacheDirectory.create(recursive: true);
      await File('${cacheDirectory.path}/cache.bin')
          .writeAsBytes(List<int>.filled(12, 1));

      final snapshot = await service.collectSnapshot();

      expect(snapshot.initialized, isFalse);
      expect(snapshot.modelAvailable, isTrue);
      expect(snapshot.experimentalNativeInferenceEnabled, isTrue);
      expect(snapshot.nativeInferenceSupported, isTrue);
      expect(snapshot.nativeSymbolsAvailable, isTrue);
      expect(snapshot.modelFileExists, isTrue);
      expect(snapshot.modelBytes, 32);
      expect(snapshot.cacheBytes, 12);
      expect(snapshot.bundledFileName, 'qwen2.5-0.5b-instruct-q4_k_m.gguf');
      expect(snapshot.requestTimeoutSeconds, 10);
      expect(snapshot.maxTokens, 128);
    });

    test('runSelfCheck returns topic and metadata inference results', () async {
      final result = await service.runSelfCheck();

      expect(result.completedAt, DateTime.parse('2026-03-18T12:00:00.000Z'));
      expect(result.initializeCompleted, isTrue);
      expect(result.topic, '项目诊断');
      expect(result.topicFallbackMode, MemorySlmFallbackMode.none);
      expect(result.topicLatencyMs, 11);
      expect(result.title, 'SLM 自检摘要');
      expect(result.tags, const <String>['SLM', '诊断']);
      expect(result.metadataFallbackMode, MemorySlmFallbackMode.none);
      expect(result.metadataLatencyMs, 17);
      expect(result.usedNativeModel, isTrue);
      expect(result.completedSuccessfully, isTrue);
    });
  });
}

class _FakeMemorySlmService extends MemorySLMService {
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  bool get isModelAvailable => true;

  @override
  bool get experimentalNativeInferenceEnabled => true;

  @override
  bool get nativeInferenceSupported => true;

  @override
  bool get nativeSymbolsAvailable => true;

  @override
  Future<bool> isSlmInferenceEnabled() async => true;

  @override
  Future<void> initialize({
    ModelDownloadProgressCallback? onProgress,
  }) async {
    _initialized = true;
  }

  @override
  Future<MemorySlmConfig> resolveConfig() async => MemorySlmConfig.fallback;

  @override
  Future<MemorySlmResponse<String>> extractTopic(
    String title,
    String content,
  ) async {
    return const MemorySlmResponse<String>(
      success: true,
      data: '项目诊断',
      fallbackUsed: MemorySlmFallbackMode.none,
      latencyMs: 11,
    );
  }

  @override
  Future<MemorySlmResponse<MemorySlmSummaryMetadata>> generateSummaryMetadata({
    String title = '',
    required String content,
    List<String> tags = const [],
  }) async {
    return const MemorySlmResponse<MemorySlmSummaryMetadata>(
      success: true,
      data: MemorySlmSummaryMetadata(
        title: 'SLM 自检摘要',
        tags: <String>['SLM', '诊断'],
      ),
      fallbackUsed: MemorySlmFallbackMode.none,
      latencyMs: 17,
    );
  }
}
