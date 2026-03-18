import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/services/memory_slm_config.dart';

void main() {
  group('MemorySlmConfig', () {
    test('parses config json and renders prompt placeholders', () {
      final config = MemorySlmConfig.fromJson(const <String, dynamic>{
        'model': <String, dynamic>{
          'bundledFileName': 'test.gguf',
          'bundledAssetPath': 'models/test.gguf',
          'modelDirectoryName': 'custom_models',
          'cacheDirectoryName': 'custom_cache',
        },
        'runtime': <String, dynamic>{
          'requestTimeoutSeconds': 8,
          'maxQueueWaitSeconds': 6,
          'maxCacheEntries': 32,
          'maxTokens': 96,
          'temperature': 0.1,
          'topK': 20,
        },
        'limits': <String, dynamic>{
          'topicContentChars': 111,
          'sameTopicContentChars': 77,
          'mergeItemContentChars': 88,
          'summaryMetadataContentChars': 222,
          'mergeResultTagCount': 6,
          'summaryMetadataTagCount': 3,
          'fallbackMergeTagCount': 2,
          'topicChineseMinChars': 3,
          'topicChineseMaxChars': 7,
          'fallbackChineseTopicChars': 5,
          'topicEnglishWordCount': 2,
        },
        'heuristics': <String, dynamic>{
          'sameTopicMinTagOverlap': 4,
          'upgradeAccessCountThreshold': 12,
          'upgradeImportanceThreshold': 0.9,
        },
        'fallbacks': <String, dynamic>{
          'summaryMetadataTitle': '待整理',
          'emptyFactTitle': '空事实',
          'emptyChineseTopic': '默认主题',
          'emptyEnglishTopic': 'Default topic',
          'upgradeReasonHighAccess': '高频访问',
          'upgradeReasonHighImportance': '高重要性',
          'upgradeReasonDefault': '默认升级原因',
        },
        'formatting': <String, dynamic>{
          'emptyFieldPlaceholder': 'N/A',
          'titleLabel': '题目',
          'tagsLabel': '关键词',
          'contentLabel': '正文',
          'mergeSessionEntry':
              '第{{index}}条\n{{titleLabel}}={{title}}\n{{contentLabel}}={{content}}\n{{tagsLabel}}={{tags}}',
        },
        'prompts': <String, dynamic>{
          'extractTopic':
              '{{titleLabel}}：{{title}} {{contentLabel}}：{{content}}',
          'sameTopic': 'A={{titleA}} B={{titleB}} {{contentLabel}}',
          'mergeSessions': '{{entries}}',
          'upgradeReason': '{{title}}',
          'summaryMetadata':
              '{{titleLabel}}={{title}} {{tagsLabel}}={{tags}} {{contentLabel}}={{content}}',
        },
      });

      expect(config.model.bundledFileName, 'test.gguf');
      expect(config.runtime.maxTokens, 96);
      expect(config.limits.summaryMetadataContentChars, 222);
      expect(config.limits.mergeResultTagCount, 6);
      expect(config.heuristics.sameTopicMinTagOverlap, 4);
      expect(config.fallbacks.emptyFactTitle, '空事实');
      expect(config.fallbacks.upgradeReasonDefault, '默认升级原因');
      expect(config.formatting.titleLabel, '题目');
      expect(
        config.renderTemplate(
          config.prompts.summaryMetadata,
          const <String, String>{
            'titleLabel': '题目',
            'tagsLabel': '关键词',
            'contentLabel': '正文',
            'title': '周会纪要',
            'tags': '项目进展',
            'content': '确认发布计划',
          },
        ),
        '题目=周会纪要 关键词=项目进展 正文=确认发布计划',
      );
      expect(
        config.renderTemplate(
          config.formatting.mergeSessionEntry,
          const <String, String>{
            'index': '1',
            'titleLabel': '题目',
            'tagsLabel': '关键词',
            'contentLabel': '正文',
            'title': '发布计划',
            'tags': '灰度, 回滚',
            'content': '确认发布时间',
          },
        ),
        '第1条\n题目=发布计划\n正文=确认发布时间\n关键词=灰度, 回滚',
      );
    });

    test('runtime overrides replace bundled numeric values', () {
      final config = MemorySlmConfig.fallback.withRuntimeOverrides(
        requestTimeout: const Duration(seconds: 5),
        maxQueueWait: const Duration(seconds: 7),
        maxCacheEntries: 16,
        maxTokens: 64,
        temperature: 0.05,
        topK: 12,
      );

      expect(config.requestTimeout, const Duration(seconds: 5));
      expect(config.maxQueueWait, const Duration(seconds: 7));
      expect(config.runtime.maxCacheEntries, 16);
      expect(config.runtime.maxTokens, 64);
      expect(config.runtime.temperature, 0.05);
      expect(config.runtime.topK, 12);
    });
  });
}
