import '../entities/summary_entity.dart';

/// Summary repository interface
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

  /// Record access
  Future<void> recordAccess(String id);

  /// Update importance score
  Future<void> updateImportance(String id, double importance);

  /// Get by memory type
  List<SummaryEntity> getSummariesByType(MemoryType type);
}
