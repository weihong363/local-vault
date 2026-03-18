/// 相似度计算工具类
class SimilarityUtils {
  /// 计算两个文本的 Jaccard 相似度
  /// 取值范围: 0.0 (完全不相似) - 1.0 (完全相同)
  static double jaccardSimilarity(String text1, String text2) {
    final words1 = _tokenize(text1);
    final words2 = _tokenize(text2);

    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;

    return union == 0 ? 0.0 : intersection / union;
  }

  /// 文本分词
  static Set<String> _tokenize(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u4E00-\u9FFF]'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return const <String>{};
    }

    final tokens = <String>{};

    for (final match in RegExp(r'[a-z0-9]+').allMatches(normalized)) {
      final token = match.group(0);
      if (token != null && token.length > 1) {
        tokens.add(token);
      }
    }

    for (final match in RegExp(r'[\u4E00-\u9FFF]+').allMatches(normalized)) {
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
    }

    return tokens;
  }

  /// 计算两个记忆的综合相似度
  /// 同时考虑标题和内容
  static double calculateMemorySimilarity(
    String title1,
    String content1,
    String title2,
    String content2,
  ) {
    final fullText1 = '$title1 $content1';
    final fullText2 = '$title2 $content2';
    
    final titleSimilarity = jaccardSimilarity(title1, title2);
    final contentSimilarity = jaccardSimilarity(content1, content2);
    final fullSimilarity = jaccardSimilarity(fullText1, fullText2);
    
    // 加权平均: 标题权重 0.3, 内容权重 0.5, 全文权重 0.2
    return titleSimilarity * 0.3 + contentSimilarity * 0.5 + fullSimilarity * 0.2;
  }
}
