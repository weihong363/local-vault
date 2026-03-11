import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/core/domain/repositories/template_repository_interface.dart';

/// TemplateRepository 的 Hive 实现
class HiveTemplateRepository implements TemplateRepositoryInterface {
  static const String _boxName = 'templates_v2';
  Box<Map<String, dynamic>>? _box;

  @override
  Future<void> init() async {
    try {
      debugPrint('🔄 [HiveTemplateRepository] 正在打开 Hive box: $_boxName');
      if (_box == null) {
        _box = await Hive.openBox<Map<String, dynamic>>(_boxName);
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
      _box = await Hive.openBox<Map<String, dynamic>>(_boxName);
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
    ];

    for (final template in defaultTemplates) {
      await addTemplate(template);
    }
    
    debugPrint('✅ [HiveTemplateRepository] 已添加 ${defaultTemplates.length} 个默认模板');
  }

  Box<Map<String, dynamic>> get _templateBox {
    assert(_box != null, 'Repository not initialized. Call init() first.');
    return _box!;
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
    return json != null ? _fromMap(json) : null;
  }

  @override
  List<TemplateEntity> getAllTemplates() {
    return _templateBox.values
        .map(_fromMap)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  List<TemplateEntity> searchTemplates(String query) {
    final lowerQuery = query.toLowerCase();
    return _templateBox.values
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
      tags: (map['tags'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }
}
