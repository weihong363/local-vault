import '../entities/summary_entity.dart';

/// 摘要仓库接口
abstract class SummaryRepositoryInterface {
  Future<void> init();
  Future<void> addSummary(SummaryEntity summary);
  Future<void> updateSummary(SummaryEntity summary);
  Future<void> deleteSummary(String id);
  SummaryEntity? getSummary(String id);
  List<SummaryEntity> getAllSummaries();
  List<SummaryEntity> searchSummaries(String query);
  Future<void> updateSortOrders(List<SummaryEntity> summaries);
  List<SummaryEntity> getSummariesByTag(String tag);
  List<SummaryEntity> getSummariesBySource(String source);
  int get totalCount;
  Future<void> clearAll();
  
  /// 记录访问
  Future<void> recordAccess(String id);
  
  /// 更新重要性评分
  Future<void> updateImportance(String id, double importance);
  
  /// 根据记忆类型获取
  List<SummaryEntity> getSummariesByType(MemoryType type);
}
