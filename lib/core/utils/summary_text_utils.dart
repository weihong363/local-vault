class SummaryTextUtils {
  SummaryTextUtils._();

  static const int maxTitleLength = 50;

  static String generateTitle(String content) {
    if (content.trim().isEmpty) {
      return '未命名摘要';
    }

    String cleaned = content.trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^\s+'), '');

    int endIndex = cleaned.length;
    final sentenceEnd = RegExp(r'[。！？.!?]');
    final firstSentenceMatch = sentenceEnd.firstMatch(cleaned);
    if (firstSentenceMatch != null) {
      endIndex = firstSentenceMatch.end;
    } else {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1 && firstNewline < maxTitleLength) {
        endIndex = firstNewline;
      }
    }

    if (endIndex > maxTitleLength) {
      endIndex = maxTitleLength;
    }

    String title = cleaned.substring(0, endIndex).trim();
    title = title.replaceAll(RegExp(r'[.…。！？,!?]+$'), '');

    if (title.isEmpty) {
      title = cleaned.substring(
          0, cleaned.length > maxTitleLength ? maxTitleLength : cleaned.length);
    }

    return compressTitle(title);
  }

  static String compressTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return '未命名摘要';
    }
    if (trimmed.length <= maxTitleLength) {
      return trimmed;
    }
    return '${trimmed.substring(0, maxTitleLength - 3)}...';
  }

  static List<String> generateTags(
    String title,
    String content, {
    int maxTags = 5,
  }) {
    final text = '$title\n$content';
    final tags = <String>{};

    final cjkStopwords = {
      '这个',
      '那个',
      '我们',
      '你们',
      '他们',
      '然后',
      '但是',
      '因为',
      '所以',
      '如果',
      '可以',
      '需要',
      '进行',
      '内容',
      '摘要',
      '总结',
    };
    final enStopwords = {
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
    };

    for (final match in RegExp(r'[\u4E00-\u9FFF]{2,6}').allMatches(text)) {
      final word = match.group(0) ?? '';
      if (word.length >= 2 && !cjkStopwords.contains(word)) {
        tags.add(word);
      }
      if (tags.length >= maxTags) break;
    }

    if (tags.length < maxTags) {
      for (final match in RegExp(r'[A-Za-z]{3,}').allMatches(text)) {
        final word = (match.group(0) ?? '').toLowerCase();
        if (!enStopwords.contains(word)) {
          tags.add(word);
        }
        if (tags.length >= maxTags) break;
      }
    }

    return tags.take(maxTags).toList();
  }
}
