import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class MemorySlmPrompts {
  const MemorySlmPrompts({
    required this.extractTopic,
    required this.sameTopic,
    required this.mergeSessions,
    required this.upgradeReason,
    required this.summaryMetadata,
  });

  final String extractTopic;
  final String sameTopic;
  final String mergeSessions;
  final String upgradeReason;
  final String summaryMetadata;

  factory MemorySlmPrompts.fromJson(Map<String, dynamic> json) {
    return MemorySlmPrompts(
      extractTopic: json['extractTopic'] as String? ?? '',
      sameTopic: json['sameTopic'] as String? ?? '',
      mergeSessions: json['mergeSessions'] as String? ?? '',
      upgradeReason: json['upgradeReason'] as String? ?? '',
      summaryMetadata: json['summaryMetadata'] as String? ?? '',
    );
  }
}

class MemorySlmFormattingValues {
  const MemorySlmFormattingValues({
    required this.emptyFieldPlaceholder,
    required this.titleLabel,
    required this.tagsLabel,
    required this.contentLabel,
    required this.mergeSessionEntry,
  });

  final String emptyFieldPlaceholder;
  final String titleLabel;
  final String tagsLabel;
  final String contentLabel;
  final String mergeSessionEntry;

  factory MemorySlmFormattingValues.fromJson(Map<String, dynamic> json) {
    return MemorySlmFormattingValues(
      emptyFieldPlaceholder: json['emptyFieldPlaceholder'] as String? ?? '（空）',
      titleLabel: json['titleLabel'] as String? ?? '标题',
      tagsLabel: json['tagsLabel'] as String? ?? '标签',
      contentLabel: json['contentLabel'] as String? ?? '内容',
      mergeSessionEntry: json['mergeSessionEntry'] as String? ??
          '记录 {{index}}\n'
              '{{titleLabel}}：{{title}}\n'
              '{{contentLabel}}：{{content}}\n'
              '{{tagsLabel}}：{{tags}}\n',
    );
  }
}

class MemorySlmPromptLimits {
  const MemorySlmPromptLimits({
    required this.topicContentChars,
    required this.sameTopicContentChars,
    required this.mergeItemContentChars,
    required this.summaryMetadataContentChars,
    required this.mergeResultTagCount,
    required this.summaryMetadataTagCount,
    required this.fallbackMergeTagCount,
    required this.topicChineseMinChars,
    required this.topicChineseMaxChars,
    required this.fallbackChineseTopicChars,
    required this.topicEnglishWordCount,
  });

  final int topicContentChars;
  final int sameTopicContentChars;
  final int mergeItemContentChars;
  final int summaryMetadataContentChars;
  final int mergeResultTagCount;
  final int summaryMetadataTagCount;
  final int fallbackMergeTagCount;
  final int topicChineseMinChars;
  final int topicChineseMaxChars;
  final int fallbackChineseTopicChars;
  final int topicEnglishWordCount;

  factory MemorySlmPromptLimits.fromJson(Map<String, dynamic> json) {
    return MemorySlmPromptLimits(
      topicContentChars: json['topicContentChars'] as int? ?? 240,
      sameTopicContentChars: json['sameTopicContentChars'] as int? ?? 120,
      mergeItemContentChars: json['mergeItemContentChars'] as int? ?? 180,
      summaryMetadataContentChars:
          json['summaryMetadataContentChars'] as int? ?? 420,
      mergeResultTagCount: json['mergeResultTagCount'] as int? ?? 5,
      summaryMetadataTagCount: json['summaryMetadataTagCount'] as int? ?? 4,
      fallbackMergeTagCount: json['fallbackMergeTagCount'] as int? ?? 5,
      topicChineseMinChars: json['topicChineseMinChars'] as int? ?? 2,
      topicChineseMaxChars: json['topicChineseMaxChars'] as int? ?? 8,
      fallbackChineseTopicChars: json['fallbackChineseTopicChars'] as int? ?? 6,
      topicEnglishWordCount: json['topicEnglishWordCount'] as int? ?? 3,
    );
  }
}

class MemorySlmHeuristics {
  const MemorySlmHeuristics({
    required this.sameTopicMinTagOverlap,
    required this.upgradeAccessCountThreshold,
    required this.upgradeImportanceThreshold,
  });

  final int sameTopicMinTagOverlap;
  final int upgradeAccessCountThreshold;
  final double upgradeImportanceThreshold;

  factory MemorySlmHeuristics.fromJson(Map<String, dynamic> json) {
    return MemorySlmHeuristics(
      sameTopicMinTagOverlap: json['sameTopicMinTagOverlap'] as int? ?? 2,
      upgradeAccessCountThreshold:
          json['upgradeAccessCountThreshold'] as int? ?? 10,
      upgradeImportanceThreshold:
          (json['upgradeImportanceThreshold'] as num?)?.toDouble() ?? 0.8,
    );
  }
}

class MemorySlmRuntimeValues {
  const MemorySlmRuntimeValues({
    required this.requestTimeoutSeconds,
    required this.maxQueueWaitSeconds,
    required this.maxCacheEntries,
    required this.maxTokens,
    required this.temperature,
    required this.topK,
  });

  final int requestTimeoutSeconds;
  final int maxQueueWaitSeconds;
  final int maxCacheEntries;
  final int maxTokens;
  final double temperature;
  final int topK;

  factory MemorySlmRuntimeValues.fromJson(Map<String, dynamic> json) {
    return MemorySlmRuntimeValues(
      requestTimeoutSeconds: json['requestTimeoutSeconds'] as int? ?? 10,
      maxQueueWaitSeconds: json['maxQueueWaitSeconds'] as int? ?? 10,
      maxCacheEntries: json['maxCacheEntries'] as int? ?? 128,
      maxTokens: json['maxTokens'] as int? ?? 128,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.2,
      topK: json['topK'] as int? ?? 40,
    );
  }
}

class MemorySlmModelPaths {
  const MemorySlmModelPaths({
    required this.bundledFileName,
    required this.bundledAssetPath,
    required this.modelDirectoryName,
    required this.cacheDirectoryName,
  });

  final String bundledFileName;
  final String bundledAssetPath;
  final String modelDirectoryName;
  final String cacheDirectoryName;

  factory MemorySlmModelPaths.fromJson(Map<String, dynamic> json) {
    return MemorySlmModelPaths(
      bundledFileName: json['bundledFileName'] as String? ??
          'qwen2.5-0.5b-instruct-q4_k_m.gguf',
      bundledAssetPath: json['bundledAssetPath'] as String? ??
          'models/qwen2.5-0.5b-instruct-q4_k_m.gguf',
      modelDirectoryName: json['modelDirectoryName'] as String? ?? 'models',
      cacheDirectoryName:
          json['cacheDirectoryName'] as String? ?? 'mediapipe_cache',
    );
  }
}

class MemorySlmFallbackValues {
  const MemorySlmFallbackValues({
    required this.summaryMetadataTitle,
    required this.emptyFactTitle,
    required this.emptyChineseTopic,
    required this.emptyEnglishTopic,
    required this.upgradeReasonHighAccess,
    required this.upgradeReasonHighImportance,
    required this.upgradeReasonDefault,
  });

  final String summaryMetadataTitle;
  final String emptyFactTitle;
  final String emptyChineseTopic;
  final String emptyEnglishTopic;
  final String upgradeReasonHighAccess;
  final String upgradeReasonHighImportance;
  final String upgradeReasonDefault;

  factory MemorySlmFallbackValues.fromJson(Map<String, dynamic> json) {
    return MemorySlmFallbackValues(
      summaryMetadataTitle: json['summaryMetadataTitle'] as String? ?? '待整理摘要',
      emptyFactTitle: json['emptyFactTitle'] as String? ?? '未命名事实',
      emptyChineseTopic: json['emptyChineseTopic'] as String? ?? '临时主题',
      emptyEnglishTopic:
          json['emptyEnglishTopic'] as String? ?? 'General topic',
      upgradeReasonHighAccess: json['upgradeReasonHighAccess'] as String? ??
          '这条记忆被频繁访问，已经表现出稳定的长期价值，适合升级为核心记忆。',
      upgradeReasonHighImportance:
          json['upgradeReasonHighImportance'] as String? ??
              '这条记忆的重要性评分很高，值得作为核心记忆长期保留。',
      upgradeReasonDefault: json['upgradeReasonDefault'] as String? ??
          '这条记忆已经具备持续价值，升级后可以获得更稳定的保存与检索优先级。',
    );
  }
}

class MemorySlmConfig {
  const MemorySlmConfig({
    required this.model,
    required this.runtime,
    required this.limits,
    required this.heuristics,
    required this.fallbacks,
    required this.formatting,
    required this.prompts,
  });

  static const String bundledConfigAssetPath = 'assets/config/slm_config.json';
  static const String overrideDirectoryName = 'slm';
  static const String overrideFileName = 'slm_config.override.json';

  static const MemorySlmConfig fallback = MemorySlmConfig(
    model: MemorySlmModelPaths(
      bundledFileName: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
      bundledAssetPath: 'models/qwen2.5-0.5b-instruct-q4_k_m.gguf',
      modelDirectoryName: 'models',
      cacheDirectoryName: 'mediapipe_cache',
    ),
    runtime: MemorySlmRuntimeValues(
      requestTimeoutSeconds: 10,
      maxQueueWaitSeconds: 10,
      maxCacheEntries: 128,
      maxTokens: 128,
      temperature: 0.2,
      topK: 40,
    ),
    limits: MemorySlmPromptLimits(
      topicContentChars: 240,
      sameTopicContentChars: 120,
      mergeItemContentChars: 180,
      summaryMetadataContentChars: 420,
      mergeResultTagCount: 5,
      summaryMetadataTagCount: 4,
      fallbackMergeTagCount: 5,
      topicChineseMinChars: 2,
      topicChineseMaxChars: 8,
      fallbackChineseTopicChars: 6,
      topicEnglishWordCount: 3,
    ),
    heuristics: MemorySlmHeuristics(
      sameTopicMinTagOverlap: 2,
      upgradeAccessCountThreshold: 10,
      upgradeImportanceThreshold: 0.8,
    ),
    fallbacks: MemorySlmFallbackValues(
      summaryMetadataTitle: '待整理摘要',
      emptyFactTitle: '未命名事实',
      emptyChineseTopic: '临时主题',
      emptyEnglishTopic: 'General topic',
      upgradeReasonHighAccess: '这条记忆被频繁访问，已经表现出稳定的长期价值，适合升级为核心记忆。',
      upgradeReasonHighImportance: '这条记忆的重要性评分很高，值得作为核心记忆长期保留。',
      upgradeReasonDefault: '这条记忆已经具备持续价值，升级后可以获得更稳定的保存与检索优先级。',
    ),
    formatting: MemorySlmFormattingValues(
      emptyFieldPlaceholder: '（空）',
      titleLabel: '标题',
      tagsLabel: '标签',
      contentLabel: '内容',
      mergeSessionEntry: '记录 {{index}}\n'
          '{{titleLabel}}：{{title}}\n'
          '{{contentLabel}}：{{content}}\n'
          '{{tagsLabel}}：{{tags}}\n',
    ),
    prompts: MemorySlmPrompts(
      extractTopic: '''
角色：记忆整理助手
任务：从以下标题和内容中提取一个精确的主题标签。
要求：
- 只输出一个主题标签
- 输出语言跟随输入主语言
- 不要使用标点符号
- 尽量简洁

{{titleLabel}}：{{title}}
{{contentLabel}}：{{content}}''',
      sameTopic: '''
角色：文本相似度判断助手
任务：判断两段文字是否讨论同一主题。
要求：
- 只回答“是”或“否”

文本 A {{titleLabel}}：{{titleA}}
文本 A {{contentLabel}}：{{contentA}}

文本 B {{titleLabel}}：{{titleB}}
文本 B {{contentLabel}}：{{contentB}}''',
      mergeSessions: '''
角色：信息整理专家
任务：将多条记录合并为一条结构化事实记忆。
严格按以下格式输出：
{{titleLabel}}：不超过 10 个字
{{tagsLabel}}：标签1, 标签2, 标签3
{{contentLabel}}：
用 1 到 3 段话整理出合并后的核心信息，总字数控制在 300 字以内。

{{entries}}''',
      upgradeReason: '''
角色：记忆管理顾问
任务：解释为什么这条记忆值得升级为核心记忆。
要求：
- 只输出一句话
- 语气积极、具体

{{titleLabel}}：{{title}}
访问次数：{{accessCount}}
重要性：{{importance}}
创建时间：{{createdAt}}''',
      summaryMetadata: '''
角色：本地记忆库的摘要整理助手
任务：只根据正文内容判断“这条记录最值得被怎样命名、怎样打标签”，产出一个适合长期检索的标题和 2 到 4 个标签。
你的输出会直接展示给用户，所以必须语义自然、可检索、可复用。
要求：
- 现有标题和标签仅供参考；如果和正文不一致，必须以正文为准直接改写
- 先判断正文最核心的主题、对象、事件、结论或待办，再生成标题
- 忽略“请帮我、记录一下、需要、确认、安排、处理、更新”这类操作口吻
- 如果正文是会议/同步，标题优先写“主题 + 场景”
- 如果正文是任务/待办，标题优先写“对象 + 目标/动作”
- 如果正文是问题/方案/决定，标题优先写“对象 + 问题/方案/决定”
- 标题要像用户之后会主动搜索的名字，避免空泛词和流水账
- 中文标题优先控制在 6 到 14 个字，必要时不超过 18 个字；英文不超过 8 个单词
- 标签必须是名词或短语，不能是完整句子
- 标签优先覆盖不同维度：主题、对象、动作、状态；避免同义重复
- 不要输出“内容、摘要、记录、事项、问题、需求、更新”这类空泛标签，除非正文核心就真是它
- 如果正文里有明确实体、项目名、模块名、会议主题、任务对象，优先体现在标题或标签里
- 严格按以下格式输出：
{{titleLabel}}：...
{{tagsLabel}}：标签1, 标签2, 标签3

现有{{titleLabel}}：{{title}}
现有{{tagsLabel}}：{{tags}}
正文：
{{content}}''',
    ),
  );

  final MemorySlmModelPaths model;
  final MemorySlmRuntimeValues runtime;
  final MemorySlmPromptLimits limits;
  final MemorySlmHeuristics heuristics;
  final MemorySlmFallbackValues fallbacks;
  final MemorySlmFormattingValues formatting;
  final MemorySlmPrompts prompts;

  Duration get requestTimeout =>
      Duration(seconds: runtime.requestTimeoutSeconds);

  Duration get maxQueueWait => Duration(seconds: runtime.maxQueueWaitSeconds);

  MemorySlmConfig copyWith({
    MemorySlmModelPaths? model,
    MemorySlmRuntimeValues? runtime,
    MemorySlmPromptLimits? limits,
    MemorySlmHeuristics? heuristics,
    MemorySlmFallbackValues? fallbacks,
    MemorySlmFormattingValues? formatting,
    MemorySlmPrompts? prompts,
  }) {
    return MemorySlmConfig(
      model: model ?? this.model,
      runtime: runtime ?? this.runtime,
      limits: limits ?? this.limits,
      heuristics: heuristics ?? this.heuristics,
      fallbacks: fallbacks ?? this.fallbacks,
      formatting: formatting ?? this.formatting,
      prompts: prompts ?? this.prompts,
    );
  }

  MemorySlmConfig withRuntimeOverrides({
    Duration? requestTimeout,
    Duration? maxQueueWait,
    int? maxCacheEntries,
    int? maxTokens,
    double? temperature,
    int? topK,
  }) {
    return copyWith(
      runtime: MemorySlmRuntimeValues(
        requestTimeoutSeconds:
            requestTimeout?.inSeconds ?? runtime.requestTimeoutSeconds,
        maxQueueWaitSeconds:
            maxQueueWait?.inSeconds ?? runtime.maxQueueWaitSeconds,
        maxCacheEntries: maxCacheEntries ?? runtime.maxCacheEntries,
        maxTokens: maxTokens ?? runtime.maxTokens,
        temperature: temperature ?? runtime.temperature,
        topK: topK ?? runtime.topK,
      ),
    );
  }

  factory MemorySlmConfig.fromJson(Map<String, dynamic> json) {
    return MemorySlmConfig(
      model: MemorySlmModelPaths.fromJson(
        _asMap(json['model']),
      ),
      runtime: MemorySlmRuntimeValues.fromJson(
        _asMap(json['runtime']),
      ),
      limits: MemorySlmPromptLimits.fromJson(
        _asMap(json['limits']),
      ),
      heuristics: MemorySlmHeuristics.fromJson(
        _asMap(json['heuristics']),
      ),
      fallbacks: MemorySlmFallbackValues.fromJson(
        _asMap(json['fallbacks']),
      ),
      formatting: MemorySlmFormattingValues.fromJson(
        _asMap(json['formatting']),
      ),
      prompts: MemorySlmPrompts.fromJson(
        _asMap(json['prompts']),
      ),
    );
  }

  static Future<MemorySlmConfig> load() async {
    Map<String, dynamic> merged = <String, dynamic>{};

    try {
      final bundledRaw = await rootBundle.loadString(bundledConfigAssetPath);
      merged = _asMap(jsonDecode(bundledRaw));
    } catch (error, stackTrace) {
      debugPrint('⚠️ [MemorySlmConfig] 读取内置配置失败，回退到默认配置: $error');
      debugPrintStack(stackTrace: stackTrace);
      return fallback;
    }

    try {
      final overrideFile = await resolveOverrideFile();
      if (await overrideFile.exists()) {
        final overrideRaw = await overrideFile.readAsString();
        final overrideJson = _asMap(jsonDecode(overrideRaw));
        merged = _deepMerge(merged, overrideJson);
      }
    } catch (error, stackTrace) {
      debugPrint(
        '⚠️ [MemorySlmConfig] 读取覆盖配置失败，将继续使用内置配置: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }

    return MemorySlmConfig.fromJson(merged);
  }

  static Future<File> resolveOverrideFile() async {
    final appSupportDirectory = await getApplicationSupportDirectory();
    final slmDirectory = Directory(
      '${appSupportDirectory.path}/$overrideDirectoryName',
    );
    if (!await slmDirectory.exists()) {
      await slmDirectory.create(recursive: true);
    }
    return File('${slmDirectory.path}/$overrideFileName');
  }

  String renderTemplate(
    String template,
    Map<String, String> variables,
  ) {
    var rendered = template;
    variables.forEach((key, value) {
      rendered = rendered.replaceAll('{{$key}}', value);
    });
    return rendered;
  }

  static Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) {
        return MapEntry(key.toString(), value);
      });
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> override,
  ) {
    final merged = Map<String, dynamic>.from(base);
    override.forEach((key, value) {
      final current = merged[key];
      if (current is Map && value is Map) {
        merged[key] = _deepMerge(
          _asMap(current),
          _asMap(value),
        );
      } else {
        merged[key] = value;
      }
    });
    return merged;
  }
}
