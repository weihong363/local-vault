import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/features/template/models/template.dart';
import 'package:local_vault/features/template/domain/repositories/template_repository.dart';

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository();
});

final templateListProvider = FutureProvider<List<Template>>((ref) async {
  final repository = ref.watch(templateRepositoryProvider);
  await repository.init();
  return repository.getAllTemplates();
});

class TemplateNotifier extends StateNotifier<AsyncValue<List<Template>>> {
  final TemplateRepository repository;

  TemplateNotifier(this.repository) : super(const AsyncLoading()) {
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      await repository.init();
      final templates = repository.getAllTemplates();
      state = AsyncData(templates);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addTemplate(Template template) async {
    state = const AsyncLoading();
    try {
      await repository.addTemplate(template);
      final templates = repository.getAllTemplates();
      state = AsyncData(templates);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> deleteTemplate(String id) async {
    state = const AsyncLoading();
    try {
      await repository.deleteTemplate(id);
      final templates = repository.getAllTemplates();
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
      final templates = repository.searchTemplates(query);
      state = AsyncData(templates);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    await _loadTemplates();
  }
}

final templateNotifierProvider = StateNotifierProvider<TemplateNotifier, AsyncValue<List<Template>>>((ref) {
  final repository = ref.watch(templateRepositoryProvider);
  return TemplateNotifier(repository);
});
