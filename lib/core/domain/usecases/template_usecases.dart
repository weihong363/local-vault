import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/core/domain/repositories/template_repository_interface.dart';

/// 模板业务用例
class TemplateUseCases {
  final TemplateRepositoryInterface repository;

  TemplateUseCases(this.repository);

  /// 添加模板
  Future<void> addTemplate(TemplateEntity template) async {
    await repository.addTemplate(template);
  }

  /// 更新模板
  Future<void> updateTemplate(TemplateEntity template) async {
    await repository.updateTemplate(template);
  }

  /// 删除模板
  Future<void> deleteTemplate(String id) async {
    await repository.deleteTemplate(id);
  }

  /// 获取单个模板
  TemplateEntity? getTemplate(String id) {
    return repository.getTemplate(id);
  }

  /// 获取所有模板
  List<TemplateEntity> getAllTemplates() {
    return repository.getAllTemplates();
  }

  /// 搜索模板
  List<TemplateEntity> searchTemplates(String query) {
    return repository.searchTemplates(query);
  }
}
