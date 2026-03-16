import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/core/domain/repositories/template_repository_interface.dart';

/// TemplateRepository 的 Hive 实现
class HiveTemplateRepository implements TemplateRepositoryInterface {
  static const String _boxName = 'templates_v2';
  Box? _box;

  @override
  Future<void> init() async {
    try {
      debugPrint('🔄 [HiveTemplateRepository] 正在打开 Hive box: $_boxName');
      if (_box == null) {
        _box = await Hive.openBox(_boxName);
        debugPrint('✅ [HiveTemplateRepository] Hive box 打开成功，包含 ${_box!.length} 条记录');

        // 首次初始化时添加默认模板
        if (_box!.isEmpty) {
          await _addDefaultTemplates();
        }
      }
    } catch (e) {
      debugPrint('❌ [HiveTemplateRepository] 打开 Hive box 失败: $e');
      debugPrint('⚠️  [HiveTemplateRepository] 尝试删除并重建 box...');
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox(_boxName);
      await _addDefaultTemplates();
      debugPrint('✅ [HiveTemplateRepository] Hive box 重建成功');
    }
  }

  /// 添加默认模板
  Future<void> _addDefaultTemplates() async {
    debugPrint('📝 [HiveTemplateRepository] 正在添加默认模板...');
    
    final defaultTemplates = [
      TemplateEntity(
        id: 'default_summary',
        title: '快速摘要',
        content: '请总结以下内容，突出关键点：\n\n{{content}}',
        tags: ['摘要', '通用'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_question',
        title: '问题解答',
        content: '针对以下内容，请详细回答这个问题：\n问题：{{question}}\n\n内容：{{content}}',
        tags: ['问题', '解答'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_analysis',
        title: '深度分析',
        content: '请对以下内容进行深度分析，从多个角度进行阐述：\n\n{{content}}',
        tags: ['分析', '深度'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_meeting',
        title: '会议纪要',
        content: '请将以下内容整理为清晰的会议纪要，包含时间、地点、参会人员、议题、决议等：\n\n{{content}}',
        tags: ['会议', '纪要'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_action_items',
        title: '行动项提取',
        content: '请从以下内容中提取可执行的行动项，按优先级排序，并给出负责人和截止时间建议：\n\n{{content}}',
        tags: ['行动项', '任务'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_brief',
        title: '要点提炼',
        content: '请提炼以下内容的要点，使用条目化列表输出：\n\n{{content}}',
        tags: ['要点', '提炼'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_code_review',
        title: '代码审查',
        content: '请审查以下代码，指出潜在问题、风险和改进建议：\n\n```dart\n{{content}}\n```',
        tags: ['代码', '审查'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_plan',
        title: '任务拆解',
        content: '请将以下目标拆解为可执行的步骤，并给出估时与依赖关系：\n\n{{content}}',
        tags: ['规划', '拆解'],
        createdAt: DateTime.now(),
      ),
      TemplateEntity(
        id: 'default_translation',
        title: '翻译润色',
        content: '请将以下内容翻译为中文，并进行润色：\n\n{{content}}',
        tags: ['翻译', '润色'],
        createdAt: DateTime.now(),
      ),
    ];

    for (final template in defaultTemplates) {
      await addTemplate(template);
    }
    
    debugPrint('✅ [HiveTemplateRepository] 已添加 ${defaultTemplates.length} 个默认模板');
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
    throw ArgumentError('无法转换为 Map<String, dynamic>: $map');
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
    await _templateBox.put(template.id, {
      'id': template.id,
      'title': template.title,
      'content': template.content,
      'tags': template.tags,
      'createdAt': template.createdAt.toIso8601String(),
      'updatedAt': template.updatedAt?.toIso8601String(),
    });
  }

  @override
  Future<void> updateTemplate(TemplateEntity template) async {
    await _templateBox.put(template.id, {
      'id': template.id,
      'title': template.title,
      'content': template.content,
      'tags': template.tags,
      'createdAt': template.createdAt.toIso8601String(),
      'updatedAt': template.updatedAt?.toIso8601String(),
    });
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
    return TemplateEntity(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      tags: _parseTags(map['tags']),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? _parseDate(map['updatedAt']) : null,
    );
  }
}
