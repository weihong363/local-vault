import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:local_vault/core/services/memory_slm_config.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/services/summary_metadata_service.dart';
import 'package:local_vault/core/utils/summary_text_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SummaryMetadataService', () {
    test('rule mode generates refined title and semantic tags', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'slm_summary_metadata_enabled': false,
      });

      final service = SummaryMetadataService(
        slmService: _FakeMemorySlmService(),
        settingsService: AppSettingsService(),
      );

      final draft = await service.prepareForSave(
        content: '请帮我记录一下：本周项目进展同步，确认登录页改版和埋点补齐。',
      );

      expect(draft.usedModel, isFalse);
      expect(draft.title, isNot(SummaryTextUtils.unnamedTitle));
      expect(draft.title, isNot(contains('请帮我')));
      expect(draft.title, isNot(contains('记录一下')));
      expect(draft.title, contains('项目进展'));
      expect(draft.tags, isNotEmpty);
      expect(draft.tags.join(','), contains('项目进展'));
    });

    test('slm mode bypasses rule generation and uses model output', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'slm_summary_metadata_enabled': true,
      });

      final service = SummaryMetadataService(
        slmService: _FakeMemorySlmService(),
        settingsService: AppSettingsService(),
      );

      final draft = await service.prepareForSave(
        content: '原始摘要内容',
      );

      expect(draft.usedModel, isTrue);
      expect(draft.title, '项目周报整理');
      expect(draft.tags, <String>['项目进展', '登录改版', '埋点补齐']);
    });

    test('slm fallback title follows resolved config', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'slm_summary_metadata_enabled': true,
      });

      final service = SummaryMetadataService(
        slmService: _FallbackMemorySlmService(),
        settingsService: AppSettingsService(),
      );

      final draft = await service.prepareForSave(
        content: '这里只提供正文，不提供可靠标题。',
      );

      expect(draft.usedModel, isFalse);
      expect(draft.title, '待人工整理');
    });

    test('preview mode regenerates metadata from content even if form has text',
        () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'slm_summary_metadata_enabled': false,
      });

      final service = SummaryMetadataService(
        slmService: _FakeMemorySlmService(),
        settingsService: AppSettingsService(),
      );

      final draft = await service.preparePreview(
        title: '随手记一下',
        tags: const <String>['记录'],
        content: '周会同步项目上线安排，确认灰度发布和回滚预案。',
      );

      expect(draft.usedModel, isFalse);
      expect(draft.title, isNot('随手记一下'));
      expect(draft.title, contains('项目'));
      expect(draft.tags, isNot(contains('记录')));
    });
  });
}

class _FakeMemorySlmService extends MemorySLMService {
  @override
  Future<MemorySlmConfig> resolveConfig() async => MemorySlmConfig.fallback;

  @override
  Future<MemorySlmResponse<MemorySlmSummaryMetadata>> generateSummaryMetadata({
    String title = '',
    required String content,
    List<String> tags = const [],
  }) async {
    return const MemorySlmResponse<MemorySlmSummaryMetadata>(
      success: true,
      data: MemorySlmSummaryMetadata(
        title: '项目周报整理',
        tags: <String>['项目进展', '登录改版', '埋点补齐'],
      ),
      fallbackUsed: MemorySlmFallbackMode.none,
      latencyMs: 0,
    );
  }
}

class _FallbackMemorySlmService extends MemorySLMService {
  @override
  Future<MemorySlmConfig> resolveConfig() async {
    return MemorySlmConfig.fallback.copyWith(
      fallbacks: const MemorySlmFallbackValues(
        summaryMetadataTitle: '待人工整理',
        emptyFactTitle: '未命名事实',
        emptyChineseTopic: '临时主题',
        emptyEnglishTopic: 'General topic',
        upgradeReasonHighAccess: '高频访问',
        upgradeReasonHighImportance: '高重要性',
        upgradeReasonDefault: '默认升级原因',
      ),
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
        title: '',
        tags: <String>[],
      ),
      fallbackUsed: MemorySlmFallbackMode.disabled,
      latencyMs: 0,
      errorCode: 'slm_model_unavailable',
    );
  }
}
