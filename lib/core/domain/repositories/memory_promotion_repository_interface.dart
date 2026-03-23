import 'package:local_vault/core/domain/entities/memory_promotion_metadata.dart';

/// 记忆晋升元数据仓库接口
///
/// 💡 **职责**：
/// - 管理记忆晋升相关的辅助数据
/// - 与核心业务数据 (SummaryEntity) 解耦
/// - 支持独立的版本迭代
abstract class MemoryPromotionRepositoryInterface {
  /// 初始化
  Future<void> init();

  /// 获取所有元数据
  List<MemoryPromotionMetadata> getAllMetadata();

  /// 根据 summaryId 获取元数据
  MemoryPromotionMetadata? getMetadata(String summaryId);

  /// 保存或更新元数据
  Future<void> saveMetadata(MemoryPromotionMetadata metadata);

  /// 批量保存
  Future<void> saveAllMetadata(List<MemoryPromotionMetadata> metadataList);

  /// 删除元数据
  Future<void> deleteMetadata(String summaryId);

  /// 清空所有数据
  Future<void> clearAll();

  /// 总数
  int get totalCount;
}
