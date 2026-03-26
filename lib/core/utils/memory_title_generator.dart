import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, debugPrintStack;
import 'package:flutter/services.dart' show rootBundle;

/// Structured title data model
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

/// Title candidate
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

/// Structured title generation result
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

/// Structured memory title generator
///
/// Implements complete title generation workflow:
/// raw memory → extract subject / action / topic → canonical normalize
/// → generate 2~3 title candidates → score selection → output title
class StructuredMemoryTitleGenerator {
  /// Topic Taxonomy whitelist - standard topic list (loaded from external file at runtime)
  static Set<String> _topicTaxonomy = {};

  /// Synonym mapping table (loaded from external file at runtime)
  static Map<String, String> _synonymMappings = {};

  /// Whether configuration is loaded
  static bool _isInitialized = false;

  /// Whether loading is in progress
  static bool _isLoading = false;

  /// Get currently available Topic Taxonomy (returns loaded if available, otherwise returns default)
  static Set<String> get _currentTopicTaxonomy {
    if (_isInitialized && _topicTaxonomy.isNotEmpty) {
      return _topicTaxonomy;
    }
    // Return default immediately when uninitialized or empty
    return _defaultTopicTaxonomy;
  }

  /// Get currently available synonym mappings (returns loaded if available, otherwise returns default)
  static Map<String, String> get _currentSynonymMappings {
    if (_isInitialized && _synonymMappings.isNotEmpty) {
      return _synonymMappings;
    }
    // Return default immediately when uninitialized or empty
    return _defaultSynonymMappings;
  }

  /// Initialize and load Topic Taxonomy configuration
  static Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;

    _isLoading = true;
    try {
      debugPrint('📦 [TopicTaxonomy] Loading configuration file...');
      // Load configuration from assets
      final jsonString =
          await rootBundle.loadString('assets/config/topic_taxonomy.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Parse topic taxonomy
      final topicsJson = jsonData['topics'] as Map<String, dynamic>;
      final allTopics = <String>{};
      for (final category in topicsJson.values) {
        if (category is List) {
          allTopics.addAll(category.cast<String>());
        }
      }
      _topicTaxonomy = allTopics;

      // Parse synonym mappings
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
          '✅ [TopicTaxonomy] Loaded successfully: ${_topicTaxonomy.length} topics, ${_synonymMappings.length} synonym mappings');
    } catch (e, stackTrace) {
      debugPrint(
          '⚠️ [TopicTaxonomy] Load failed: $e, using default configuration');
      debugPrintStack(stackTrace: stackTrace);
      // Use default fallback configuration
      _topicTaxonomy = _defaultTopicTaxonomy;
      _synonymMappings = _defaultSynonymMappings;
      _isInitialized = true;
    } finally {
      _isLoading = false;
    }
  }

  /// Default Topic Taxonomy (fallback configuration)
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

  /// Default synonym mappings (fallback configuration)
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

  /// Format base score mapping table
  static const Map<String, double> _formatBaseScores = {
    'subject_action': 0.9,
    'topic_action': 0.8,
    'object_action': 0.7,
  };

  /// Precompiled regular expression patterns
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

    // 1. Prioritize extraction from synonym mappings (keyword matching) - sorted by length descending, match longer phrases first
    final sortedSynonyms = synonymMappings.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in sortedSynonyms) {
      // Use word boundary matching to avoid false matches (e.g., "ui" matched to letter combinations in words)
      final wordBoundaryRegex = RegExp(
        r'\b' + RegExp.escape(entry.key) + r'\b',
        caseSensitive: false,
      );
      if (wordBoundaryRegex.hasMatch(normalizedText)) {
        return entry.value;
      }
    }

    // 2. Extract using existing regex patterns
    for (final pattern in _topicPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final candidate = match.group(1)!.trim();
        if (candidate.length >= 2 && candidate.length <= 20) {
          return candidate;
        }
      }
    }

    // 3. Try to extract noun phrases as topic from text
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

  /// Map topic to canonical topic
  static String? _normalizeToCanonicalTopic(String? topic) {
    if (topic == null || topic.trim().isEmpty) {
      return null;
    }

    final normalizedTopic = topic.trim().toLowerCase();
    final synonymMappings = _currentSynonymMappings;
    final topicTaxonomy = _currentTopicTaxonomy;

    // 1. Direct match in synonym mappings (exact match priority)
    if (synonymMappings.containsKey(normalizedTopic)) {
      return synonymMappings[normalizedTopic];
    }

    // 2. Full word match - check if contains synonyms (sorted by length descending, match longer phrases first)
    final sortedSynonyms = synonymMappings.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in sortedSynonyms) {
      // Use word boundary matching to avoid partial matches (e.g., "rag" matched to "graphrag")
      final wordBoundaryRegex = RegExp(
        r'\b' + RegExp.escape(entry.key) + r'\b',
        caseSensitive: false,
      );
      if (wordBoundaryRegex.hasMatch(normalizedTopic)) {
        return entry.value;
      }
    }

    // 3. Check if in Topic Taxonomy whitelist (optimized: cache lowercase comparison)
    for (final standardTopic in topicTaxonomy) {
      final lowerStandard = standardTopic.toLowerCase();
      if (lowerStandard == normalizedTopic ||
          lowerStandard.contains(normalizedTopic) ||
          normalizedTopic.contains(lowerStandard)) {
        return standardTopic;
      }
    }

    // 4. Unable to match, return original topic
    return topic;
  }

  static const int _minTitleLength = 8;
  static const int _maxTitleLength = 20;

  /// Build title candidate (optimized: extract common logic to reduce duplication)
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

    // Candidate 1: subject_action - highest priority
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

    // Candidate 2: topic_action - if has standard topic, increase priority
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

    // Candidate 3: object_action
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

    // Fallback
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

  /// Calculate candidate title score (optimized: use Map instead of switch)
  static double _calculateCandidateScore({
    required String format,
    required bool hasSubject,
    required bool hasAction,
    required bool hasTopic,
    required int titleLength,
    double baseScore = 0.0,
  }) {
    var score = _formatBaseScores[format] ?? 0.5;

    // Length reward:符合 8-20 character range
    if (titleLength >= _minTitleLength && titleLength <= _maxTitleLength) {
      score += 0.05;
    }

    // Information completeness reward
    if (hasSubject) score += 0.03;
    if (hasAction) score += 0.04;
    if (hasTopic) score += 0.03;

    return (score * 100).roundToDouble() / 100; // Keep two decimal places
  }

  /// Check if it's a canonical topic
  static bool _isCanonicalTopic(String topic) {
    final normalized = topic.trim().toLowerCase();
    final topicTaxonomy = _currentTopicTaxonomy;
    return topicTaxonomy.any((standard) =>
        standard.toLowerCase() == normalized ||
        standard.toLowerCase().contains(normalized) ||
        normalized.contains(standard.toLowerCase()));
  }

  /// Title length dynamic compression (8-20 characters)
  static String _compressTitle(String title, String rawMemory) {
    // 1. Return directly if already in range
    if (title.length >= _minTitleLength && title.length <= _maxTitleLength) {
      return title;
    }

    // 2. If too short, try to supplement information from original text
    if (title.length < _minTitleLength) {
      return _enrichTitle(title, rawMemory);
    }

    // 3. Compress if too long
    return _shortenTitle(title);
  }

  /// Enrich overly short titles (optimized: more efficient keyword extraction)
  static String _enrichTitle(String title, String rawMemory) {
    // Prefer nouns/professional terms (usually more informative)
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

    // Unable to enrich, return original title
    return title;
  }

  /// Shorten overly long titles
  static String _shortenTitle(String title) {
    if (title.length <= _maxTitleLength) {
      return title;
    }

    // 1. Prefer to keep the part before colon
    final parts = title.split(':');
    if (parts.length > 1) {
      final mainPart = parts.first;
      if (mainPart.length <= _maxTitleLength) {
        return mainPart;
      }
      // Main part also too long, truncate
      return '${mainPart.substring(0, _maxTitleLength)}...';
    }

    // 2. No colon, directly truncate and add ellipsis
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
