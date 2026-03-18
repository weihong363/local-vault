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
      emptyFieldPlaceholder:
          json['emptyFieldPlaceholder'] as String? ?? '(empty)',
      titleLabel: json['titleLabel'] as String? ?? 'Title',
      tagsLabel: json['tagsLabel'] as String? ?? 'Tags',
      contentLabel: json['contentLabel'] as String? ?? 'Content',
      mergeSessionEntry: json['mergeSessionEntry'] as String? ??
          'Record {{index}}\n'
              '{{titleLabel}}: {{title}}\n'
              '{{contentLabel}}: {{content}}\n'
              '{{tagsLabel}}: {{tags}}\n',
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
      summaryMetadataTitle:
          json['summaryMetadataTitle'] as String? ?? 'Pending Summary',
      emptyFactTitle: json['emptyFactTitle'] as String? ?? 'Untitled Fact',
      emptyChineseTopic:
          json['emptyChineseTopic'] as String? ?? 'Temporary Topic',
      emptyEnglishTopic:
          json['emptyEnglishTopic'] as String? ?? 'General topic',
      upgradeReasonHighAccess: json['upgradeReasonHighAccess'] as String? ??
          'This memory is accessed frequently and has demonstrated stable long-term value, making it a good candidate for promotion to core memory.',
      upgradeReasonHighImportance: json['upgradeReasonHighImportance']
              as String? ??
          'This memory has a high importance score and is worth retaining as a long-term core memory.',
      upgradeReasonDefault: json['upgradeReasonDefault'] as String? ??
          'This memory already shows lasting value, and promoting it will give it more stable retention and retrieval priority.',
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
      summaryMetadataTitle: 'Pending Summary',
      emptyFactTitle: 'Untitled Fact',
      emptyChineseTopic: 'Temporary Topic',
      emptyEnglishTopic: 'General topic',
      upgradeReasonHighAccess:
          'This memory is accessed frequently and has demonstrated stable long-term value, making it a good candidate for promotion to core memory.',
      upgradeReasonHighImportance:
          'This memory has a high importance score and is worth retaining as a long-term core memory.',
      upgradeReasonDefault:
          'This memory already shows lasting value, and promoting it will give it more stable retention and retrieval priority.',
    ),
    formatting: MemorySlmFormattingValues(
      emptyFieldPlaceholder: '(empty)',
      titleLabel: 'Title',
      tagsLabel: 'Tags',
      contentLabel: 'Content',
      mergeSessionEntry: 'Record {{index}}\n'
          '{{titleLabel}}: {{title}}\n'
          '{{contentLabel}}: {{content}}\n'
          '{{tagsLabel}}: {{tags}}\n',
    ),
    prompts: MemorySlmPrompts(
      extractTopic: '''
Role: memory organization assistant
Task: extract one precise topic label from the following title and content.
Requirements:
- Output exactly one topic label
- Follow the main language of the input
- Do not use punctuation
- Keep it concise

{{titleLabel}}: {{title}}
{{contentLabel}}: {{content}}''',
      sameTopic: '''
Role: text similarity judge
Task: determine whether two pieces of text discuss the same topic.
Requirements:
- Answer only "yes" or "no"

Text A {{titleLabel}}: {{titleA}}
Text A {{contentLabel}}: {{contentA}}

Text B {{titleLabel}}: {{titleB}}
Text B {{contentLabel}}: {{contentB}}''',
      mergeSessions: '''
Role: information organization specialist
Task: merge multiple records into one structured fact memory.
Output must strictly follow this format:
{{titleLabel}}: no more than 10 words
{{tagsLabel}}: tag 1, tag 2, tag 3
{{contentLabel}}:
Use 1 to 3 paragraphs to summarize the merged core information, with a total length under 300 words.

{{entries}}''',
      upgradeReason: '''
Role: memory management advisor
Task: explain why this memory deserves promotion to core memory.
{{outputLanguageInstruction}}
Requirements:
- Output only one sentence
- Keep the tone positive and specific

{{titleLabel}}: {{title}}
{{accessCountLabel}}: {{accessCount}}
{{importanceLabel}}: {{importance}}
{{createdAtLabel}}: {{createdAt}}''',
      summaryMetadata: '''
Role: Local Vault summary organization assistant
Task: decide how this record should be named and tagged based only on the main content, then produce one retrieval-friendly title and 2 to 4 tags.
The output is shown directly to the user, so it must be natural, searchable, and reusable.
Requirements:
- Existing title and tags are reference only; if they conflict with the content, rewrite them based on the content
- Identify the core topic, entity, event, conclusion, or task before generating the title
- Ignore operational phrasing such as "please help me", "note this", "need", "confirm", "arrange", "handle", or "update"
- If the content is a meeting or sync note, prefer "topic + context" in the title
- If the content is a task or to-do item, prefer "object + goal/action" in the title
- If the content is about a problem, plan, or decision, prefer "object + problem/plan/decision" in the title
- The title should read like something the user would actively search for later, not a vague or journal-like phrase
- Keep Chinese titles within 6 to 14 characters when possible, and no more than 18 if necessary; keep English titles within 8 words
- Tags must be nouns or short phrases, never full sentences
- Tags should cover different dimensions such as topic, object, action, and status while avoiding synonyms
- Avoid vague tags such as "content", "summary", "record", "item", "problem", "requirement", or "update" unless they are truly central to the content
- If the content includes explicit entities, project names, module names, meeting topics, or task objects, surface them in the title or tags when possible
- Output must strictly follow this format:
{{titleLabel}}: ...
{{tagsLabel}}: tag 1, tag 2, tag 3

Existing {{titleLabel}}: {{title}}
Existing {{tagsLabel}}: {{tags}}
Main content:
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
      debugPrint(
        '⚠️ [MemorySlmConfig] Failed to read bundled config. Falling back to defaults: $error',
      );
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
        '⚠️ [MemorySlmConfig] Failed to read override config. Continuing with bundled config: $error',
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
