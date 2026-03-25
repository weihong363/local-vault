import 'dart:math';

/// 相似度计算工具类
class SimilarityUtils {
  static final RegExp _latinTokenRegex = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿĀ-žẞß0-9]+');
  static final RegExp _cjkChunkRegex =
      RegExp(r'[\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF]+');

  /// 计算两个文本的 Jaccard 相似度
  /// 取值范围: 0.0 (完全不相似) - 1.0 (完全相同)
  static double jaccardSimilarity(String text1, String text2) {
    final words1 = _tokenizeToSet(text1);
    final words2 = _tokenizeToSet(text2);

    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;

    return union == 0 ? 0.0 : intersection / union;
  }

  /// 使用成对文档频率估算的 BM25-lite 相似度。
  static double bm25Similarity(String text1, String text2) {
    final normalized1 = _normalizeForComparison(text1);
    final normalized2 = _normalizeForComparison(text2);
    if (normalized1.isEmpty || normalized2.isEmpty) {
      return 0.0;
    }
    if (normalized1 == normalized2) {
      return 1.0;
    }

    final tokens1 = _tokenizeToList(text1);
    final tokens2 = _tokenizeToList(text2);
    if (tokens1.isEmpty || tokens2.isEmpty) {
      return 0.0;
    }

    final forward = _normalizedBm25Score(tokens1, tokens2);
    final backward = _normalizedBm25Score(tokens2, tokens1);
    return ((forward + backward) / 2).clamp(0.0, 1.0);
  }

  /// 计算 token overlap coefficient，用于放大短文本间的共享关键信号。
  static double tokenOverlapCoefficient(String text1, String text2) {
    final tokens1 = _tokenizeToSet(text1);
    final tokens2 = _tokenizeToSet(text2);
    if (tokens1.isEmpty || tokens2.isEmpty) {
      return 0.0;
    }

    final intersection = tokens1.intersection(tokens2).length;
    final minSize = min(tokens1.length, tokens2.length);
    return minSize == 0 ? 0.0 : intersection / minSize;
  }

  /// 计算两个记忆的综合相似度。
  /// 同时考虑 Jaccard、BM25-lite、token overlap 和包含关系。
  static double calculateMemorySimilarity(
    String title1,
    String content1,
    String title2,
    String content2,
  ) {
    final normalizedTitle1 = _normalizeForComparison(title1);
    final normalizedTitle2 = _normalizeForComparison(title2);
    final normalizedContent1 = _normalizeForComparison(content1);
    final normalizedContent2 = _normalizeForComparison(content2);

    if (normalizedTitle1 == normalizedTitle2 &&
        normalizedContent1 == normalizedContent2 &&
        normalizedTitle1.isNotEmpty) {
      return 1.0;
    }

    final fullText1 = '$title1 $content1';
    final fullText2 = '$title2 $content2';

    final titleJaccard = jaccardSimilarity(title1, title2);
    final titleOverlap = tokenOverlapCoefficient(title1, title2);
    final titleBm25 = bm25Similarity(title1, title2);
    final contentJaccard = jaccardSimilarity(content1, content2);
    final contentBm25 = bm25Similarity(content1, content2);
    final fullJaccard = jaccardSimilarity(fullText1, fullText2);
    final fullBm25 = bm25Similarity(fullText1, fullText2);
    final fullOverlap = tokenOverlapCoefficient(fullText1, fullText2);
    final titleComposite =
        (titleJaccard * 0.4) + (titleBm25 * 0.35) + (titleOverlap * 0.25);
    final contentComposite = (contentJaccard * 0.55) + (contentBm25 * 0.45);
    final fullComposite =
        (fullJaccard * 0.4) + (fullBm25 * 0.4) + (fullOverlap * 0.2);
    final alignmentScore = sqrt(titleComposite * contentComposite);
    final acronymBonus =
        _hasSharedUppercaseTerm(fullText1, fullText2) ? 0.05 : 0.0;
    final containmentBonus = _hasMeaningfulContainment(fullText1, fullText2) &&
            max(contentComposite, fullComposite) >= 0.55
        ? 0.03
        : 0.0;

    final weighted = (titleComposite * 0.22) +
        (contentComposite * 0.25) +
        (fullComposite * 0.18) +
        (alignmentScore * 0.30) +
        acronymBonus +
        containmentBonus;

    return weighted.clamp(0.0, 1.0);
  }

  static double _normalizedBm25Score(
    List<String> queryTokens,
    List<String> docTokens,
  ) {
    if (queryTokens.isEmpty || docTokens.isEmpty) {
      return 0.0;
    }

    const k1 = 1.2;
    const b = 0.75;
    final docLength = docTokens.length.toDouble();
    final averageDocLength =
        max(1.0, (queryTokens.length + docTokens.length) / 2);
    final documentFrequencies = _frequencyMap(docTokens);
    final queryTerms = queryTokens.toSet();

    double score = 0.0;
    double maxScore = 0.0;

    for (final term in queryTerms) {
      final documentFrequency = (queryTerms.contains(term) ? 1 : 0) +
          (documentFrequencies.containsKey(term) ? 1 : 0);
      final idf = log(
        1 + ((2 - documentFrequency + 0.5) / (documentFrequency + 0.5)),
      );
      final tf = documentFrequencies[term] ?? 0;
      final denominator = tf + k1 * (1 - b + b * docLength / averageDocLength);
      if (tf > 0 && denominator > 0) {
        score += idf * ((tf * (k1 + 1)) / denominator);
      }

      const idealTf = 1.0;
      final maxDenominator =
          idealTf + k1 * (1 - b + b * docLength / averageDocLength);
      if (maxDenominator > 0) {
        maxScore += idf * ((idealTf * (k1 + 1)) / maxDenominator);
      }
    }

    return maxScore == 0.0 ? 0.0 : (score / maxScore).clamp(0.0, 1.0);
  }

  static Map<String, int> _frequencyMap(List<String> tokens) {
    final frequencies = <String, int>{};
    for (final token in tokens) {
      frequencies.update(token, (count) => count + 1, ifAbsent: () => 1);
    }
    return frequencies;
  }

  static Set<String> _tokenizeToSet(String text) {
    return _tokenizeToList(text).toSet();
  }

  static List<String> _tokenizeToList(String text) {
    final normalized = _normalizeForTokenization(text);
    if (normalized.isEmpty) {
      return const <String>[];
    }

    final tokens = <String>[];

    for (final match in _latinTokenRegex.allMatches(normalized)) {
      final token = match.group(0)?.toLowerCase();
      if (token != null && token.length > 1) {
        tokens.add(token);
      }
    }

    for (final match in _cjkChunkRegex.allMatches(normalized)) {
      final chunk = match.group(0);
      if (chunk == null || chunk.isEmpty) {
        continue;
      }

      if (chunk.length <= 4) {
        tokens.add(chunk);
      }

      if (chunk.length == 1) {
        continue;
      }

      for (var i = 0; i < chunk.length - 1; i++) {
        tokens.add(chunk.substring(i, i + 2));
      }

      if (chunk.length >= 3) {
        for (var i = 0; i < chunk.length - 2; i++) {
          tokens.add(chunk.substring(i, i + 3));
        }
      }
    }

    return tokens;
  }

  static String _normalizeForTokenization(String text) {
    return text
        .toLowerCase()
        .replaceAll(
          RegExp(
              r'[^A-Za-zÀ-ÖØ-öø-ÿĀ-žẞß0-9\s\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF]'),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _normalizeForComparison(String text) {
    return _normalizeForTokenization(text);
  }

  static bool _hasMeaningfulContainment(String text1, String text2) {
    final normalized1 = _normalizeForComparison(text1);
    final normalized2 = _normalizeForComparison(text2);
    if (normalized1.isEmpty || normalized2.isEmpty) {
      return false;
    }
    if (normalized1 == normalized2) {
      return true;
    }

    final shorter =
        normalized1.length <= normalized2.length ? normalized1 : normalized2;
    final longer = shorter == normalized1 ? normalized2 : normalized1;
    if (shorter.length < 6) {
      return false;
    }
    return longer.contains(shorter);
  }

  static bool _hasSharedUppercaseTerm(String text1, String text2) {
    final terms1 = _extractUppercaseTerms(text1);
    final terms2 = _extractUppercaseTerms(text2);
    if (terms1.isEmpty || terms2.isEmpty) {
      return false;
    }
    return terms1.intersection(terms2).isNotEmpty;
  }

  static Set<String> _extractUppercaseTerms(String text) {
    return RegExp(r'\b[A-Z][A-Z0-9]{1,7}\b')
        .allMatches(text)
        .map((match) => match.group(0))
        .whereType<String>()
        .toSet();
  }
}
