import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/features/summary/models/summary.dart' as old;

/// Summary model adapter - converts between old and new models
class SummaryAdapter {
  /// Convert old model to new model
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

  /// Convert new model to old model
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

  /// Convert old model list to new model list
  static List<SummaryEntity> toEntityList(List<old.Summary> oldList) {
    return oldList.map(toEntity).toList();
  }

  /// Convert new model list to old model list
  static List<old.Summary> fromEntityList(List<SummaryEntity> entityList) {
    return entityList.map(fromEntity).toList();
  }
}
