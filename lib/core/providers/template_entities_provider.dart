import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/core/domain/usecases/template_usecases.dart';

/// Template UseCase Provider - 使用新架构
final templateUseCasesProvider = Provider<TemplateUseCases>((ref) {
  return sl<TemplateUseCases>();
});

/// Template List Provider - 新架构
class TemplateEntityNotifier extends StateNotifier<AsyncValue<List<TemplateEntity>>> {
  final TemplateUseCases useCases;

  TemplateEntityNotifier(this.useCases) : super(const AsyncLoading()) {
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = useCases.getAllTemplates();
      state = AsyncData(templates);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addTemplate(TemplateEntity template) async {
    state = const AsyncLoading();
    try {
      await useCases.addTemplate(template);
      final templates = useCases.getAllTemplates();
      state = AsyncData(templates);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateTemplate(TemplateEntity template) async {
    state = const AsyncLoading();
    try {
      await useCases.updateTemplate(template);
      final templates = useCases.getAllTemplates();
      state = AsyncData(templates);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> deleteTemplate(String id) async {
    state = const AsyncLoading();
    try {
      await useCases.deleteTemplate(id);
      final templates = useCases.getAllTemplates();
      state = AsyncData(templates);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> searchTemplates(String query) async {
    if (query.isEmpty) {
      await _loadTemplates();
      return;
    }
    try {
      final templates = useCases.searchTemplates(query);
      state = AsyncData(templates);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    await _loadTemplates();
  }
}

final templateEntityNotifierProvider =
    StateNotifierProvider<TemplateEntityNotifier, AsyncValue<List<TemplateEntity>>>((ref) {
  final useCases = ref.watch(templateUseCasesProvider);
  return TemplateEntityNotifier(useCases);
});
