class TopicPlaceholderUtils {
  TopicPlaceholderUtils._();

  static const Set<String> _placeholderTopicAliases = {
    'temporary topic',
    'general topic',
    'pending summary',
    'untitled summary',
    'uncategorized',
    '临时主题',
    '通用主题',
    '待整理摘要',
    '未命名摘要',
    '未分类',
    '仮テーマ',
    '一般トピック',
    '保留中の要約',
    '未分類',
    '임시 주제',
    '일반 주제',
    '정리 대기 요약',
    '미분류',
    'tema temporal',
    'tema general',
    'resumen pendiente',
    'sin clasificar',
    'sujet temporaire',
    'sujet général',
    'sujet general',
    'résumé en attente',
    'resume en attente',
    'non classé',
    'non classe',
    'temporäres thema',
    'temporares thema',
    'allgemeines thema',
    'ausstehende zusammenfassung',
    'nicht kategorisiert',
  };

  static const List<String> _placeholderTopicPrefixes = [
    'pending summary',
    'untitled summary',
    'temporary topic',
    'general topic',
    'uncategorized',
    '待整理摘要',
    '未命名摘要',
    '临时主题',
    '通用主题',
    '未分类',
    '保留中の要約',
    '仮テーマ',
    '一般トピック',
    '未分類',
    '정리 대기 요약',
    '임시 주제',
    '일반 주제',
    '미분류',
    'resumen pendiente',
    'tema temporal',
    'tema general',
    'sin clasificar',
    'résumé en attente',
    'resume en attente',
    'sujet temporaire',
    'sujet général',
    'sujet general',
    'non classé',
    'non classe',
    'ausstehende zusammenfassung',
    'temporäres thema',
    'temporares thema',
    'allgemeines thema',
    'nicht kategorisiert',
    '待整理',
    '未命名',
    '临时',
    '保留中',
    '仮',
    '임시',
    'pending',
    'untitled',
    'temporary',
  ];

  static bool isPlaceholderTopic(String value) {
    return _placeholderTopicAliases.contains(_normalize(value));
  }

  static String stripLeadingPlaceholder(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final lower = trimmed.toLowerCase();
    for (final prefix in _placeholderTopicPrefixes) {
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
