import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';

/// SummaryRepository 的 Hive 实现
class HiveSummaryRepository implements SummaryRepositoryInterface {
  static const String _boxName = 'summaries_v3';
  Box? _box;

  @override
  Future<void> init() async {
    try {
      debugPrint('🔄 [HiveSummaryRepository] 正在打开 Hive box: $_boxName');
      if (_box == null) {
        _box = await Hive.openBox(_boxName);
        debugPrint('✅ [HiveSummaryRepository] Hive box 打开成功，包含 ${_box!.length} 条记录');
      }
    } catch (e) {
      debugPrint('❌ [HiveSummaryRepository] 打开 Hive box 失败: $e');
      debugPrint('⚠️  [HiveSummaryRepository] 尝试删除并重建 box...');
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox(_boxName);
      debugPrint('✅ [HiveSummaryRepository] Hive box 重建成功');
    }
  }

  Box get _summaryBox {
    assert(_box != null, 'Repository not initialized. Call init() first.');
    return _box!;
  }

  /// 安全地将动态Map转换为Map<String, dynamic>
  Map<String, dynamic> _safeCastMap(dynamic map) {
    if (map is Map<String, dynamic>) {
      return map;
    }
    if (map is Map) {
      return Map<String, dynamic>.from(map);
    }
    throw ArgumentError('无法转换为Map<String, dynamic>: $map');
  }

  @override
  Future<void> addSummary(SummaryEntity summary) async {
    await _summaryBox.put(summary.id, summary.toJson());
  }

  @override
  Future<void> updateSummary(SummaryEntity summary) async {
    await _summaryBox.put(summary.id, summary.toJson());
  }

  @override
  Future<void> deleteSummary(String id) async {
    await _summaryBox.delete(id);
  }

  @override
  SummaryEntity? getSummary(String id) {
    final json = _summaryBox.get(id);
    return json != null ? SummaryEntity.fromJson(_safeCastMap(json)) : null;
  }

  @override
  List<SummaryEntity> getAllSummaries() {
    final summaries = _summaryBox.values
        .map((json) => SummaryEntity.fromJson(_safeCastMap(json)))
        .toList();
    summaries.sort((a, b) {
      if (a.sortOrder != b.sortOrder) {
        return a.sortOrder.compareTo(b.sortOrder);
      }
      // 按综合评分降序排序
      return b.combinedScore.compareTo(a.combinedScore);
    });
    return summaries;
  }

  @override
  List<SummaryEntity> searchSummaries(String query) {
    final lowerQuery = query.toLowerCase();
    final summaries = _summaryBox.values
        .map((json) => SummaryEntity.fromJson(_safeCastMap(json)))
        .where((summary) {
          return summary.title.toLowerCase().contains(lowerQuery) ||
              summary.content.toLowerCase().contains(lowerQuery) ||
              summary.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
        }).toList();
    summaries.sort((a, b) {
      // 搜索时优先使用综合评分
      final scoreA = _calculateSearchRelevance(a, lowerQuery);
      final scoreB = _calculateSearchRelevance(b, lowerQuery);
      return scoreB.compareTo(scoreA);
    });
    return summaries;
  }

  /// 计算搜索相关性
  double _calculateSearchRelevance(SummaryEntity summary, String query) {
    double score = 0.0;

    // 标题匹配权重最高
    if (summary.title.toLowerCase().contains(query)) {
      score += 10.0;
    }

    // 标签匹配
    for (final tag in summary.tags) {
      if (tag.toLowerCase().contains(query)) {
        score += 5.0;
      }
    }

    // 内容匹配
    if (summary.content.toLowerCase().contains(query)) {
      score += 2.0;
    }

    // 乘以综合评分
    return score * summary.combinedScore;
  }

  @override
  Future<void> recordAccess(String id) async {
    final summary = getSummary(id);
    if (summary != null) {
      final updatedSummary = summary.copyWith(
        lastAccessedAt: DateTime.now(),
        accessCount: summary.accessCount + 1,
      );
      await updateSummary(updatedSummary);
    }
  }

  @override
  Future<void> updateImportance(String id, double importance) async {
    final summary = getSummary(id);
    if (summary != null) {
      final updatedSummary = summary.copyWith(
        importance: importance.clamp(0.0, 1.0),
      );
      await updateSummary(updatedSummary);
    }
  }

  @override
  List<SummaryEntity> getSummariesByType(MemoryType type) {
    return _summaryBox.values
        .map((json) => SummaryEntity.fromJson(_safeCastMap(json)))
        .where((summary) => summary.type == type)
        .toList();
  }

  @override
  Future<void> updateSortOrders(List<SummaryEntity> summaries) async {
    for (int i = 0; i < summaries.length; i++) {
      final summary = summaries[i];
      if (summary.sortOrder != i) {
        final updatedSummary = summary.copyWith(sortOrder: i);
        await _summaryBox.put(updatedSummary.id, updatedSummary.toJson());
      }
    }
  }

  @override
  List<SummaryEntity> getSummariesByTag(String tag) {
    return _summaryBox.values
        .map((json) => SummaryEntity.fromJson(_safeCastMap(json)))
        .where((summary) => summary.tags.contains(tag))
        .toList();
  }

  @override
  List<SummaryEntity> getSummariesBySource(String source) {
    return _summaryBox.values
        .map((json) => SummaryEntity.fromJson(_safeCastMap(json)))
        .where((summary) => summary.source == source)
        .toList();
  }

  @override
  int get totalCount {
    return _summaryBox.length;
  }

  @override
  Future<void> clearAll() async {
    await _summaryBox.clear();
  }
}
