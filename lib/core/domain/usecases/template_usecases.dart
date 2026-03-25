import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/core/domain/repositories/template_repository_interface.dart';

/// Template business use cases
class TemplateUseCases {
  final TemplateRepositoryInterface repository;

  TemplateUseCases(this.repository);

  /// Add template
  Future<void> addTemplate(TemplateEntity template) async {
    await repository.addTemplate(template);
  }

  /// Update template
  Future<void> updateTemplate(TemplateEntity template) async {
    await repository.updateTemplate(template);
  }

  /// Delete template
  Future<void> deleteTemplate(String id) async {
    await repository.deleteTemplate(id);
  }

  /// Get single template
  TemplateEntity? getTemplate(String id) {
    return repository.getTemplate(id);
  }

  /// Get all templates
  List<TemplateEntity> getAllTemplates() {
    return repository.getAllTemplates();
  }

  /// Search templates
  List<TemplateEntity> searchTemplates(String query) {
    return repository.searchTemplates(query);
  }
}
