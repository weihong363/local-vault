class SummaryTextUtils {
  SummaryTextUtils._();

  static const int maxTitleLength = 32;
  static const int maxEnglishWordCount = 8;
  static const int defaultMaxTags = 4;
  static const String unnamedTitle = 'Untitled summary';
  static const String _latinScriptCharacterClass = 'A-Za-zÀ-ÖØ-öø-ÿĀ-žẞß';
  static const Set<String> _unnamedTitleAliases = {
    'untitled summary',
    '未命名摘要',
  };
  static const String _cjkScriptPattern =
      r'[\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF]';

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

  static const Set<String> _genericJapaneseTokens = {
    'これ',
    'それ',
    'ここ',
    '内容',
    '要約',
    'まとめ',
    'タイトル',
    'タグ',
    '情報',
    '状況',
    '項目',
    '記録',
    '整理',
    '課題',
    '要件',
    'メモ',
  };

  static const Set<String> _genericKoreanTokens = {
    '이것',
    '그것',
    '여기',
    '내용',
    '요약',
    '제목',
    '태그',
    '정보',
    '상황',
    '항목',
    '기록',
    '정리',
    '문제',
    '요구사항',
    '메모',
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

  static const Set<String> _highSignalJapaneseKeywords = {
    '会議',
    '議事録',
    '振り返り',
    '計画',
    'タスク',
    '課題',
    '要件',
    '進捗',
    'リリース',
    '決定',
    '方針',
    '対応',
  };

  static const Set<String> _highSignalKoreanKeywords = {
    '회의',
    '회고',
    '계획',
    '작업',
    '할일',
    '이슈',
    '요구사항',
    '진행',
    '릴리스',
    '결정',
    '대응',
    '수정',
  };

  static const Set<String> _highSignalEnglishKeywords = {
    'meeting',
    'review',
    'retro',
    'plan',
    'checklist',
    'task',
    'todo',
    'decision',
    'proposal',
    'release',
    'launch',
    'timeline',
    'issue',
    'fix',
    'update',
    'report',
    'summary',
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

  static const Set<String> _actionLeadingJapaneseWords = {
    '確認',
    '対応',
    '整理',
    '更新',
    '修正',
    '提出',
    '購入',
    '推進',
    '完了',
    '実行',
  };

  static const Set<String> _actionLeadingKoreanWords = {
    '확인',
    '처리',
    '정리',
    '업데이트',
    '최적화',
    '수정',
    '제출',
    '구매',
    '진행',
    '완료',
    '실행',
  };

  static const Set<String> _actionLeadingEnglishWords = {
    'confirm',
    'handle',
    'arrange',
    'update',
    'optimize',
    'fix',
    'submit',
    'buy',
    'follow',
    'complete',
    'execute',
    'review',
    'check',
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

  static const Set<String> _tagSceneJapaneseSuffixes = {
    '共有',
    '確認',
    '記録',
    '整理',
    '計画',
    '対応',
  };

  static const Set<String> _tagSceneKoreanSuffixes = {
    '공유',
    '확인',
    '기록',
    '정리',
    '계획',
    '대응',
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
    'item',
    'items',
    'issue',
    'issues',
    'task',
    'tasks',
    'todo',
    'todos',
    'request',
    'requests',
    'need',
    'needs',
    'contenido',
    'resumen',
    'nota',
    'notas',
    'registro',
    'registros',
    'problema',
    'problemas',
    'requisito',
    'requisitos',
    'contenu',
    'résumé',
    'resume',
    'enregistrement',
    'enregistrements',
    'problème',
    'probleme',
    'problèmes',
    'problemes',
    'exigence',
    'exigences',
    'inhalt',
    'zusammenfassung',
    'notiz',
    'notizen',
    'eintrag',
    'eintraege',
    'einträge',
    'problem',
    'anforderung',
    'anforderungen',
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

  static const List<String> _leadingChineseFillers = [
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

  static const List<String> _leadingJapaneseFillers = [
    '確認',
    '記録',
    'まとめ',
    '整理',
    'について',
    '関連',
    'これは',
    '今回',
    '今週',
    '今月',
    '今日',
    'タイトル',
    '件名',
    '内容',
    '課題',
    '要件',
  ];

  static const List<String> _leadingKoreanFillers = [
    '확인',
    '기록',
    '정리',
    '요약',
    '관련',
    '이것은',
    '이번',
    '이번 주',
    '이번 달',
    '오늘',
    '방금',
    '제목',
    '내용',
    '문제',
    '요구사항',
  ];

  static const List<String> _leadingEnglishFillers = [
    'please help me',
    'help me',
    'please',
    'note down',
    'note',
    'summarize',
    'summary',
    'organize',
    'about',
    'regarding',
    'this is',
    'this',
    'today',
    'this week',
    'this month',
    'just now',
    'need to',
    'need',
    'want to',
    'want',
    'topic',
    'title',
    'content',
    'issue',
    'requirement',
    'por favor',
    'ayudame',
    'ayúdame',
    'anota',
    'anotar',
    'resumir',
    'resumen',
    'organizar',
    'sobre',
    'esta es',
    'hoy',
    'esta semana',
    'este mes',
    'necesito',
    'confirmar',
    'actualizar',
    'revisar',
    'résumer',
    'resumer',
    'résumé',
    'resume',
    'organiser',
    'cette semaine',
    'ce mois-ci',
    'besoin',
    'confirmer',
    'vérifier',
    'verifier',
    'à propos',
    'a propos',
    'bitte',
    'notiere',
    'zusammenfassen',
    'zusammenfassung',
    'organisieren',
    'heute',
    'diese woche',
    'diesen monat',
    'muss',
    'müssen',
    'mussen',
    'bestätigen',
    'bestatigen',
    'aktualisieren',
    'prüfen',
    'prufen',
    'über',
    'uber',
  ];

  static final RegExp _cjkScriptRegex = RegExp(_cjkScriptPattern);
  static final RegExp _latinRegex = RegExp('[$_latinScriptCharacterClass]');
  static final RegExp _cjkSplitRegex = RegExp(
    r'和|与|及|并且|以及|或者|还是|然后|但是|因为|所以|如果|关于|有关|需要|进行|完成|处理|讨论|同步|确认|提交|购买|安排|计划|跟进|优化|修复|更新|と|や|および|または|について|関連|必要|確認|対応|整理|計画|그리고|및|또는|관련|필요|확인|처리|논의|계획|업데이트|수정',
  );
  static final RegExp _coordinationRegex = RegExp(
    r'和|并| and | or |と|や|および|그리고|및|또는',
    caseSensitive: false,
  );

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

    if (_isMeaningfulTag(normalizedTitle) &&
        !isUnnamedTitleValue(normalizedTitle)) {
      addCandidate(normalizedTitle, 10);
    }

    for (final candidate in _extractCjkCandidates(normalizedTitle)) {
      addCandidate(candidate, 8);
    }
    for (final candidate in _extractCjkCandidates(normalizedContent)) {
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
      fallbackTitle:
          isUnnamedTitleValue(normalizedTitle) ? null : normalizedTitle,
    );
  }

  static bool isUnnamedTitleValue(String title) {
    final normalized = title
        .trim()
        .replaceAll(RegExp(r'^[(（]\s*'), '')
        .replaceAll(RegExp(r'\s*[)）]$'), '')
        .toLowerCase();
    return _unnamedTitleAliases.contains(normalized);
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
    var result = text.trimLeft();
    var changed = true;
    while (changed) {
      changed = false;
      for (final filler in _leadingChineseFillers) {
        if (result.startsWith(filler) && result.length > filler.length + 1) {
          result = result.substring(filler.length).trimLeft();
          changed = true;
        }
      }

      for (final filler in _leadingJapaneseFillers) {
        if (result.startsWith(filler) && result.length > filler.length + 1) {
          result = result.substring(filler.length).trimLeft();
          changed = true;
        }
      }

      for (final filler in _leadingKoreanFillers) {
        if (result.startsWith(filler) && result.length > filler.length + 1) {
          result = result.substring(filler.length).trimLeft();
          changed = true;
        }
      }

      final lower = result.toLowerCase();
      for (final filler in _leadingEnglishFillers) {
        if (lower.startsWith(filler) && result.length > filler.length + 1) {
          result = result.substring(filler.length).trimLeft();
          changed = true;
          break;
        }
      }

      result = result.replaceFirst(
        RegExp(r'^(一下|一下子|please)\s*', caseSensitive: false),
        '',
      );
      result = result.replaceFirst(RegExp(r'^(的|の|을|를|에|의|:|：|-|–)\s*'), '');
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
    if (_containsCjk(normalized)) {
      score += 3;
    }
    if (normalized.length >= 4 && normalized.length <= 16) {
      score += 4;
    } else if (normalized.length <= maxTitleLength) {
      score += 2;
    }
    if (!_startsWithTemporalPrefix(normalized)) {
      score += 2;
    }
    if (!_isGenericToken(normalized)) {
      score += 2;
    }
    if (_containsHighSignalKeyword(normalized)) {
      score += 3;
    }
    if (_startsWithActionLeadingWord(normalized)) {
      score -= 3;
    }
    if (_coordinationRegex.hasMatch(' $normalized ')) {
      score -= 1;
    }
    return score;
  }

  static String _limitEnglishWords(String text) {
    if (_containsCjk(text) || !_containsEnglish(text)) {
      return text;
    }

    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final limited = words.take(maxEnglishWordCount).join(' ');
    return limited.trim();
  }

  static int _findNaturalCutoff(String text, int maxLength) {
    final preferredDelimiters = ['，', '、', '・', ' ', '-', '/', '|'];
    for (final delimiter in preferredDelimiters) {
      final index = text.lastIndexOf(delimiter, maxLength - 1);
      if (index >= maxLength ~/ 2) {
        return index;
      }
    }
    return maxLength - 3;
  }

  static Iterable<String> _extractCjkCandidates(String text) sync* {
    final seen = <String>{};
    final normalized = _normalizePlainText(text);
    for (final segment in normalized.split(RegExp(r'[\n。！？!?；;，,、/|]'))) {
      final trimmed = _normalizeTag(segment);
      if (!_containsCjk(trimmed)) {
        continue;
      }

      if (_isMeaningfulTag(trimmed) && seen.add(trimmed)) {
        yield trimmed;
      }

      for (final part in trimmed.split(_cjkSplitRegex)) {
        final candidate = _normalizeTag(part);
        if (_isMeaningfulTag(candidate) &&
            _containsCjk(candidate) &&
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
          .split(RegExp('[^$_latinScriptCharacterClass]+'))
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
            r"^(请帮我|帮我|请|记录一下|记一下|需要|安排|处理|讨论|确认|优化|修复|更新|查看|提交|购买|今天|本周|本月|关于|please help me|help me|please|note down|note|need to|need|review|check|today|this week|this month|about|por favor|ayudame|ayúdame|anota|anotar|resumir|resumen|necesito|confirmar|actualizar|revisar|hoy|esta semana|este mes|sobre|確認|記録|整理|今週|今月|今日|résumer|resumer|résumé|resume|organiser|cette semaine|ce mois-ci|besoin|confirmer|vérifier|verifier|à propos|a propos|관련|확인|기록|정리|이번 주|이번 달|오늘|bitte|notiere|zusammenfassen|zusammenfassung|heute|diese woche|diesen monat|bestätigen|bestatigen|aktualisieren|prüfen|prufen|über|uber)",
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r"(记录|总结|摘要|内容|事项|record|summary|content|note|notes|contenido|resumen|contenu|résumé|resume|inhalt|zusammenfassung|notiz|notizen)$",
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(RegExp(r'^(的|の|을|를|에|의)\s*'), '')
        .trim();

    for (final suffix in _tagSceneSuffixes) {
      if (normalized.endsWith(suffix) &&
          normalized.length > suffix.length + 1) {
        normalized =
            normalized.substring(0, normalized.length - suffix.length).trim();
        break;
      }
    }

    for (final suffix in _tagSceneJapaneseSuffixes) {
      if (normalized.endsWith(suffix) &&
          normalized.length > suffix.length + 1) {
        normalized =
            normalized.substring(0, normalized.length - suffix.length).trim();
        break;
      }
    }

    for (final suffix in _tagSceneKoreanSuffixes) {
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
    if (title.isEmpty || isUnnamedTitleValue(title)) {
      return false;
    }
    if (title.length < 2) {
      return false;
    }
    return !_isGenericToken(title);
  }

  static bool _isMeaningfulTag(String tag) {
    if (tag.isEmpty) {
      return false;
    }
    if (_containsCjk(tag)) {
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
    if (_isGenericToken(tag) || _genericEnglishTokens.contains(lower)) {
      return false;
    }
    if (RegExp(r'^\d+$').hasMatch(tag)) {
      return false;
    }
    return true;
  }

  static bool _containsCjk(String text) {
    return _cjkScriptRegex.hasMatch(text);
  }

  static bool _containsEnglish(String text) {
    return _latinRegex.hasMatch(text);
  }

  static int _countOccurrences(String text, String keyword) {
    if (text.isEmpty || keyword.isEmpty) {
      return 0;
    }
    return RegExp(RegExp.escape(keyword)).allMatches(text).length;
  }

  static bool _isGenericToken(String value) {
    final lower = value.toLowerCase();
    return _genericChineseTokens.contains(value) ||
        _genericJapaneseTokens.contains(value) ||
        _genericKoreanTokens.contains(value) ||
        _genericEnglishTokens.contains(lower);
  }

  static bool _containsHighSignalKeyword(String value) {
    final lower = value.toLowerCase();
    return _highSignalTitleKeywords.any(value.contains) ||
        _highSignalJapaneseKeywords.any(value.contains) ||
        _highSignalKoreanKeywords.any(value.contains) ||
        _highSignalEnglishKeywords.any(lower.contains);
  }

  static bool _startsWithActionLeadingWord(String value) {
    final lower = value.toLowerCase();
    return _actionLeadingWords.any(value.startsWith) ||
        _actionLeadingJapaneseWords.any(value.startsWith) ||
        _actionLeadingKoreanWords.any(value.startsWith) ||
        _actionLeadingEnglishWords.any(lower.startsWith);
  }

  static bool _startsWithTemporalPrefix(String value) {
    final lower = value.toLowerCase();
    return value.startsWith('本周') ||
        value.startsWith('本月') ||
        value.startsWith('本季度') ||
        value.startsWith('本年') ||
        value.startsWith('今年') ||
        value.startsWith('今天') ||
        value.startsWith('这个') ||
        value.startsWith('今回') ||
        value.startsWith('今週') ||
        value.startsWith('今月') ||
        value.startsWith('今年') ||
        value.startsWith('今日') ||
        value.startsWith('이번') ||
        value.startsWith('오늘') ||
        lower.startsWith('this week') ||
        lower.startsWith('this month') ||
        lower.startsWith('this quarter') ||
        lower.startsWith('this year') ||
        lower.startsWith('today') ||
        lower.startsWith('just now') ||
        lower.startsWith('esta semana') ||
        lower.startsWith('este mes') ||
        lower.startsWith('este trimestre') ||
        lower.startsWith('este año') ||
        lower.startsWith('este ano') ||
        lower.startsWith('hoy') ||
        lower.startsWith('cette semaine') ||
        lower.startsWith('ce mois-ci') ||
        lower.startsWith('ce trimestre') ||
        lower.startsWith('cette année') ||
        lower.startsWith('cette annee') ||
        lower.startsWith('heute') ||
        lower.startsWith('diese woche') ||
        lower.startsWith('diesen monat') ||
        lower.startsWith('dieses quartal') ||
        lower.startsWith('dieses jahr');
  }
}
