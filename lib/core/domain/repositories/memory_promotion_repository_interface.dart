import 'package:local_vault/core/domain/entities/memory_promotion_metadata.dart';

/// Memory Promotion Metadata Repository Interface
///
/// 💡 **Responsibilities**:
/// - Manage auxiliary data related to memory promotion
/// - Decouple from core business data (SummaryEntity)
/// - Support independent version iteration
abstract class MemoryPromotionRepositoryInterface {
  /// Initialize
  Future<void> init();

  /// Get all metadata
  List<MemoryPromotionMetadata> getAllMetadata();

  /// Get metadata by summaryId
  MemoryPromotionMetadata? getMetadata(String summaryId);

  /// Save or update metadata
  Future<void> saveMetadata(MemoryPromotionMetadata metadata);

  /// Batch save
  Future<void> saveAllMetadata(List<MemoryPromotionMetadata> metadataList);

  /// Delete metadata
  Future<void> deleteMetadata(String summaryId);

  /// Clear all data
  Future<void> clearAll();

  /// Total count
  int get totalCount;
}
