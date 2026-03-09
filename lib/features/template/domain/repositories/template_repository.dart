import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/features/template/models/template.dart';

class TemplateRepository {
  static const String _boxName = 'templates';
  Box<Template>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Template>(_boxName);
    } else {
      _box = Hive.box<Template>(_boxName);
    }
    
    if (_box!.isEmpty) {
      await _addDefaultTemplates();
    }
  }

  Future<void> _addDefaultTemplates() async {
    final defaultTemplates = [
      Template.create(
        title: '代码解释模板',
        content: '请详细解释以下代码的功能、逻辑和关键点：\n\n```\n[在此粘贴代码]\n```',
        tags: ['编程', '代码', '解释'],
      ),
      Template.create(
        title: '写作润色模板',
        content: '请帮我润色以下文字，使其更加流畅、专业：\n\n[在此粘贴文本]',
        tags: ['写作', '润色', '文案'],
      ),
      Template.create(
        title: '翻译模板',
        content: '请将以下内容翻译成中文：\n\n[在此粘贴文本]',
        tags: ['翻译', '语言'],
      ),
      Template.create(
        title: '总结模板',
        content: '请帮我总结以下内容的要点：\n\n[在此粘贴文本]',
        tags: ['总结', '摘要', '要点'],
      ),
    ];

    for (final template in defaultTemplates) {
      await _box!.put(template.id, template);
    }
  }

  List<Template> getAllTemplates() {
    if (_box == null) throw Exception('Repository not initialized');
    return _box!.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addTemplate(Template template) async {
    if (_box == null) throw Exception('Repository not initialized');
    await _box!.put(template.id, template);
  }

  Future<void> updateTemplate(Template template) async {
    if (_box == null) throw Exception('Repository not initialized');
    final updatedTemplate = template.copyWith(updatedAt: DateTime.now());
    await _box!.put(template.id, updatedTemplate);
  }

  Future<void> deleteTemplate(String id) async {
    if (_box == null) throw Exception('Repository not initialized');
    await _box!.delete(id);
  }

  List<Template> searchTemplates(String query) {
    if (_box == null) throw Exception('Repository not initialized');
    final lowerQuery = query.toLowerCase();
    return _box!.values.where((template) {
      return template.title.toLowerCase().contains(lowerQuery) ||
          template.content.toLowerCase().contains(lowerQuery) ||
          template.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}
