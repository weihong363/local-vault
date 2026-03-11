# 记忆模块迁移指南

## 📋 概述

本文档指导如何将当前项目的记忆模块从基础架构升级为基于 **mem0** 和 **ToolNeuron** 设计理念的增强版记忆系统。

**参考项目**：
- [mem0](https://github.com/mem0ai/mem0) - 智能记忆层
- [ToolNeuron](https://github.com/Siddhesh2377/ToolNeuron) - 离线 AI 助手

---

## 🎯 迁移目标

### 当前状态
- ✅ 基础 DDD 架构
- ✅ SummaryEntity 领域模型
- ✅ Hive 本地存储
- ✅ 基本搜索功能
- ⚠️ 单级记忆（无分类）
- ❌ 无记忆权重管理
- ❌ 无时效性管理
- ❌ 无去重机制
- ❌ 无遗忘曲线

### 目标状态
- ✅ 多级记忆架构（用户事实、会话、模板）
- ✅ 记忆权重和重要性评分
- ✅ 时效性管理和遗忘曲线
- ✅ Jaccard 相似度去重
- ✅ 智能搜索和排序
- ✅ 独立的记忆管理界面

---

## 🚀 迁移阶段

### 第一阶段：基础扩展（低风险，立即实施）

**目标**：扩展现有的 SummaryEntity，添加核心字段

#### 1.1 扩展 SummaryEntity

**文件**：`lib/core/domain/entities/summary_entity.dart`

**添加字段**：
```dart
/// 记忆类型
enum MemoryType {
  fact,        // 用户事实（持久化）
  session,     // 会话记忆（临时）
  template,    // 模板记忆
}

class SummaryEntity {
  // ... 现有字段 ...
  
  /// 新增字段
  final MemoryType type;
  final DateTime? lastAccessedAt;  // 最后访问时间
  final double importance;         // 重要性 (0.0-1.0)
  final int accessCount;           // 访问次数
  final bool isAutoExtracted;     // 是否自动提取
  
  // ... 更新构造函数和方法 ...
}
```

**向后兼容**：
- 现有数据默认 `type = MemoryType.fact`
- `importance` 默认 0.5
- `accessCount` 默认 0

#### 1.2 更新 Hive 存储

**文件**：`lib/infrastructure/repositories/hive_summary_repository.dart`

**更新内容**：
- 支持新字段的序列化/反序列化
- 数据迁移脚本（将现有数据升级）

#### 1.3 优化搜索排序

**文件**：`lib/core/domain/usecases/summary_usecases.dart`

**新增方法**：
```dart
/// 计算时效性分数
double _calculateRecencyScore(SummaryEntity summary) {
  if (summary.lastAccessedAt == null) return 0.5;
  final daysSinceAccess = DateTime.now().difference(summary.lastAccessedAt!).inDays;
  return 1.0 * (0.95 ^ daysSinceAccess); // 每天衰减 5%
}

/// 综合评分排序
List<SummaryEntity> _sortByRelevance(List<SummaryEntity> summaries) {
  return summaries..sort((a, b) {
    final scoreA = a.importance * 0.5 + _calculateRecencyScore(a) * 0.3 + (a.accessCount > 0 ? 1.0 - (1.0 / (a.accessCount + 1)) : 0.0) * 0.2;
    final scoreB = b.importance * 0.5 + _calculateRecencyScore(b) * 0.3 + (b.accessCount > 0 ? 1.0 - (1.0 / (b.accessCount + 1)) : 0.0) * 0.2;
    return scoreB.compareTo(scoreA);
  });
}
```

#### 1.4 更新 Provider

**文件**：`lib/core/providers/summary_entities_provider.dart`

**新增方法**：
```dart
/// 记录访问
Future<void> recordAccess(String id) async {
  // 更新 lastAccessedAt 和 accessCount
}

/// 按类型筛选
List<SummaryEntity> getByType(MemoryType type) {
  // 实现筛选逻辑
}
```

**验收标准**：
- [ ] 现有数据正常加载
- [ ] 搜索结果按综合评分排序
- [ ] 可以按记忆类型筛选
- [ ] `flutter analyze` 通过

---

### 第二阶段：智能增强（中期优化）

**目标**：实现去重、遗忘曲线、记忆管理界面

#### 2.1 实现 Jaccard 相似度去重

**新增文件**：`lib/core/utils/similarity_utils.dart`

```dart
/// Jaccard 相似度计算
class SimilarityUtils {
  /// 计算两个文本的 Jaccard 相似度
  static double jaccardSimilarity(String text1, String text2) {
    final words1 = _tokenize(text1);
    final words2 = _tokenize(text2);
    
    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;
    
    return union == 0 ? 0.0 : intersection / union;
  }
  
  static Set<String> _tokenize(String text) {
    return text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toSet();
  }
}
```

**更新 UseCase**：
```dart
/// 添加记忆（带去重）
Future<void> addWithDeduplication(SummaryEntity summary) async {
  const threshold = 0.7;
  final existing = getAllSummaries();
  
  for (final item in existing) {
    final similarity = SimilarityUtils.jaccardSimilarity(
      '${summary.title} ${summary.content}',
      '${item.title} ${item.content}',
    );
    
    if (similarity >= threshold) {
      // 合并记忆
      final merged = _mergeMemories(item, summary);
      await updateSummary(merged);
      return;
    }
  }
  
  await addSummary(summary);
}

/// 合并相似记忆
SummaryEntity _mergeMemories(SummaryEntity existing, SummaryEntity newOne) {
  final mergedTags = {...existing.tags, ...newOne.tags}.toList();
  return existing.copyWith(
    content: '${existing.content}\n\n${newOne.content}',
    tags: mergedTags,
    updatedAt: DateTime.now(),
    importance: (existing.importance + newOne.importance) / 2,
  );
}
```

#### 2.2 实现遗忘曲线

**新增方法**：
```dart
/// 应用遗忘曲线
Future<void> applyForgettingCurve() async {
  final all = getAllSummaries();
  final now = DateTime.now();
  
  for (final summary in all) {
    final daysOld = now.difference(summary.createdAt).inDays;
    
    // 30天后开始衰减
    if (daysOld > 30) {
      final decayFactor = 1.0 - ((daysOld - 30) / 60) * 0.9;
      final newImportance = (summary.importance * decayFactor).clamp(0.1, 1.0);
      
      if (newImportance != summary.importance) {
        await updateSummary(summary.copyWith(importance: newImportance));
      }
    }
  }
}

/// 清理过期会话记忆
Future<void> cleanupSessionMemories() async {
  const maxAge = Duration(hours: 24);
  final sessions = getByType(MemoryType.session);
  final now = DateTime.now();
  
  for (final session in sessions) {
    if (now.difference(session.createdAt) > maxAge) {
      await deleteSummary(session.id);
    }
  }
}
```

#### 2.3 创建记忆管理界面

**新增文件**：`lib/features/memory/presentation/pages/memory_management_page.dart`

**功能**：
- 查看所有记忆
- 按类型筛选
- 编辑记忆重要性
- 手动删除/合并记忆
- 查看记忆统计（访问次数、最后访问时间）

#### 2.4 定时任务集成

**更新**：`lib/main.dart`

**添加**：应用启动时和恢复时执行清理任务
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    // 应用恢复时执行
    _memoryUseCases.applyForgettingCurve();
    _memoryUseCases.cleanupSessionMemories();
  }
}
```

**验收标准**：
- [ ] 添加记忆时自动去重
- [ ] 遗忘曲线正常工作
- [ ] 会话记忆自动清理
- [ ] 记忆管理界面可用
- [ ] `flutter analyze` 通过

---

### 第三阶段：高级功能（长期规划）

**目标**：向量检索、自动提取、智能合并

#### 3.1 集成本地向量检索

**选项**：
- SQLite + 向量扩展
- 集成 ONNX Runtime 进行本地嵌入
- 使用简单的余弦相似度

**新增文件**：`lib/core/services/vector_search_service.dart`

#### 3.2 自动记忆提取

**功能**：
- 从对话中自动识别用户事实
- 使用本地 LLM 提取关键信息
- 标记为 `isAutoExtracted`

#### 3.3 智能记忆合并

**功能**：
- 定期检查相似记忆
- 智能合并相关内容
- 保持记忆的时效性

**验收标准**：
- [ ] 向量检索可用
- [ ] 自动提取功能正常
- [ ] 智能合并工作
- [ ] 性能优化完成

---

## 📁 文件结构变化

### 新增文件

```
lib/
├── core/
│   ├── domain/
│   │   └── entities/
│   │       └── memory_entity.dart          (可选：独立的增强版)
│   ├── usecases/
│   │   └── memory_usecases.dart           (可选：独立)
│   └── utils/
│       └── similarity_utils.dart           (新增)
└── features/
    └── memory/
        ├── domain/
        │   └── repositories/
        │       └── memory_repository_interface.dart
        ├── data/
        │   └── repositories/
        │       └── hive_memory_repository.dart
        └── presentation/
            ├── providers/
            │   └── memory_provider.dart
            ├── pages/
            │   └── memory_management_page.dart
            └── widgets/
                └── memory_card.dart
```

### 修改文件

```
lib/
├── core/
│   ├── domain/
│   │   └── entities/
│   │       └── summary_entity.dart          (扩展)
│   ├── usecases/
│   │   └── summary_usecases.dart           (扩展)
│   └── providers/
│       └── summary_entities_provider.dart  (扩展)
├── infrastructure/
│   └── repositories/
│       └── hive_summary_repository.dart     (更新)
└── main.dart                                  (添加生命周期钩子)
```

---

## 🔄 数据迁移策略

### 现有数据升级

```dart
/// 数据迁移脚本
class DataMigrationService {
  static Future<void> migrateToV2() async {
    final oldSummaries = await getOldSummaries();
    
    for (final old in oldSummaries) {
      final migrated = SummaryEntity(
        id: old.id,
        title: old.title,
        content: old.content,
        tags: old.tags,
        type: MemoryType.fact,  // 默认用户事实
        createdAt: old.createdAt,
        updatedAt: old.updatedAt,
        source: old.source,
        embedding: old.embedding,
        sortOrder: old.sortOrder,
        // 新字段默认值
        importance: 0.5,
        accessCount: 0,
        lastAccessedAt: null,
        isAutoExtracted: false,
      );
      
      await saveMigrated(migrated);
    }
  }
}
```

---

## ✅ 检查清单

### 第一阶段
- [ ] 扩展 SummaryEntity 添加新字段
- [ ] 更新 Hive 序列化
- [ ] 实现数据迁移
- [ ] 优化搜索排序
- [ ] 添加访问记录功能
- [ ] 测试现有功能
- [ ] `flutter analyze` 通过

### 第二阶段
- [ ] 实现 Jaccard 相似度
- [ ] 添加去重逻辑
- [ ] 实现遗忘曲线
- [ ] 会话记忆自动清理
- [ ] 创建记忆管理界面
- [ ] 集成定时任务
- [ ] 完整测试
- [ ] `flutter analyze` 通过

### 第三阶段
- [ ] 向量检索集成
- [ ] 自动记忆提取
- [ ] 智能合并
- [ ] 性能优化
- [ ] 完整测试

---

## 📊 与参考项目的对应关系

| 特性 | mem0 | ToolNeuron | 本项目 |
|-----|------|-----------|--------|
| 多级记忆 | ✅ | ✅ | 第一阶段 |
| 记忆权重 | ✅ | ✅ | 第一阶段 |
| 时效性 | ✅ | ✅ | 第一阶段 |
| Jaccard 去重 | ❌ | ✅ | 第二阶段 |
| 遗忘曲线 | ❌ | ✅ | 第二阶段 |
| 向量检索 | ✅ | ✅ | 第三阶段 |
| 自动提取 | ✅ | ✅ | 第三阶段 |

---

## 🎯 下一步行动

1. **立即开始**：实施第一阶段
2. **测试验证**：确保第一阶段稳定
3. **逐步推进**：根据反馈调整后续阶段
4. **持续优化**：基于实际使用情况迭代

---

## 📚 参考资源

- [mem0 GitHub](https://github.com/mem0ai/mem0)
- [mem0 文档](https://docs.mem0.ai)
- [ToolNeuron GitHub](https://github.com/Siddhesh2377/ToolNeuron)
- [ToolNeuron 记忆设计](https://github.com/Siddhesh2377/ToolNeuron)
