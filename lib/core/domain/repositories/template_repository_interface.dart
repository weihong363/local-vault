import '../entities/template_entity.dart';

/// 模板仓库接口
abstract class TemplateRepositoryInterface {
  Future<void> init();
  Future<void> addTemplate(TemplateEntity template);
  Future<void> updateTemplate(TemplateEntity template);
  Future<void> deleteTemplate(String id);
  TemplateEntity? getTemplate(String id);
  List<TemplateEntity> getAllTemplates();
  List<TemplateEntity> searchTemplates(String query);
  Future<void> clearAll();
}
