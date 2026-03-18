class SummaryTextUtils {
  SummaryTextUtils._();

  static const int maxTitleLength = 32;
  static const int maxEnglishWordCount = 8;
  static const int defaultMaxTags = 4;
  static const String unnamedTitle = '未命名摘要';

  static const Set<String> _genericChineseTokens = {
    '这个',
    '那个',
    '这里',
    '这个问题',
    '这件事',
    '内容',
    '摘要',
    '总结',
    '标题',
    '标签',
    '信息',
    '情况',
    '事项',
    '记录',
    '整理',
    '处理',
    '优化',
    '更新',
    '问题',
    '需求',
  };

  static const Set<String> _highSignalTitleKeywords = {
    '进展',
    '同步',
    '会议',
    '纪要',
    '复盘',
    '方案',
    '计划',
    '安排',
    '清单',
    '任务',
    '待办',
    '周报',
    '月报',
    '总结',
    '结论',
    '问题',
    '需求',
    '改版',
    '优化',
    '修复',
  };

  static const Set<String> _actionLeadingWords = {
    '确认',
    '处理',
    '安排',
    '更新',
    '优化',
    '修复',
    '提交',
    '购买',
    '推进',
    '跟进',
    '完成',
    '执行',
  };

  static const Set<String> _tagSceneSuffixes = {
    '同步',
    '讨论',
    '处理',
    '确认',
    '记录',
    '总结',
    '整理',
    '安排',
    '推进',
    '跟进',
  };

  static const Set<String> _genericEnglishTokens = {
    'the',
    'and',
    'for',
    'with',
    'that',
    'this',
    'from',
    'into',
    'your',
    'you',
    'are',
    'was',
    'were',
    'have',
    'has',
    'had',
    'summary',
    'title',
    'content',
    'notes',
    'note',
    'record',
    'records',
    'update',
    'updates',
  };

  static const Set<String> _highSignalEnglishShortTokens = {
    'rag',
    'llm',
    'slm',
    'ocr',
    'api',
    'sdk',
    'nlp',
    'ml',
    'ai',
    'ui',
    'ux',
  };

  static String generateTitle(String content) {
    final cleaned = _normalizePlainText(content);
    if (cleaned.isEmpty) {
      return unnamedTitle;
    }

    for (final candidate in _extractTitleCandidates(cleaned)) {
      final refined = compressTitle(candidate);
      if (_isMeaningfulTitle(refined)) {
        return refined;
      }
    }

    return compressTitle(cleaned);
  }

  static String compressTitle(String title) {
    var normalized = _normalizeTitleText(title);
    if (normalized.isEmpty) {
      return unnamedTitle;
    }

    normalized = _pickBestTitleClause(normalized);
    normalized = _normalizeTitleText(normalized);
    if (normalized.isEmpty) {
      return unnamedTitle;
    }

    normalized = _limitEnglishWords(normalized);
    if (normalized.length <= maxTitleLength) {
      return normalized;
    }

    final cutoff = _findNaturalCutoff(normalized, maxTitleLength);
    final shortened = normalized.substring(0, cutoff).trim();
    return shortened.isEmpty ? unnamedTitle : '$shortened...';
  }

  static List<String> sanitizeTags(
    List<String> tags, {
    int maxTags = defaultMaxTags,
    String? fallbackTitle,
  }) {
    final sanitized = <String>[];
    final seen = <String>{};

    for (final tag in tags) {
      final normalized = _normalizeTag(tag);
      final key = normalized.toLowerCase();
      if (!_isMeaningfulTag(normalized) || !seen.add(key)) {
        continue;
      }
      if (sanitized.any(
        (existing) =>
            existing.contains(normalized) || normalized.contains(existing),
      )) {
        continue;
      }
      sanitized.add(normalized);
      if (sanitized.length >= maxTags) {
        return sanitized;
      }
    }

    final fallback = fallbackTitle == null ? '' : _normalizeTag(fallbackTitle);
    if (sanitized.isEmpty &&
        _isMeaningfulTag(fallback) &&
        seen.add(fallback.toLowerCase())) {
      sanitized.add(fallback);
    }

    return sanitized;
  }

  static List<String> generateTags(
    String title,
    String content, {
    int maxTags = defaultMaxTags,
  }) {
    final normalizedTitle = compressTitle(title);
    final normalizedContent = _normalizePlainText(content);
    final scored = <String, int>{};

    void addCandidate(String raw, int baseScore) {
      final normalized = _normalizeTag(raw);
      if (!_isMeaningfulTag(normalized)) {
        return;
      }

      var score = baseScore;
      if (normalizedTitle.contains(normalized)) {
        score += 4;
      }
      final matches = _countOccurrences(normalizedContent, normalized);
      if (matches > 0) {
        score += matches * 2;
      }
      if (normalized.length >= 4 && normalized.length <= 8) {
        score += 1;
      }

      scored.update(
        normalized,
        (previous) => previous > score ? previous : score,
        ifAbsent: () => score,
      );
    }

    if (_isMeaningfulTag(normalizedTitle) && normalizedTitle != unnamedTitle) {
      addCandidate(normalizedTitle, 10);
    }

    for (final candidate in _extractChineseCandidates(normalizedTitle)) {
      addCandidate(candidate, 8);
    }
    for (final candidate in _extractChineseCandidates(normalizedContent)) {
      addCandidate(candidate, 5);
    }
    for (final candidate in _extractEnglishCandidates(normalizedTitle)) {
      addCandidate(candidate, 6);
    }
    for (final candidate in _extractEnglishCandidates(normalizedContent)) {
      addCandidate(candidate, 3);
    }

    final ranked = scored.entries.toList()
      ..sort((a, b) {
        final scoreDiff = b.value.compareTo(a.value);
        if (scoreDiff != 0) {
          return scoreDiff;
        }
        final lengthDiff = a.key.length.compareTo(b.key.length);
        if (lengthDiff != 0) {
          return lengthDiff;
        }
        return a.key.compareTo(b.key);
      });

    final result = <String>[];
    for (final entry in ranked) {
      final candidate = entry.key;
      if (result.any(
        (existing) =>
            existing.contains(candidate) || candidate.contains(existing),
      )) {
        continue;
      }
      result.add(candidate);
      if (result.length >= maxTags) {
        break;
      }
    }

    return sanitizeTags(
      result,
      maxTags: maxTags,
      fallbackTitle: normalizedTitle == unnamedTitle ? null : normalizedTitle,
    );
  }

  static Iterable<String> _extractTitleCandidates(String content) sync* {
    final seen = <String>{};
    for (final line in content.split('\n')) {
      final normalizedLine = _normalizeTitleText(line);
      if (normalizedLine.isEmpty || !seen.add(normalizedLine)) {
        continue;
      }
      yield normalizedLine;

      for (final clause in normalizedLine.split(RegExp(r'[。！？!?；;]'))) {
        final normalizedClause = _normalizeTitleText(clause);
        if (normalizedClause.isEmpty || !seen.add(normalizedClause)) {
          continue;
        }
        yield normalizedClause;
      }
    }
  }

  static String _normalizePlainText(String text) {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAllMapped(
          RegExp(r'\[([^\]]+)\]\([^)]+\)'),
          (match) => match.group(1) ?? '',
        )
        .replaceAll(RegExp(r'https?://\S+'), ' ')
        .replaceAll(RegExp(r'[`*_>#]'), ' ')
        .split('\n')
        .map((line) {
          return line
              .trim()
              .replaceFirst(
                RegExp(r'^[-*•\d.)(一二三四五六七八九十、\s]+'),
                '',
              )
              .trim();
        })
        .where((line) => line.isNotEmpty)
        .join('\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .trim();
    return normalized;
  }

  static String _normalizeTitleText(String text) {
    var normalized = _normalizePlainText(text)
        .replaceAll(RegExp(r'^[《「『"“\[]+'), '')
        .replaceAll(RegExp(r'[》」』"”\]]+$'), '')
        .replaceAll(RegExp(r'[。！？!?；;，,、]+$'), '')
        .trim();

    final colonIndex = normalized.lastIndexOf(RegExp(r'[:：]'));
    if (colonIndex != -1 && colonIndex < normalized.length - 1) {
      final tail = normalized.substring(colonIndex + 1).trim();
      if (tail.length >= 2) {
        normalized = tail;
      }
    }

    normalized = _stripLeadingTitleFillers(normalized);
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized;
  }

  static String _stripLeadingTitleFillers(String text) {
    final fillers = <String>[
      '请帮我',
      '帮我',
      '请',
      '记录一下',
      '记一下',
      '记录',
      '总结一下',
      '总结',
      '整理一下',
      '整理',
      '关于',
      '有关',
      '这是',
      '这个',
      '这次',
      '本次',
      '本周',
      '本月',
      '今天',
      '今日',
      '刚刚',
      '需要',
      '想要',
      '想',
      '确认',
      '主题',
      '标题',
      '内容',
      '问题',
      '需求',
    ];

    var result = text.trimLeft();
    var changed = true;
    while (changed) {
      changed = false;
      for (final filler in fillers) {
        if (result.startsWith(filler) && result.length > filler.length + 1) {
          result = result.substring(filler.length).trimLeft();
          changed = true;
        }
      }
      result = result.replaceFirst(RegExp(r'^(一下|一下子)\s*'), '');
    }
    return result.trim();
  }

  static String _pickBestTitleClause(String title) {
    final clauses = title
        .split(RegExp(r'[，,、|/]'))
        .map(_normalizeTitleText)
        .where((clause) => clause.isNotEmpty)
        .toList();
    if (clauses.isEmpty) {
      return title;
    }

    String bestClause = clauses.first;
    var bestScore = _scoreTitleClause(bestClause);
    for (final clause in clauses.skip(1)) {
      final score = _scoreTitleClause(clause);
      if (score > bestScore) {
        bestClause = clause;
        bestScore = score;
      }
    }
    return bestClause;
  }

  static int _scoreTitleClause(String clause) {
    var score = 0;
    final normalized = clause.trim();
    if (normalized.isEmpty) {
      return score;
    }
    if (_containsChinese(normalized)) {
      score += 3;
    }
    if (normalized.length >= 4 && normalized.length <= 16) {
      score += 4;
    } else if (normalized.length <= maxTitleLength) {
      score += 2;
    }
    if (!normalized.startsWith('本周') &&
        !normalized.startsWith('今天') &&
        !normalized.startsWith('这个')) {
      score += 2;
    }
    if (!_genericChineseTokens.contains(normalized) &&
        !_genericEnglishTokens.contains(normalized.toLowerCase())) {
      score += 2;
    }
    if (_highSignalTitleKeywords.any(normalized.contains)) {
      score += 3;
    }
    if (_actionLeadingWords.any(normalized.startsWith)) {
      score -= 3;
    }
    if (normalized.contains('和') || normalized.contains('并')) {
      score -= 1;
    }
    return score;
  }

  static String _limitEnglishWords(String text) {
    if (_containsChinese(text) || !_containsEnglish(text)) {
      return text;
    }

    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final limited = words.take(maxEnglishWordCount).join(' ');
    return limited.trim();
  }

  static int _findNaturalCutoff(String text, int maxLength) {
    final preferredDelimiters = ['，', '、', ' ', '-', '/', '|'];
    for (final delimiter in preferredDelimiters) {
      final index = text.lastIndexOf(delimiter, maxLength - 1);
      if (index >= maxLength ~/ 2) {
        return index;
      }
    }
    return maxLength - 3;
  }

  static Iterable<String> _extractChineseCandidates(String text) sync* {
    final seen = <String>{};
    final normalized = _normalizePlainText(text);
    for (final segment in normalized.split(RegExp(r'[\n。！？!?；;，,、/|]'))) {
      final trimmed = _normalizeTag(segment);
      if (!_containsChinese(trimmed)) {
        continue;
      }

      if (_isMeaningfulTag(trimmed) && seen.add(trimmed)) {
        yield trimmed;
      }

      for (final part in trimmed.split(
        RegExp(
          r'和|与|及|并且|以及|或者|还是|然后|但是|因为|所以|如果|关于|有关|需要|进行|完成|处理|讨论|同步|确认|提交|购买|安排|计划|跟进|优化|修复|更新',
        ),
      )) {
        final candidate = _normalizeTag(part);
        if (_isMeaningfulTag(candidate) &&
            _containsChinese(candidate) &&
            seen.add(candidate)) {
          yield candidate;
        }
      }
    }
  }

  static Iterable<String> _extractEnglishCandidates(String text) sync* {
    final seen = <String>{};
    final normalized = _normalizePlainText(text);
    for (final segment in normalized.split(RegExp(r'[\n,.;!?/|]'))) {
      final words = segment
          .split(RegExp(r'[^A-Za-z]+'))
          .map((word) => word.trim().toLowerCase())
          .where(
            (word) =>
                word.length >= 4 ||
                _highSignalEnglishShortTokens.contains(word),
          )
          .where((word) => !_genericEnglishTokens.contains(word))
          .toList();

      for (final word in words) {
        if (seen.add(word)) {
          yield word;
        }
      }
    }
  }

  static String _normalizeTag(String tag) {
    var normalized = _normalizeTitleText(tag)
        .replaceAll(RegExp(r'^#+'), '')
        .replaceAll(RegExp(r'^[（(\[]+|[）)\]]+$'), '')
        .trim();

    normalized = normalized
        .replaceFirst(
          RegExp(
              r'^(请帮我|帮我|请|记录一下|记一下|需要|安排|处理|讨论|确认|优化|修复|更新|查看|提交|购买|今天|本周|本月|关于)'),
          '',
        )
        .replaceFirst(RegExp(r'(记录|总结|摘要|内容|事项)$'), '')
        .trim();

    for (final suffix in _tagSceneSuffixes) {
      if (normalized.endsWith(suffix) &&
          normalized.length > suffix.length + 1) {
        normalized =
            normalized.substring(0, normalized.length - suffix.length).trim();
        break;
      }
    }

    return normalized;
  }

  static bool _isMeaningfulTitle(String title) {
    if (title.isEmpty || title == unnamedTitle) {
      return false;
    }
    if (title.length < 2) {
      return false;
    }
    return !_genericChineseTokens.contains(title) &&
        !_genericEnglishTokens.contains(title.toLowerCase());
  }

  static bool _isMeaningfulTag(String tag) {
    if (tag.isEmpty) {
      return false;
    }
    if (_containsChinese(tag)) {
      if (tag.length < 2 || tag.length > 12) {
        return false;
      }
    } else if (_containsEnglish(tag)) {
      final lower = tag.toLowerCase();
      final isShortHighSignal = _highSignalEnglishShortTokens.contains(lower);
      if ((!isShortHighSignal && tag.length < 4) || tag.length > 24) {
        return false;
      }
    } else {
      return false;
    }

    final lower = tag.toLowerCase();
    if (_genericChineseTokens.contains(tag) ||
        _genericEnglishTokens.contains(lower)) {
      return false;
    }
    if (RegExp(r'^\d+$').hasMatch(tag)) {
      return false;
    }
    return true;
  }

  static bool _containsChinese(String text) {
    return RegExp(r'[\u4E00-\u9FFF]').hasMatch(text);
  }

  static bool _containsEnglish(String text) {
    return RegExp(r'[A-Za-z]').hasMatch(text);
  }

  static int _countOccurrences(String text, String keyword) {
    if (text.isEmpty || keyword.isEmpty) {
      return 0;
    }
    return RegExp(RegExp.escape(keyword)).allMatches(text).length;
  }
}
