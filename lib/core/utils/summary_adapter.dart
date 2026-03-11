import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/features/summary/models/summary.dart' as old;

/// Summary 模型适配器 - 新旧模型互转
class SummaryAdapter {
  /// 旧模型转新模型
  static SummaryEntity toEntity(old.Summary oldSummary) {
    return SummaryEntity(
      id: oldSummary.id,
      title: oldSummary.title,
      content: oldSummary.content,
      tags: oldSummary.tags,
      createdAt: oldSummary.createdAt,
      updatedAt: oldSummary.updatedAt,
      source: oldSummary.source,
      embedding: oldSummary.embedding,
      sortOrder: oldSummary.sortOrder,
    );
  }

  /// 新模型转旧模型
  static old.Summary fromEntity(SummaryEntity entity) {
    return old.Summary(
      id: entity.id,
      title: entity.title,
      content: entity.content,
      tags: entity.tags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      source: entity.source,
      embedding: entity.embedding,
      sortOrder: entity.sortOrder,
    );
  }

  /// 旧模型列表转新模型列表
  static List<SummaryEntity> toEntityList(List<old.Summary> oldList) {
    return oldList.map(toEntity).toList();
  }

  /// 新模型列表转旧模型列表
  static List<old.Summary> fromEntityList(List<SummaryEntity> entityList) {
    return entityList.map(fromEntity).toList();
  }
}
