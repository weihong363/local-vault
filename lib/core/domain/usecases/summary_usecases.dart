import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';
import 'package:local_vault/core/utils/similarity_utils.dart';

/// 摘要业务用例
class SummaryUseCases {
  final SummaryRepositoryInterface repository;

  SummaryUseCases(this.repository);

  /// 添加摘要
  Future<void> addSummary(SummaryEntity summary) async {
    await repository.addSummary(summary);
  }

  /// 更新摘要
  Future<void> updateSummary(SummaryEntity summary) async {
    await repository.updateSummary(summary);
  }

  /// 删除摘要
  Future<void> deleteSummary(String id) async {
    await repository.deleteSummary(id);
  }

  /// 获取单个摘要
  SummaryEntity? getSummary(String id) {
    return repository.getSummary(id);
  }

  /// 获取所有摘要
  List<SummaryEntity> getAllSummaries() {
    return repository.getAllSummaries();
  }

  /// 搜索摘要
  List<SummaryEntity> searchSummaries(String query) {
    return repository.searchSummaries(query);
  }

  /// 更新排序
  Future<void> updateSortOrders(List<SummaryEntity> summaries) async {
    await repository.updateSortOrders(summaries);
  }

  /// 根据标签获取摘要
  List<SummaryEntity> getSummariesByTag(String tag) {
    return repository.getSummariesByTag(tag);
  }

  /// 根据来源获取摘要
  List<SummaryEntity> getSummariesBySource(String source) {
    return repository.getSummariesBySource(source);
  }

  /// 记录访问
  Future<void> recordAccess(String id) async {
    await repository.recordAccess(id);
  }

  /// 更新重要性评分
  Future<void> updateImportance(String id, double importance) async {
    await repository.updateImportance(id, importance);
  }

  /// 根据记忆类型获取
  List<SummaryEntity> getSummariesByType(MemoryType type) {
    return repository.getSummariesByType(type);
  }

  /// 添加记忆（带去重）
  /// 相似度阈值默认为 0.7，超过则合并而非新增
  Future<void> addWithDeduplication(
    SummaryEntity summary, {
    double similarityThreshold = 0.7,
  }) async {
    final existingSummaries = getAllSummaries();

    // 1) 完全重复内容：不新增，只更新访问记录
    final duplicate = _findExactDuplicate(existingSummaries, summary);
    if (duplicate != null) {
      await updateSummary(
        duplicate.copyWith(
          lastAccessedAt: DateTime.now(),
          accessCount: duplicate.accessCount + 1,
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }

    for (final existing in existingSummaries) {
      final similarity = SimilarityUtils.calculateMemorySimilarity(
        summary.title,
        summary.content,
        existing.title,
        existing.content,
      );

      if (similarity >= similarityThreshold) {
        final merged = _mergeMemories(existing, summary);
        await updateSummary(merged);
        return;
      }
    }

    await addSummary(summary);
  }

  /// 添加会话记忆（仅在会话内合并）
  Future<void> addSessionMemory(
    SummaryEntity summary, {
    double similarityThreshold = 0.6,
  }) async {
    final sessionSummaries = getSummariesByType(MemoryType.session);
    SummaryEntity? bestMatch;
    double bestScore = 0.0;

    final duplicate = _findExactDuplicate(sessionSummaries, summary);
    if (duplicate != null) {
      await updateSummary(
        duplicate.copyWith(
          lastAccessedAt: DateTime.now(),
          accessCount: duplicate.accessCount + 1,
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }

    for (final existing in sessionSummaries) {
      if (_isSameTopic(existing, summary)) {
        final merged = _mergeMemories(existing, summary);
        await updateSummary(merged.copyWith(updatedAt: DateTime.now()));
        return;
      }

      final similarity = SimilarityUtils.calculateMemorySimilarity(
        summary.title,
        summary.content,
        existing.title,
        existing.content,
      );
      if (similarity > bestScore) {
        bestScore = similarity;
        bestMatch = existing;
      }
    }

    if (bestMatch != null && bestScore >= similarityThreshold) {
      final merged = _mergeMemories(bestMatch, summary);
      await updateSummary(merged);
      return;
    }

    await addSummary(summary);
  }

  SummaryEntity? _findExactDuplicate(
    List<SummaryEntity> existing,
    SummaryEntity incoming,
  ) {
    final incomingContent = _normalizeContent(incoming.content);
    for (final item in existing) {
      if (_normalizeContent(item.content) == incomingContent) {
        return item;
      }
    }
    return null;
  }

  bool _isSameTopic(SummaryEntity a, SummaryEntity b) {
    final titleA = _normalizeTitle(a.title);
    final titleB = _normalizeTitle(b.title);
    if (titleA.isEmpty || titleB.isEmpty) return false;
    if (titleA == titleB) return true;
    if (titleA.contains(titleB) || titleB.contains(titleA)) return true;
    return false;
  }

  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\u4E00-\u9FFF ]'), '')
        .trim();
  }

  String _normalizeContent(String content) {
    return content.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 合并两个相似记忆
  SummaryEntity _mergeMemories(SummaryEntity existing, SummaryEntity newOne) {
    final mergedTags = {...existing.tags, ...newOne.tags}.toList();
    final mergedContent = _mergeContent(existing.content, newOne.content);

    return existing.copyWith(
      content: mergedContent,
      tags: mergedTags,
      updatedAt: DateTime.now(),
      importance: (existing.importance + newOne.importance) / 2,
      accessCount: existing.accessCount + newOne.accessCount,
    );
  }

  /// 合并记忆内容，避免重复
  String _mergeContent(String content1, String content2) {
    if (content1.contains(content2)) {
      return content1;
    }
    if (content2.contains(content1)) {
      return content2;
    }
    return '$content1\n\n$content2';
  }

  /// 应用遗忘曲线
  /// 30天后开始衰减，重要性最低保留 0.1
  Future<void> applyForgettingCurve() async {
    final allSummaries = getAllSummaries();
    final now = DateTime.now();

    for (final summary in allSummaries) {
      final daysOld = now.difference(summary.createdAt).inDays;

      // 30天后开始衰减
      if (daysOld > 30) {
        final decayFactor = 1.0 - ((daysOld - 30) / 60) * 0.9;
        final newImportance = (summary.importance * decayFactor).clamp(0.1, 1.0);

        if (newImportance != summary.importance) {
          await updateSummary(summary.copyWith(importance: newImportance));
        }
      }
    }
  }

  /// 清理过期会话记忆（默认 24 小时）
  Future<void> cleanupSessionMemories({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final sessionMemories = getSummariesByType(MemoryType.session);
    final now = DateTime.now();

    for (final session in sessionMemories) {
      if (now.difference(session.createdAt) > maxAge) {
        await deleteSummary(session.id);
      }
    }
  }

  /// 查找相似记忆
  List<SummaryEntity> findSimilarMemories(
    SummaryEntity target, {
    double threshold = 0.5,
  }) {
    final allSummaries = getAllSummaries();
    final similar = <SummaryEntity>[];

    for (final summary in allSummaries) {
      if (summary.id == target.id) continue;

      final similarity = SimilarityUtils.calculateMemorySimilarity(
        target.title,
        target.content,
        summary.title,
        summary.content,
      );

      if (similarity >= threshold) {
        similar.add(summary);
      }
    }

    return similar;
  }

  /// 手动合并两个记忆
  Future<void> mergeMemories(String id1, String id2) async {
    final summary1 = getSummary(id1);
    final summary2 = getSummary(id2);

    if (summary1 == null || summary2 == null) {
      throw ArgumentError('找不到指定的记忆');
    }

    final merged = _mergeMemories(summary1, summary2);
    await updateSummary(merged);
    await deleteSummary(summary2.id);
  }
}
