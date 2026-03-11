import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';

/// 数据迁移用例
class DataMigrationUsecase {
  static const String _oldBoxName = 'summaries_v2';
  static const String _newBoxName = 'summaries_v3';

  /// 执行数据迁移
  Future<void> migrate() async {
    try {
      debugPrint('🔄 开始数据迁移: $_oldBoxName → $_newBoxName');

      // 检查旧版数据是否存在
      if (!Hive.isBoxOpen(_oldBoxName)) {
        await Hive.openBox(_oldBoxName);
      }

      final oldBox = Hive.box(_oldBoxName);
      if (oldBox.isEmpty) {
        debugPrint('📭 旧版数据为空，跳过迁移');
        return;
      }

      // 打开新版 box
      if (!Hive.isBoxOpen(_newBoxName)) {
        await Hive.openBox(_newBoxName);
      }

      final newBox = Hive.box(_newBoxName);

      // 迁移数据
      int migratedCount = 0;
      for (final key in oldBox.keys) {
        final oldData = oldBox.get(key);
        if (oldData != null) {
          final migratedSummary = _migrateSummary(oldData);
          await newBox.put(migratedSummary.id, migratedSummary.toJson());
          migratedCount++;
        }
      }

      debugPrint('✅ 数据迁移完成: 共迁移 $migratedCount 条记录');
    } catch (e) {
      debugPrint('❌ 数据迁移失败: $e');
      rethrow;
    }
  }

  /// 迁移单个摘要
  SummaryEntity _migrateSummary(dynamic oldData) {
    final Map<String, dynamic> map;
    if (oldData is Map<String, dynamic>) {
      map = oldData;
    } else if (oldData is Map) {
      map = Map<String, dynamic>.from(oldData);
    } else {
      throw ArgumentError('无法解析旧数据: $oldData');
    }

    return SummaryEntity(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      tags: List<String>.from(map['tags'] ?? []),
      type: MemoryType.fact,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      lastAccessedAt: null,
      source: map['source'] as String? ?? 'manual',
      embedding: List<double>.from(map['embedding'] ?? []),
      importance: 0.5,
      accessCount: 0,
      isAutoExtracted: false,
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }
}
