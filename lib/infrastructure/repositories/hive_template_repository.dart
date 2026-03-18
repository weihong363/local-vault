import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:local_vault/core/constants/app_storage.dart';
import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/core/domain/repositories/template_repository_interface.dart';

/// Hive-backed implementation of TemplateRepositoryInterface.
class HiveTemplateRepository implements TemplateRepositoryInterface {
  static final String _boxName = AppStorage.templateBoxName;
  Box? _box;

  @override
  Future<void> init() async {
    try {
      debugPrint('🔄 [HiveTemplateRepository] Opening Hive box: $_boxName');
      if (_box == null) {
        _box = await Hive.openBox(_boxName);
        debugPrint(
          '✅ [HiveTemplateRepository] Hive box opened successfully with ${_box!.length} record(s)',
        );

        // Seed default templates on first initialization.
        if (_box!.isEmpty) {
          await _addDefaultTemplates();
        }
      }
    } catch (e) {
      debugPrint('❌ [HiveTemplateRepository] Failed to open Hive box: $e');
      debugPrint('⚠️ [HiveTemplateRepository] Recreating the box from disk...');
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox(_boxName);
      await _addDefaultTemplates();
      debugPrint('✅ [HiveTemplateRepository] Hive box recreated successfully');
    }
  }

  /// Add the built-in starter templates.
  Future<void> _addDefaultTemplates() async {
    debugPrint('📝 [HiveTemplateRepository] Adding default templates...');

    final defaultTemplates = [
      TemplateEntity(
        id: 'default_summary',
        title: 'Quick Summary',
        content:
            'Summarize the following content and highlight the key points:\n\n{{content}}',
        tags: ['summary', 'general'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_question',
        title: 'Question Answering',
        content:
            'Answer this question in detail using the following content:\nQuestion: {{question}}\n\nContent: {{content}}',
        tags: ['question', 'answer'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_analysis',
        title: 'Deep Analysis',
        content:
            'Provide a deep analysis of the following content from multiple angles:\n\n{{content}}',
        tags: ['analysis', 'deep-dive'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_meeting',
        title: 'Meeting Notes',
        content:
            'Turn the following content into clear meeting notes, including time, location, attendees, agenda, and decisions:\n\n{{content}}',
        tags: ['meeting', 'notes'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_action_items',
        title: 'Action Items',
        content:
            'Extract actionable items from the following content, sort them by priority, and suggest owners and due dates:\n\n{{content}}',
        tags: ['action-items', 'tasks'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_brief',
        title: 'Key Takeaways',
        content:
            'Extract the key takeaways from the following content and present them as a bullet list:\n\n{{content}}',
        tags: ['takeaways', 'brief'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_code_review',
        title: 'Code Review',
        content:
            'Review the following code and point out potential problems, risks, and improvement suggestions:\n\n```dart\n{{content}}\n```',
        tags: ['code', 'review'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_plan',
        title: 'Task Breakdown',
        content:
            'Break the following goal into actionable steps and include effort estimates and dependencies:\n\n{{content}}',
        tags: ['planning', 'breakdown'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_translation',
        title: 'Translation Polish',
        content:
            'Translate the following content into English and polish the wording:\n\n{{content}}',
        tags: ['translation', 'polish'],
        createdAt: DateTime.now(),
      ),
    ];

    for (final template in defaultTemplates) {
      await addTemplate(template);
    }

    debugPrint(
      '✅ [HiveTemplateRepository] Added ${defaultTemplates.length} default templates',
    );
  }

  Box get _templateBox {
    assert(_box != null, 'Repository not initialized. Call init() first.');
    return _box!;
  }

  Map<String, dynamic> _safeCastMap(dynamic map) {
    if (map is Map<String, dynamic>) {
      return map;
    }
    if (map is Map) {
      return Map<String, dynamic>.from(map);
    }
    throw ArgumentError('Cannot convert to Map<String, dynamic>: $map');
  }

  List<String> _parseTags(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }
    return const [];
  }

  DateTime _parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) {
      return DateTime.parse(raw);
    }
    return DateTime.now();
  }

  @override
  Future<void> addTemplate(TemplateEntity template) async {
    await _templateBox.put(template.id, template.toJson());
  }

  @override
  Future<void> updateTemplate(TemplateEntity template) async {
    await _templateBox.put(template.id, template.toJson());
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _templateBox.delete(id);
  }

  @override
  TemplateEntity? getTemplate(String id) {
    final json = _templateBox.get(id);
    return json != null ? _fromMap(_safeCastMap(json)) : null;
  }

  @override
  List<TemplateEntity> getAllTemplates() {
    return _templateBox.values.map(_safeCastMap).map(_fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  List<TemplateEntity> searchTemplates(String query) {
    final lowerQuery = query.toLowerCase();
    return _templateBox.values
        .map(_safeCastMap)
        .map(_fromMap)
        .where((template) =>
            template.title.toLowerCase().contains(lowerQuery) ||
            template.content.toLowerCase().contains(lowerQuery))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> clearAll() async {
    await _templateBox.clear();
  }

  TemplateEntity _fromMap(Map<String, dynamic> map) {
    return TemplateEntity.fromJson(<String, dynamic>{
      'id': map['id'],
      'title': map['title'],
      'content': map['content'],
      'tags': _parseTags(map['tags']),
      'createdAt': _parseDate(map['createdAt']).toIso8601String(),
      'updatedAt': map['updatedAt'] != null
          ? _parseDate(map['updatedAt']).toIso8601String()
          : null,
    });
  }
}
