import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, debugPrintStack;
import 'package:flutter/services.dart' show rootBundle;

/// 结构化标题数据模型
class StructuredTitleData {
  final String? subject;
  final String? action;
  final String? object;
  final String? topic;

  StructuredTitleData({
    this.subject,
    this.action,
    this.object,
    this.topic,
  });
}

/// 标题候选
class TitleCandidate {
  final String title;
  final double score;
  final String format;

  TitleCandidate({
    required this.title,
    required this.score,
    required this.format,
  });
}

/// 结构化标题生成结果
class StructuredTitleResult {
  final String title;
  final List<TitleCandidate> candidates;
  final StructuredTitleData structuredData;
  final double confidence;

  StructuredTitleResult({
    required this.title,
    required this.candidates,
    required this.structuredData,
    required this.confidence,
  });
}

/// 结构化记忆标题生成器
///
/// 实现完整的标题生成流程：
/// raw memory → 抽 subject / action / topic → canonical normalize
/// → 生成 2~3 个标题候选 → 打分选择 → 输出 title
class StructuredMemoryTitleGenerator {
  /// Topic Taxonomy 白名单 - 标准主题列表（运行时从外部文件加载）
  static Set<String> _topicTaxonomy = {};

  /// 同义词映射表（运行时从外部文件加载）
  static Map<String, String> _synonymMappings = {};

  /// 是否已加载配置
  static bool _isInitialized = false;

  /// 是否正在加载中
  static bool _isLoading = false;

  /// 获取当前可用的 Topic Taxonomy（优先返回已加载的，否则返回默认值）
  static Set<String> get _currentTopicTaxonomy {
    if (_isInitialized && _topicTaxonomy.isNotEmpty) {
      return _topicTaxonomy;
    }
    // 未初始化或为空时，立即返回默认配置
    return _defaultTopicTaxonomy;
  }

  /// 获取当前可用的同义词映射（优先返回已加载的，否则返回默认值）
  static Map<String, String> get _currentSynonymMappings {
    if (_isInitialized && _synonymMappings.isNotEmpty) {
      return _synonymMappings;
    }
    // 未初始化或为空时，立即返回默认配置
    return _defaultSynonymMappings;
  }

  /// 初始化并加载 Topic Taxonomy 配置
  static Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;

    _isLoading = true;
    try {
      debugPrint('📦 [TopicTaxonomy] 开始加载配置文件...');
      // 从 assets 加载配置文件
      final jsonString =
          await rootBundle.loadString('assets/config/topic_taxonomy.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // 解析主题分类
      final topicsJson = jsonData['topics'] as Map<String, dynamic>;
      final allTopics = <String>{};
      for (final category in topicsJson.values) {
        if (category is List) {
          allTopics.addAll(category.cast<String>());
        }
      }
      _topicTaxonomy = allTopics;

      // 解析同义词映射
      final synonymsJson = jsonData['synonyms'] as Map<String, dynamic>;
      final synonymMap = <String, String>{};
      synonymsJson.forEach((standardTopic, variants) {
        if (variants is List) {
          for (final variant in variants) {
            if (variant is String) {
              synonymMap[variant.toLowerCase()] = standardTopic;
            }
          }
        }
      });
      _synonymMappings = synonymMap;

      _isInitialized = true;
      debugPrint(
          '✅ [TopicTaxonomy] 加载成功：${_topicTaxonomy.length} 个主题，${_synonymMappings.length} 个同义词映射');
    } catch (e, stackTrace) {
      debugPrint('⚠️ [TopicTaxonomy] 加载失败：$e，使用默认配置');
      debugPrintStack(stackTrace: stackTrace);
      // 使用默认兜底配置
      _topicTaxonomy = _defaultTopicTaxonomy;
      _synonymMappings = _defaultSynonymMappings;
      _isInitialized = true;
    } finally {
      _isLoading = false;
    }
  }

  /// 默认 Topic Taxonomy（兜底配置）
  static const Set<String> _defaultTopicTaxonomy = {
    '软件开发',
    '移动开发',
    '前端开发',
    '后端开发',
    '架构设计',
    '数据库',
    'Flutter',
    'Dart',
    'Android',
    'iOS',
    'Python',
    'Java',
    'Bug 修复',
    '功能需求',
    '学习总结',
    '技术咨询',
    'RAG',
    'GraphRAG',
    'LLM',
    'SLM',
    'AI',
    'OCR',
  };

  /// 默认同义词映射（兜底配置）
  static const Map<String, String> _defaultSynonymMappings = {
    '编程': '软件开发',
    'coding': '软件开发',
    'app': '移动开发',
    'mobile': '移动开发',
    'rag': 'RAG',
    '检索增强生成': 'RAG',
    'graphrag': 'GraphRAG',
    '知识图谱': 'GraphRAG',
    'llm': 'LLM',
    '大语言模型': 'LLM',
    'ocr': 'OCR',
    '文字识别': 'OCR',
  };

  /// 格式基础分映射表
  static const Map<String, double> _formatBaseScores = {
    'subject_action': 0.9,
    'topic_action': 0.8,
    'object_action': 0.7,
  };

  /// 预编译的正则表达式模式
  static final List<RegExp> _subjectPatterns = [
    RegExp(r'(\w+(?:\s+\w+)*?)\s+的？\s*(?:设计 | 优化 | 实现 | 分析)',
        caseSensitive: false),
    RegExp(r'(\w+(?:\s+\w+)*?)\s+(?:for|about|on)', caseSensitive: false),
    RegExp(r'(\w+(?:-\w+)*)', caseSensitive: false),
  ];

  static final List<RegExp> _objectPatterns = [
    RegExp(r'(?:for|to|about)\s+(\w+(?:\s+\w+)*)', caseSensitive: false),
    RegExp(r'(\w+(?:\s+\w+)*?)\s+(?:系统 | 模块 | 组件 | 功能)', caseSensitive: false),
  ];

  static final List<RegExp> _topicPatterns = [
    RegExp(r'(\w+(?:\s+\w+)*?)\s+(?:系统 | 架构 | 设计 | 实现)', caseSensitive: false),
    RegExp(r'(\w+(?:-\w+)*)', caseSensitive: false),
  ];

  static const Set<String> _stopWords = {
    '关于',
    '一些',
    '讨论',
    '问题',
    '请问',
    '帮我',
    '请求',
    '需要',
    '想要',
    '希望',
    'the',
    'a',
    'an',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'being',
  };

  static const Set<String> _actionVerbs = {
    '设计',
    '优化',
    '实现',
    '分析',
    '开发',
    '创建',
    '修改',
    '修复',
    '重构',
    '测试',
    '部署',
    '配置',
    '学习',
    '研究',
    '探讨',
    '总结',
    '整理',
    'review',
    'design',
    'optimize',
    'implement',
    'analyze',
    'develop',
    'create',
    'modify',
    'fix',
    'refactor',
    'test',
    'deploy',
    'configure',
    'learn',
    'study',
    'discuss',
    'summarize',
  };

  static StructuredTitleResult generateTitle(String rawMemory) {
    final structuredData = _extractStructuredData(rawMemory);
    final normalizedData = _canonicalNormalize(structuredData);
    final candidates = _generateCandidates(normalizedData, rawMemory);
    final bestCandidate = _selectBestCandidate(candidates);
    final confidence = _calculateConfidence(normalizedData);

    return StructuredTitleResult(
      title: bestCandidate.title,
      candidates: candidates,
      structuredData: normalizedData,
      confidence: confidence,
    );
  }

  static StructuredTitleData _extractStructuredData(String rawMemory) {
    final cleanedMemory = _removeStopWords(rawMemory);
    final subject = _extractSubject(cleanedMemory);
    final action = _extractAction(cleanedMemory);
    final object = _extractObject(cleanedMemory);
    final topic = _extractTopic(cleanedMemory);

    return StructuredTitleData(
      subject: subject,
      action: action,
      object: object,
      topic: topic,
    );
  }

  static String _removeStopWords(String text) {
    var result = text;
    for (final word in _stopWords) {
      result =
          result.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '');
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String? _extractSubject(String text) {
    for (final pattern in _subjectPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final candidate = match.group(1)!.trim();
        if (candidate.length >= 2 && candidate.length <= 20) {
          return candidate;
        }
      }
    }
    return null;
  }

  static String? _extractAction(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    for (final word in words) {
      if (_actionVerbs.contains(word)) {
        return word;
      }
    }
    for (final verb in _actionVerbs) {
      if (text.toLowerCase().contains(verb)) {
        return verb;
      }
    }
    return null;
  }

  static String? _extractObject(String text) {
    for (final pattern in _objectPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final candidate = match.group(1)!.trim();
        if (candidate.length >= 2 && candidate.length <= 20) {
          return candidate;
        }
      }
    }
    return null;
  }

  static String? _extractTopic(String text) {
    final normalizedText = text.toLowerCase();
    final synonymMappings = _currentSynonymMappings;

    // 1. 优先从同义词映射中提取（关键词匹配）- 按长度降序排列，优先匹配长短语
    final sortedSynonyms = synonymMappings.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in sortedSynonyms) {
      // 使用单词边界匹配，避免误匹配（如 "ui" 被匹配到单词中的字母组合）
      final wordBoundaryRegex = RegExp(
        r'\b' + RegExp.escape(entry.key) + r'\b',
        caseSensitive: false,
      );
      if (wordBoundaryRegex.hasMatch(normalizedText)) {
        return entry.value;
      }
    }

    // 2. 使用原有的正则表达式模式提取
    for (final pattern in _topicPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final candidate = match.group(1)!.trim();
        if (candidate.length >= 2 && candidate.length <= 20) {
          return candidate;
        }
      }
    }

    // 3. 尝试从文本中提取名词短语作为 topic
    final words = text.split(RegExp(r'\s+'));
    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w\u4e00-\u9fa5]'), '');
      if (cleanWord.length >= 3 && cleanWord.length <= 20) {
        return cleanWord;
      }
    }

    return null;
  }

  static StructuredTitleData _canonicalNormalize(StructuredTitleData data) {
    return StructuredTitleData(
      subject: data.subject?.trim(),
      action: data.action?.trim(),
      object: data.object?.trim(),
      topic: _normalizeToCanonicalTopic(data.topic),
    );
  }

  /// 将主题映射到标准主题（canonical topic）
  static String? _normalizeToCanonicalTopic(String? topic) {
    if (topic == null || topic.trim().isEmpty) {
      return null;
    }

    final normalizedTopic = topic.trim().toLowerCase();
    final synonymMappings = _currentSynonymMappings;
    final topicTaxonomy = _currentTopicTaxonomy;

    // 1. 直接匹配同义词映射（精确匹配优先）
    if (synonymMappings.containsKey(normalizedTopic)) {
      return synonymMappings[normalizedTopic];
    }

    // 2. 完整单词匹配 - 检查是否包含同义词（按长度降序，优先匹配长短语）
    final sortedSynonyms = synonymMappings.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in sortedSynonyms) {
      // 使用单词边界匹配，避免部分匹配（如 "rag" 被匹配到 "graphrag"）
      final wordBoundaryRegex = RegExp(
        r'\b' + RegExp.escape(entry.key) + r'\b',
        caseSensitive: false,
      );
      if (wordBoundaryRegex.hasMatch(normalizedTopic)) {
        return entry.value;
      }
    }

    // 3. 检查是否在 Topic Taxonomy 白名单中（优化：缓存 lowercase 比较）
    for (final standardTopic in topicTaxonomy) {
      final lowerStandard = standardTopic.toLowerCase();
      if (lowerStandard == normalizedTopic ||
          lowerStandard.contains(normalizedTopic) ||
          normalizedTopic.contains(lowerStandard)) {
        return standardTopic;
      }
    }

    // 4. 无法匹配，返回原始主题
    return topic;
  }

  static const int _minTitleLength = 8;
  static const int _maxTitleLength = 20;

  /// 构建标题候选（优化：提取公共逻辑减少重复）
  static TitleCandidate _buildCandidate({
    required String part1,
    required String part2,
    required String format,
    required bool hasSubject,
    required bool hasTopic,
    required String rawMemory,
    double baseScore = 0.0,
  }) {
    final title = _compressTitle('$part1：$part2', rawMemory);
    final score = _calculateCandidateScore(
      format: format,
      hasSubject: hasSubject,
      hasAction: true,
      hasTopic: hasTopic,
      titleLength: title.length,
      baseScore: baseScore,
    );
    return TitleCandidate(title: title, score: score, format: format);
  }

  static List<TitleCandidate> _generateCandidates(
    StructuredTitleData data,
    String rawMemory,
  ) {
    final candidates = <TitleCandidate>[];

    // 候选 1: subject_action - 最高优先级
    if (data.subject != null && data.action != null) {
      candidates.add(_buildCandidate(
        part1: data.subject!,
        part2: data.action!,
        format: 'subject_action',
        hasSubject: true,
        hasTopic: data.topic != null,
        rawMemory: rawMemory,
      ));
    }

    // 候选 2: topic_action - 如果有标准主题，提高优先级
    if (data.topic != null && data.action != null) {
      final isCanonical = _isCanonicalTopic(data.topic!);
      candidates.add(_buildCandidate(
        part1: data.topic!,
        part2: data.action!,
        format: 'topic_action',
        hasSubject: false,
        hasTopic: true,
        rawMemory: rawMemory,
        baseScore: isCanonical ? 0.85 : 0.75,
      ));
    }

    // 候选 3: object_action
    if (data.object != null && data.action != null) {
      candidates.add(_buildCandidate(
        part1: data.object!,
        part2: data.action!,
        format: 'object_action',
        hasSubject: false,
        hasTopic: false,
        rawMemory: rawMemory,
      ));
    }

    // 备用方案
    if (candidates.isEmpty) {
      final fallback = _generateFallbackTitle(rawMemory);
      candidates.add(TitleCandidate(
        title: fallback,
        score: 0.5,
        format: 'fallback',
      ));
    }

    return candidates;
  }

  /// 计算候选标题得分（优化：使用 Map 替代 switch）
  static double _calculateCandidateScore({
    required String format,
    required bool hasSubject,
    required bool hasAction,
    required bool hasTopic,
    required int titleLength,
    double baseScore = 0.0,
  }) {
    var score = _formatBaseScores[format] ?? 0.5;

    // 长度奖励：符合 8-20 字范围
    if (titleLength >= _minTitleLength && titleLength <= _maxTitleLength) {
      score += 0.05;
    }

    // 信息完整性奖励
    if (hasSubject) score += 0.03;
    if (hasAction) score += 0.04;
    if (hasTopic) score += 0.03;

    return (score * 100).roundToDouble() / 100; // 保留两位小数
  }

  /// 检查是否是标准主题
  static bool _isCanonicalTopic(String topic) {
    final normalized = topic.trim().toLowerCase();
    final topicTaxonomy = _currentTopicTaxonomy;
    return topicTaxonomy.any((standard) =>
        standard.toLowerCase() == normalized ||
        standard.toLowerCase().contains(normalized) ||
        normalized.contains(standard.toLowerCase()));
  }

  /// 标题长度动态压缩（8-20 字）
  static String _compressTitle(String title, String rawMemory) {
    // 1. 如果已经在范围内，直接返回
    if (title.length >= _minTitleLength && title.length <= _maxTitleLength) {
      return title;
    }

    // 2. 太短则尝试从原文补充信息
    if (title.length < _minTitleLength) {
      return _enrichTitle(title, rawMemory);
    }

    // 3. 太长则压缩
    return _shortenTitle(title);
  }

  /// 丰富过短的标题（优化：使用更高效的关键词提取）
  static String _enrichTitle(String title, String rawMemory) {
    // 优先尝试名词/专业术语（通常更有信息量）
    final keywords = RegExp(r'[\w\u4e00-\u9fa5]{3,}')
        .allMatches(rawMemory)
        .map((m) => m.group(0)!)
        .where((w) => !title.contains(w));

    for (final keyword in keywords) {
      final enriched = '$title $keyword';
      if (enriched.length >= _minTitleLength &&
          enriched.length <= _maxTitleLength) {
        return enriched;
      }
    }

    // 无法 enrich，返回原标题
    return title;
  }

  /// 缩短过长的标题
  static String _shortenTitle(String title) {
    if (title.length <= _maxTitleLength) {
      return title;
    }

    // 1. 优先保留冒号前的部分
    final parts = title.split('：');
    if (parts.length > 1) {
      final mainPart = parts.first;
      if (mainPart.length <= _maxTitleLength) {
        return mainPart;
      }
      // 主部分也过长，截断
      return '${mainPart.substring(0, _maxTitleLength)}...';
    }

    // 2. 没有冒号，直接截断并添加省略号
    return '${title.substring(0, _maxTitleLength)}...';
  }

  static String _generateFallbackTitle(String rawMemory) {
    final cleaned = rawMemory.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= _maxTitleLength) {
      return cleaned;
    }
    return cleaned.substring(0, _maxTitleLength);
  }

  static TitleCandidate _selectBestCandidate(List<TitleCandidate> candidates) {
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.first;
  }

  static double _calculateConfidence(StructuredTitleData data) {
    var score = 0.0;

    if (data.subject != null) score += 0.25;
    if (data.action != null) score += 0.35;
    if (data.object != null) score += 0.2;
    if (data.topic != null) score += 0.2;

    return score;
  }
}
