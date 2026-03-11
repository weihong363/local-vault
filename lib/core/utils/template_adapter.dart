import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/features/template/models/template.dart' as old;

/// Template 模型适配器 - 新旧模型互转
class TemplateAdapter {
  /// 旧模型转新模型
  static TemplateEntity toEntity(old.Template oldTemplate) {
    return TemplateEntity(
      id: oldTemplate.id,
      title: oldTemplate.title,
      content: oldTemplate.content,
      tags: oldTemplate.tags,
      createdAt: oldTemplate.createdAt,
      updatedAt: oldTemplate.updatedAt,
    );
  }

  /// 新模型转旧模型
  static old.Template fromEntity(TemplateEntity entity) {
    return old.Template(
      id: entity.id,
      title: entity.title,
      content: entity.content,
      tags: entity.tags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// 旧模型列表转新模型列表
  static List<TemplateEntity> toEntityList(List<old.Template> oldList) {
    return oldList.map(toEntity).toList();
  }

  /// 新模型列表转旧模型列表
  static List<old.Template> fromEntityList(List<TemplateEntity> entityList) {
    return entityList.map(fromEntity).toList();
  }
}
