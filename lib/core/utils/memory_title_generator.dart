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

  static const int _maxTitleLength = 25;

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
    final patterns = [
      RegExp(r'(\w+(?:\s+\w+)*?)\s+的?\s*(?:设计|优化|实现|分析)', caseSensitive: false),
      RegExp(r'(\w+(?:\s+\w+)*?)\s+(?:for|about|on)', caseSensitive: false),
      RegExp(r'(\w+(?:-\w+)*)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
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
    final patterns = [
      RegExp(r'(?:for|to|about)\s+(\w+(?:\s+\w+)*)', caseSensitive: false),
      RegExp(r'(\w+(?:\s+\w+)*?)\s+(?:系统|模块|组件|功能)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
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
    final patterns = [
      RegExp(r'(\w+(?:\s+\w+)*?)\s+(?:系统|架构|设计|实现)', caseSensitive: false),
      RegExp(r'(\w+(?:-\w+)*)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
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

  static StructuredTitleData _canonicalNormalize(StructuredTitleData data) {
    return StructuredTitleData(
      subject: data.subject?.trim(),
      action: data.action?.trim(),
      object: data.object?.trim(),
      topic: data.topic?.trim(),
    );
  }

  static List<TitleCandidate> _generateCandidates(
    StructuredTitleData data,
    String rawMemory,
  ) {
    final candidates = <TitleCandidate>[];

    if (data.subject != null && data.action != null) {
      final title = _limitLength('${data.subject}：${data.action}');
      candidates.add(TitleCandidate(
        title: title,
        score: 0.9,
        format: 'subject_action',
      ));
    }

    if (data.topic != null && data.action != null) {
      final title = _limitLength('${data.topic}：${data.action}');
      candidates.add(TitleCandidate(
        title: title,
        score: 0.8,
        format: 'topic_action',
      ));
    }

    if (data.object != null && data.action != null) {
      final title = _limitLength('${data.object}：${data.action}');
      candidates.add(TitleCandidate(
        title: title,
        score: 0.7,
        format: 'object_action',
      ));
    }

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

  static String _limitLength(String title) {
    if (title.length <= _maxTitleLength) {
      return title;
    }
    return title.substring(0, _maxTitleLength);
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
