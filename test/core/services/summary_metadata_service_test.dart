import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:local_vault/core/services/summary_metadata_service.dart';
import 'package:local_vault/core/utils/summary_text_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SummaryMetadataService', () {
    test('save uses refined local rules when SLM inference is disabled',
        () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'slm_inference_enabled': false,
      });

      final service = SummaryMetadataService(
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

    test('save still falls back to local rules when SLM inference is enabled',
        () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'slm_inference_enabled': true,
      });

      final service = SummaryMetadataService(
        settingsService: AppSettingsService(),
      );

      final draft = await service.prepareForSave(
        content: '原始摘要内容，用于验证当前占位 SLM 入口不会改变保存效果。',
      );

      expect(draft.usedModel, isFalse);
      expect(draft.title, isNot(SummaryTextUtils.unnamedTitle));
      expect(draft.title, isNot('SLM 自检摘要'));
      expect(draft.tags, isNotEmpty);
    });

    test('preview mode regenerates metadata from content even if form has text',
        () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'slm_inference_enabled': true,
      });

      final service = SummaryMetadataService(
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

    test('remark marker uses language-neutral separator', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'slm_inference_enabled': false,
      });

      final service = SummaryMetadataService(
        settingsService: AppSettingsService(),
      );

      final draft = await service.prepareForSave(
        content: 'Discuss release readiness.',
        remark: 'Need rollback steps.',
      );

      expect(draft.content, contains('---Remark---'));
      expect(draft.content, isNot(contains('---备注---')));
    });
  });
}
