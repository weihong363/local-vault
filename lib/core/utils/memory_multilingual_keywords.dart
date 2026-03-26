/// Multi-language Keyword Utilities for Memory System
///
/// Provides keyword lists and pattern matching for multiple languages.
library;

/// Multi-language keyword patterns for low-signal text detection
class LowSignalPatterns {
  /// Chinese low-signal patterns
  static const List<String> chinese = [
    '^这个.*', // "this..."
    '^那个.*', // "that..."
    '^一些.*', // "some..."
    '^可能.*', // "maybe..."
    '^也许.*', // "perhaps..."
    '^好像.*', // "seems like..."
    '^似乎.*', // "appears..."
    '^一般来说.*', // "generally speaking..."
    '^通常情况下.*', // "usually..."
    '^总的来说.*', // "in summary..."
    '^总之.*', // "in conclusion..."
    '^简单来说.*', // "simply put..."
    '^基本上.*', // "basically..."
    '^大概.*', // "approximately..."
    '^大约.*', // "about..."
  ];

  /// English low-signal patterns
  static const List<String> english = [
    '^this is .*',
    '^that is .*',
    '^some .*',
    '^maybe .*',
    '^perhaps .*',
    '^seems like .*',
    '^appears to .*',
    '^generally .*',
    '^usually .*',
    '^in general .*',
    '^in summary .*',
    '^in conclusion .*',
    '^simply .*',
    '^basically .*',
    '^roughly .*',
    '^approximately .*',
    '^about .*',
  ];

  /// Get all low-signal patterns for regex matching
  static List<RegExp> getAllPatterns() {
    return [
      ...chinese.map((pattern) => RegExp(pattern)),
      ...english.map((pattern) => RegExp(pattern, caseSensitive: false)),
    ];
  }
}

/// Multi-language important keywords for scoring
class ImportantKeywords {
  /// Chinese important keywords
  static const List<String> chinese = [
    '核心',
    '关键',
    '重要',
    '必须',
    '应该',
    '建议',
    '主要',
    '重点',
  ];

  /// English important keywords
  static const List<String> english = [
    'core',
    'key',
    'important',
    'must',
    'should',
    'recommend',
    'main',
    'primary',
    'focus',
    'critical',
    'essential',
    'priority',
  ];

  /// Check if text contains any important keyword
  static bool containsAny(String text) {
    final normalizedText = text.toLowerCase();
    return chinese.any((kw) => normalizedText.contains(kw)) ||
        english.any((kw) => normalizedText.contains(kw));
  }
}

/// Multi-language action verbs for scoring
class ActionVerbs {
  /// Chinese action verbs
  static const List<String> chinese = [
    '实现',
    '完成',
    '创建',
    '建立',
    '设置',
    '配置',
    '优化',
    '改进',
    '修复',
    '添加',
    '删除',
    '更新',
  ];

  /// English action verbs
  static const List<String> english = [
    'implement',
    'complete',
    'create',
    'build',
    'setup',
    'configure',
    'optimize',
    'improve',
    'fix',
    'add',
    'remove',
    'update',
    'deploy',
    'release',
  ];

  /// Check if text starts with any action verb
  static bool startsWithAny(String text) {
    final normalizedText = text.toLowerCase();
    return chinese.any((verb) => normalizedText.startsWith(verb)) ||
        english.any((verb) => normalizedText.startsWith(verb));
  }
}

/// Multi-language memory type inference keywords
class MemoryTypeKeywords {
  /// Temporary task keywords (Chinese + English)
  static const List<String> temporaryTask = [
    '记得',
    '别忘了',
    '提醒',
    'todo',
    '待办',
    'remember',
    'don\'t forget',
    'remind',
    'task',
  ];

  /// Identity-level keywords (Chinese + English)
  static const List<String> identityLevel = [
    '我是',
    '我喜欢',
    '我总是',
    '我不',
    'i am',
    'i like',
    'i always',
    'i don\'t',
    'i never',
    'i prefer',
  ];

  /// Project context keywords (Chinese + English)
  static const List<String> projectContext = [
    '项目',
    'project',
    '开发',
    'product',
    'app',
    'feature',
    'release',
    'version',
    '迭代',
    'sprint',
  ];

  /// User preference keywords (Chinese + English)
  static const List<String> userPreference = [
    '喜欢',
    '偏好',
    '习惯',
    'prefer',
    'like',
    'dislike',
    'habit',
    'usually',
    'always',
    'never',
  ];

  /// Infer memory content type from text
  static String inferType(String title, String content) {
    final text = '$title $content'.toLowerCase();

    // Temporary task keywords
    if (_containsAny(text, temporaryTask)) {
      return 'temporaryTask';
    }

    // Identity-level keywords
    if (_containsAny(text, identityLevel)) {
      return 'identityLevel';
    }

    // Project keywords
    if (_containsAny(text, projectContext)) {
      return 'projectContext';
    }

    // Preference keywords
    if (_containsAny(text, userPreference)) {
      return 'userPreference';
    }

    // Default to project context
    return 'projectContext';
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}

/// State derivation signal keywords for memory runtime
class StateSignals {
  /// Task-related signals (Chinese + English)
  static const Set<String> taskSignals = <String>{
    'task',
    'todo',
    'follow-up',
    'follow up',
    'next step',
    '待办',
    '任务',
    '跟进',
    '修复',
    '处理',
    'checklist',
    'issue',
  };

  /// Project-related signals (Chinese + English)
  static const Set<String> projectSignals = <String>{
    'project',
    'launch',
    'release',
    'rollout',
    'milestone',
    'roadmap',
    '项目',
    '发布',
    '上线',
    '计划',
    '版本',
  };

  /// Preference-related signals (Chinese + English)
  static const Set<String> preferenceSignals = <String>{
    'prefer',
    'preference',
    'like',
    'dislike',
    '偏好',
    '喜欢',
    '习惯',
  };
}

/// Multi-language placeholder topic aliases for topic detection
class PlaceholderTopics {
  /// Placeholder topic aliases (multi-language)
  static const Set<String> aliases = {
    // English
    'temporary topic',
    'general topic',
    'pending summary',
    'untitled summary',
    'uncategorized',
    // Chinese
    '临时主题',
    '通用主题',
    '待整理摘要',
    '未命名摘要',
    '未分类',
    // Japanese
    '仮テーマ',
    '一般トピック',
    '保留中の要約',
    '未分類',
    // Korean
    '임시 주제',
    '일반 주제',
    '정리 대기 요약',
    '미분류',
    // Spanish
    'tema temporal',
    'tema general',
    'resumen pendiente',
    'sin clasificar',
    // French
    'sujet temporaire',
    'sujet général',
    'sujet general',
    'résumé en attente',
    'resume en attente',
    'non classé',
    'non classe',
    // German
    'temporäres thema',
    'temporares thema',
    'allgemeines thema',
    'ausstehende zusammenfassung',
    'nicht kategorisiert',
  };

  /// Placeholder topic prefixes for stripping (multi-language)
  static const List<String> prefixes = [
    // English
    'pending summary',
    'untitled summary',
    'temporary topic',
    'general topic',
    'uncategorized',
    // Chinese
    '待整理摘要',
    '未命名摘要',
    '临时主题',
    '通用主题',
    '未分类',
    // Japanese
    '保留中の要約',
    '仮テーマ',
    '一般トピック',
    '未分類',
    // Korean
    '정리 대기 요약',
    '임시 주제',
    '일반 주제',
    '미분류',
    // Spanish
    'resumen pendiente',
    'tema temporal',
    'tema general',
    'sin clasificar',
    // French
    'résumé en attente',
    'resume en attente',
    'sujet temporaire',
    'sujet général',
    'sujet general',
    'non classé',
    'non classe',
    // German
    'ausstehende zusammenfassung',
    'temporäres thema',
    'temporares thema',
    'allgemeines thema',
    'nicht kategorisiert',
    // Short forms (Chinese)
    '待整理',
    '未命名',
    '临时',
    '保留中',
    // Short forms (Japanese)
    '仮',
    // Short forms (Korean)
    '임시',
    // Short forms (English)
    'pending',
    'untitled',
    'temporary',
  ];

  /// Check if value is a placeholder topic
  static bool isPlaceholder(String value) {
    return aliases.contains(_normalize(value));
  }

  /// Strip leading placeholder prefix from value
  static String stripLeading(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final lower = trimmed.toLowerCase();
    for (final prefix in prefixes) {
      final prefixLower = prefix.toLowerCase();
      if (!lower.startsWith(prefixLower)) {
        continue;
      }

      final stripped = trimmed.substring(prefix.length).replaceFirst(
            RegExp(r'^[\s:：\-–,，.。/]+'),
            '',
          );
      return stripped.trim();
    }

    return trimmed;
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

/// Multi-language title generation utilities
class TitleGeneration {
  /// Unnamed title aliases (for detecting default/empty titles)
  static const Set<String> unnamedTitleAliases = {
    'untitled summary',
    '未命名摘要',
  };

  /// Generic/filler tokens in Chinese
  static const Set<String> genericChineseTokens = {
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

  /// Generic/filler tokens in Japanese
  static const Set<String> genericJapaneseTokens = {
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

  /// Generic/filler tokens in Korean
  static const Set<String> genericKoreanTokens = {
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

  /// High-signal keywords in Chinese titles
  static const Set<String> highSignalChineseKeywords = {
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

  /// High-signal keywords in Japanese titles
  static const Set<String> highSignalJapaneseKeywords = {
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

  /// High-signal keywords in Korean titles
  static const Set<String> highSignalKoreanKeywords = {
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

  /// High-signal keywords in English titles
  static const Set<String> highSignalEnglishKeywords = {
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

  /// Action-leading words in Chinese
  static const Set<String> actionLeadingChineseWords = {
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

  /// Action-leading words in Japanese
  static const Set<String> actionLeadingJapaneseWords = {
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

  /// Action-leading words in Korean
  static const Set<String> actionLeadingKoreanWords = {
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

  /// Action-leading words in English
  static const Set<String> actionLeadingEnglishWords = {
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

  /// Tag scene suffixes in Chinese
  static const Set<String> tagSceneChineseSuffixes = {
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

  /// Tag scene suffixes in Japanese
  static const Set<String> tagSceneJapaneseSuffixes = {
    '共有',
    '確認',
    '記録',
    '整理',
    '計画',
    '対応',
  };

  /// Tag scene suffixes in Korean
  static const Set<String> tagSceneKoreanSuffixes = {
    '공유',
    '확인',
    '기록',
    '정리',
    '계획',
    '대응',
  };

  /// Generic English tokens (stop words)
  static const Set<String> genericEnglishTokens = {
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

  /// High-signal short English tokens (technical terms)
  static const Set<String> highSignalEnglishShortTokens = {
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

  /// Leading filler words in Chinese
  static const List<String> leadingChineseFillers = [
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

  /// Leading filler words in Japanese
  static const List<String> leadingJapaneseFillers = [
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

  /// Leading filler words in Korean
  static const List<String> leadingKoreanFillers = [
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

  /// Leading filler words in English
  static const List<String> leadingEnglishFillers = [
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

  /// CJK character split pattern
  static const String cjkSplitPattern =
      r'和 | 与|及 | 并且 | 以及 | 或者 | 还是 | 然后 | 但是 | 因为 | 所以 | 如果 | 关于 | 有关 | 需要 | 进行 | 完成 | 处理 | 讨论 | 同步 | 确认 | 提交 | 购买 | 安排 | 计划 | 跟进 | 优化 | 修复 | 更新 | と|や|および|または|について | 関連 | 必要 | 確認 | 対応 | 整理 | 計画 | 그리고|및|또는|관련|필요|확인|처리|논의|계획|업데이트|수정';

  /// Coordination conjunction pattern
  static const String coordinationPattern =
      r'和 | 并 | and | or | と|や|および|그리고|및|또는';

  /// Temporal prefix patterns
  static const List<String> temporalPrefixes = [
    '本周',
    '本月',
    '本季度',
    '本年',
    '今年',
    '今天',
    '这个',
    '今回',
    '今週',
    '今月',
    '今年',
    '今日',
    '이번',
    '오늘',
  ];

  /// English temporal prefixes
  static const List<String> englishTemporalPrefixes = [
    'this week',
    'this month',
    'this quarter',
    'this year',
    'today',
    'just now',
    'esta semana',
    'este mes',
    'este trimestre',
    'este año',
    'este ano',
    'hoy',
    'cette semaine',
    'ce mois-ci',
    'ce trimestre',
    'cette année',
    'cette annee',
    'heute',
    'diese woche',
    'diesen monat',
    'dieses quartal',
    'dieses jahr',
  ];

  /// Stop words for title generation
  static const Set<String> stopWords = {
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

  /// Action verbs for title generation (Chinese + English)
  static const Set<String> actionVerbs = {
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

  /// Default Topic Taxonomy (fallback configuration)
  static const Set<String> defaultTopicTaxonomy = {
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
  static const Map<String, String> defaultSynonymMappings = {
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

  /// Latin script character class for English word detection
  static const String latinScriptCharacterClass = 'A-Za-zÀ-ÖØ-öø-ÿĀ-žẞß';

  /// Check if value is an unnamed title
  static bool isUnnamedTitle(String title) {
    final normalized = title
        .trim()
        .replaceAll(RegExp(r'^[(（]\s*'), '')
        .replaceAll(RegExp(r'\s*[)）]$'), '')
        .toLowerCase();
    return unnamedTitleAliases.contains(normalized);
  }

  /// Check if contains any high-signal keyword (multi-language)
  static bool containsHighSignalKeyword(String value) {
    final lower = value.toLowerCase();
    return highSignalChineseKeywords.any(value.contains) ||
        highSignalJapaneseKeywords.any(value.contains) ||
        highSignalKoreanKeywords.any(value.contains) ||
        highSignalEnglishKeywords.any(lower.contains);
  }

  /// Check if starts with action-leading word (multi-language)
  static bool startsWithActionLeadingWord(String value) {
    final lower = value.toLowerCase();
    return actionLeadingChineseWords.any(value.startsWith) ||
        actionLeadingJapaneseWords.any(value.startsWith) ||
        actionLeadingKoreanWords.any(value.startsWith) ||
        actionLeadingEnglishWords.any(lower.startsWith);
  }

  /// Check if starts with temporal prefix (multi-language)
  static bool startsWithTemporalPrefix(String value) {
    final lower = value.toLowerCase();
    return temporalPrefixes.any(value.startsWith) ||
        englishTemporalPrefixes.any(lower.startsWith);
  }

  /// Check if is generic token (multi-language)
  static bool isGenericToken(String value) {
    final lower = value.toLowerCase();
    return genericChineseTokens.contains(value) ||
        genericJapaneseTokens.contains(value) ||
        genericKoreanTokens.contains(value) ||
        genericEnglishTokens.contains(lower);
  }
}
