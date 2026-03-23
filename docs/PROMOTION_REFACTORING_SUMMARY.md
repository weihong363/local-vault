# 记忆晋升机制重构完成总结

## 📦 已完成的工作

### 1. 文档创建 ✅

- **文件**: `docs/MEMORY_PROMOTION_MECHANISM.md`
- **内容**: 完整的记忆晋升与降级机制规范
- **特点**:
    - 三层动态流转机制（Session ⇄ Fact ⇄ Core）
    - 详细的计分模型和规则说明
    - 配置化策略定义
    - 预期日志输出示例

### 2. memory_promotion 包实现 ✅

**包结构**:

```
lib/core/memory_promotion/
├── models/
│   ├── memory_content_type.dart      ✅ 内容类型枚举（8 种类型）
│   ├── memory_state.dart             ✅ 记忆状态枚举（5 种状态）
│   └── type_weights.dart             ✅ 类型权重配置（差异化策略）
├── services/
│   └── promotion_scorer.dart         ✅ 计分引擎（3 个核心方法）
└── memory_promotion.dart             ✅ 统一出口
```

**核心功能**:

#### MemoryContentType (内容类型)

- `temporaryTask` - 临时任务（难升易降）
- `userPreference` - 用户偏好（易升难降）
- `projectContext` - 项目上下文（易升，仅主线进 core）
- `longTermGoal` - 长期目标
- `coreProject` - 核心项目
- `keyConstraint` - 关键约束
- `identityLevel` - 身份级约束
- `oneTimeDetail` - 一次性细节

**自动分类**: 基于文本关键词自动推断内容类型

#### MemoryState (记忆状态)

- `session` - 会话记忆
- `fact` - 事实记忆
- `core` - 核心记忆
- `observing` - 观察期
- `archived` - 已归档

#### TypeWeights (类型权重)

每种类型都有独特的：

- `promotionSpeed` - 晋升速度系数 (0.1-1.5)
- `demotionThreshold` - 降级阈值系数 (0.2-1.5)

#### PromotionScorer (计分引擎)

三个核心计分方法：

1. **scoreForSessionToFact()** - Session → Fact 计分
    - 满分 100，≥70 且无冲突可晋升
    - 考虑因素：sessionSpan、userExplicitSave、referenceCount、contentType
    - 冲突检测：7 天内有冲突则分数归零

2. **scoreForFactToCore()** - Fact → Core 计分
    - 满分 100，≥75 且通过观察期可晋升
    - 考虑因素：sessionSpan、stabilityScore、usageInRecommendations、contentType
    - 至少满足 2 条主规则才能进入观察期

3. **scoreForDemotion()** - 降级风险评估
    - 满分 100，≥60 考虑降级
    - 考虑因素：conflictingFact、isLongUnused、userModified/Revoked
    - Core 降级更保守（乘以 0.7 系数）

### 3. SummaryEntity 增强 ✅

**新增字段** (15 个晋升相关):

```dart
// === 晋升相关字段 ===
final int sessionSpan; // 跨越的 session 数量
final bool userExplicitSave; // 用户明确要求记住
final int referenceCount; // 被引用次数
final MemoryContentType contentType; // 内容类型分类
final double stabilityScore; // 稳定性分数 (0-1)
final String? contentHash; // 内容哈希
final int versionCount; // 版本数量
final DateTime? lastConflictAt; // 最后冲突时间
final MemoryState state; // 当前状态
final DateTime? observationStartedAt; // 观察期开始时间
final bool userConfirmedLongTerm; // 用户确认长期有效
final bool userModified; // 用户修改过
final bool userRevoked; // 用户撤销
final int usageInRecommendations; // 在推荐中使用次数
```

**新增方法**:

1. **shouldUpgradeToFactWithPolicy()** - Session → Fact 判断
    - 使用 PromotionScorer.scoreForSessionToFact()
    - 阈值：≥70 分且无冲突

2. **shouldUpgradeToCoreWithPolicy()** - Fact → Core 判断（重构版）
    - 使用 PromotionScorer.scoreForFactToCore()
    - 阈值：≥75 分
    - 旧逻辑已删除，完全迁移到新计分引擎

**更新方法**:

- `create()` - 自动推断 contentType 和 state
- `copyWith()` - 支持所有新字段
- `toJson()` - 序列化新字段
- `fromJson()` - 反序列化新字段（向后兼容）

### 4. SummaryUseCases 集成 ✅

**新增方法**:

```dart
Future<void> _upgradeSessionToFactIfNeeded(String id) async {
  final summary = getSummary(id);
  if (summary == null ||
      !summary.shouldUpgradeToFactWithPolicy(policyConfig)) {
    return;
  }

  debugPrint('⬆️ [Promotion] Session eligible for promotion to Fact: ${summary.title}');
  debugPrint('📊 [Promotion] Score details:');
  debugPrint('   - sessionSpan: ${summary.sessionSpan}');
  debugPrint('   - userExplicitSave: ${summary.userExplicitSave}');
  debugPrint('   - referenceCount: ${summary.referenceCount}');
  debugPrint('   - accessCount: ${summary.accessCount}');
  debugPrint('   - contentType: ${summary.contentType.name}');
  
  await repository.updateSummary(
    summary.copyWith(
      type: MemoryType.fact,
      state: MemoryState.fact,
      updatedAt: DateTime.now(),
    ),
  );
  
  debugPrint('✅ [Promotion] Promoted: Session → Fact');
}
```

**修改方法**:

1. **recordAccess()** - 触发两级晋升检测
   ```dart
   Future<void> recordAccess(String id) async {
     await repository.recordAccess(id);
     
     // ✅ 新增：Session → Fact 自动检测
     await _upgradeSessionToFactIfNeeded(id);
     
     // 原有的 Fact → Core 检测
     await _upgradeFactToCoreIfNeeded(id);
     _scheduleMemoryCompaction();
   }
   ```

2. **updateImportance()** - 触发两级晋升检测
   ```dart
   Future<void> updateImportance(String id, double importance) async {
     await repository.updateImportance(id, importance);
     
     // ✅ 新增：Session → Fact 自动检测
     await _upgradeSessionToFactIfNeeded(id);
     
     // 原有的 Fact → Core 检测
     await _upgradeFactToCoreIfNeeded(id);
     _scheduleMemoryCompaction();
   }
   ```

3. **addSessionMemory()** - 添加 sessionSpan 累加和自动检测
   ```dart
   Future<void> addSessionMemory(SummaryEntity summary) async {
     final enhancedSummary = _enhanceWithStructuredTitle(summary);
     final sessionSummaries = getSummariesByType(MemoryType.session);
     SummaryEntity? savedSession;

     final duplicate = _findExactDuplicate(sessionSummaries, enhancedSummary);
     if (duplicate != null) {
       savedSession = duplicate.copyWith(
         lastAccessedAt: DateTime.now(),
         accessCount: duplicate.accessCount + 1,
         updatedAt: DateTime.now(),
         // ✅ 增加 sessionSpan
         sessionSpan: (duplicate.sessionSpan + 1).clamp(1, 10),
       );
       await updateSummary(savedSession);
     } else {
       savedSession = enhancedSummary.copyWith(type: MemoryType.session);
       await addSummary(savedSession);
     }

     // ✅ 新增：保存后检测是否满足晋升条件
     if (savedSession != null) {
       await _upgradeSessionToFactIfNeeded(savedSession.id);
     }
     
     // ... memoryCapability 处理
   }
   ```

4. **_upgradeFactToCoreIfNeeded()** - 使用新 Scorer 并添加日志
   ```dart
   Future<void> _upgradeFactToCoreIfNeeded(String id) async {
     final summary = getSummary(id);
     if (summary == null ||
         !summary.shouldUpgradeToCoreWithPolicy(policyConfig)) {
       return;
     }

     debugPrint('⬆️ [Promotion] Fact eligible for promotion to Core: ${summary.title}');
     
     await repository.updateSummary(
       summary.copyWith(
         type: MemoryType.core,
         state: MemoryState.core,
         updatedAt: DateTime.now(),
       ),
     );
     
     debugPrint('✅ [Promotion] Promoted: Fact → Core');
   }
   ```

## 🔄 完整调用链

### Session → Fact 流程

```
用户保存 Session 记忆
  ↓
addSessionMemory()
  ↓
_enhanceWithStructuredTitle()  // 优化标题和 topic
  ↓
保存到 Repository
  ↓
_upgradeSessionToFactIfNeeded()  // ✅ 新增
  ↓
shouldUpgradeToFactWithPolicy()
  ↓
PromotionScorer.scoreForSessionToFact()
  ↓
计算分数 ≥ 70？
  ↓ YES
更新为 Fact 类型 + state
  ↓
✅ 晋升成功
```

### Fact → Core 流程

```
用户访问/更新 Fact 记忆
  ↓
recordAccess() / updateImportance()
  ↓
_upgradeSessionToFactIfNeeded()  // ✅ 先检测 Session → Fact
  ↓
_upgradeFactToCoreIfNeeded()
  ↓
shouldUpgradeToCoreWithPolicy()
  ↓
PromotionScorer.scoreForFactToCore()
  ↓
计算分数 ≥ 75？
  ↓ YES
更新为 Core 类型 + state
  ↓
✅ 晋升成功
```

## 📊 计分规则详解

### Session → Fact 计分表

| 条件                               | 权重       | 说明                 |
|----------------------------------|----------|--------------------|
| sessionSpan ≥ 2                  | +40      | 跨 2 个 session 重复出现 |
| userExplicitSave = true          | +40      | 用户明确要求记住           |
| referenceCount > 0               | +30      | 被引用过               |
| accessCount > 0                  | +30      | 被访问过               |
| contentType = preference/project | +30      | 稳定偏好或项目事实          |
| **类型加权**                         | ×0.3-1.5 | 根据 contentType 调整  |
| **冲突检测**                         | 归零       | 7 天内有冲突直接 0 分      |

### Fact → Core 计分表

| 条件                                     | 权重       | 最少规则数 |
|----------------------------------------|----------|-------|
| sessionSpan ≥ 3 && stability ≥ 0.8     | +25      | ✓     |
| hasImpactOnOutput (usage ≥ 5)          | +25      | ✓     |
| contentType = longTerm/core/constraint | +25      | ✓     |
| userConfirmedLongTerm = true           | +25      | ✓     |
| noRecentConflict (30 天)                | +20      | ✓     |
| **类型加权**                               | ×0.1-1.5 | -     |
| **最少规则数**                              | ≥2       | 必须满足  |

## 🎯 下一步工作

### 待完成的任务

1. **单元测试** ⏳
    - [ ] PromotionScorer 测试（各种场景）
    - [ ] MemoryContentType 自动分类测试
    - [ ] shouldUpgradeToFactWithPolicy 测试
    - [ ] shouldUpgradeToCoreWithPolicy 测试
    - [ ] _upgradeSessionToFactIfNeeded 测试

2. **真机测试** ⏳
    - [ ] 实际保存流程验证
    - [ ] 日志输出验证
    - [ ] 性能影响评估
    - [ ] 边界条件测试

3. **后续增强** ⏳
    - [ ] ConflictDetector 实现
    - [ ] PromotionStateMachine 实现
    - [ ] 观察期管理逻辑
    - [ ] 降级触发机制

## 📝 使用说明

### 如何触发 Session → Fact 晋升

**方式 1**: 重复保存相似内容

```dart
// 第 1 次保存
await useCases.addSessionMemory(entity1);  // sessionSpan = 1

// 第 2 次保存相似内容（会被识别为重复）
await useCases.addSessionMemory(entity2);  // sessionSpan = 2
// ↓ 自动触发检测
// ✅ 如果其他条件也满足，自动晋升为 Fact
```

**方式 2**: 用户明确说"记住"

```dart
// 内容包含"记住"、"记下来"等关键词
final entity = SummaryEntity.create(
  title: '记住这个配置',
  content: '...',
  userExplicitSave: true,  // 自动或手动设置
);
// ↓ 保存时自动检测
// ✅ 高分值（+40），容易达到 70 分阈值
```

**方式 3**: 频繁访问

```dart
// 保存后多次访问
await useCases.recordAccess(id);  // 每次访问都触发检测
// ↓ 累加 accessCount 分数
// ✅ 达到阈值自动晋升
```

### 预期日志输出

**Session → Fact 成功**:

```
I/flutter: ⬆️ [Promotion] Session eligible for promotion to Fact: GraphRAG 设计
I/flutter: 📊 [Promotion] Score details:
I/flutter:    - sessionSpan: 2
I/flutter:    - userExplicitSave: false
I/flutter:    - referenceCount: 1
I/flutter:    - accessCount: 3
I/flutter:    - contentType: projectContext
I/flutter: ✅ [Promotion] Promoted: Session → Fact
```

**Fact → Core 成功**:

```
I/flutter: ⬆️ [Promotion] Fact eligible for promotion to Core: Flutter 开发偏好
I/flutter: ✅ [Promotion] Promoted: Fact → Core
```

## ⚠️ 注意事项

1. **向后兼容性**
    - 旧的存储数据会自动使用默认值
    - fromJson() 方法会处理缺失字段
    - 不会破坏现有功能

2. **性能影响**
    - 每次保存/访问都会触发检测
    - 计分计算是轻量级的 O(1) 操作
    - 如有性能问题，可以添加防抖机制

3. **调试建议**
    - 关注 `[Promotion]` 标签的日志
    - 检查 sessionSpan 是否正确累加
    - 验证 contentType 自动分类是否准确

## 🎉 总结

本次重构完成了：

- ✅ 完整的晋升计分模型
- ✅ Session → Fact 自动检测
- ✅ Fact → Core 多维度评估
- ✅ 类型差异化策略
- ✅ 详细的日志输出
- ✅ 向后兼容的数据结构

**代码已就绪，可以开始测试！** 🚀
