# 记忆晋升机制使用示例

## 📖 快速开始

### 1. 基础使用 - 无需修改现有代码

新的晋升机制已经集成到现有的保存流程中，**不需要修改现有调用代码**。

```dart
// 原有的保存方式保持不变
await
useCases.addSessionMemory
(
summary); // ✅ 自动触发 Session → Fact 检测
await useCases.recordAccess(id); // ✅ 自动触发两级检测
await useCases.updateImportance(id, 0.8); // ✅ 自动触发两级检测
```

### 2. 查看晋升状态

```dart

final summary = useCases.getSummary(id);

// 查看当前状态
print
('Type: 
${summary.type}'); // session/fact/core
print('State: ${summary.state}'); // session/fact/core/observing/archived
print('Content Type: ${summary.contentType}'); // 自动分类结果

// 查看晋升指标
print('Session Span: ${summary.sessionSpan}'); // 跨 session 数
print('User Explicit Save: ${summary.userExplicitSave}'); // 用户明确要求
print('Reference Count: ${summary.referenceCount}'); // 被引用次数
print('Usage in Recommendations: ${
summary
.
usageInRecommendations
}
'
); // 影响力
```

## 🎯 触发晋升的场景

### Session → Fact 自动晋升

#### 场景 1：重复提及（sessionSpan ≥ 2）

```dart
// 第 1 次保存
await useCases.addSessionMemory(SummaryEntity.create(
  title: 'Flutter 状态管理',
  content: '我喜欢用 Riverpod',
));
// 日志：无晋升（sessionSpan = 1）

// 第 2 次保存相似内容（被识别为重复）
await useCases.addSessionMemory(SummaryEntity.create(
  title: 'Flutter 状态管理',
  content: '再次提到 Riverpod 很好用',
));
// ↓ 自动累加 sessionSpan = 2
// ↓ 自动触发 _upgradeSessionToFactIfNeeded()
// 日志：⬆️ [Promotion] Session eligible for promotion to Fact: Flutter 状态管理
// 日志：✅ [Promotion] Promoted: Session → Fact
```

#### 场景 2：用户明确说"记住"（userExplicitSave = true）

```dart
// 内容包含"记住"关键词，自动推断
final summary = SummaryEntity.create(
  title: '记住这个配置',
  content: '我喜欢暗黑模式',
);
// contentType 自动推断为 identityLevel
// userExplicitSave 可以通过规则引擎自动设置

await
useCases.addSessionMemory
(
summary
);
// ↓ +40 分（用户明确要求）
// ↓ 如果其他条件也满足，总分≥70，自动晋升
```

#### 场景 3：频繁访问（accessCount > 0）

```dart
// 保存 Session 记忆
await useCases.addSessionMemory(summary);

// 多次访问
await useCases.recordAccess(id);  // accessCount = 1
await useCases.recordAccess(id);  // accessCount = 2
await useCases.recordAccess(id);  // accessCount = 3

// ↓ 每次访问都触发检测
// ↓ accessCount > 0 贡献 +30 分
// ↓ 达到阈值自动晋升
```

### Fact → Core 自动晋升

#### 场景 1：长期稳定使用（sessionSpan ≥ 3 && stability ≥ 0.8）

```dart
// 一个 Fact 记忆在多个 session 中被反复提及
// sessionSpan = 5, stabilityScore = 0.9

await useCases.recordAccess(id);
// ↓ 触发 Fact → Core 检测
// ↓ scoreForFactToCore() 计算：+25 分（sessionSpan≥3）
// ↓ 如果其他条件也满足，总分≥75，进入观察期或直接晋升
```

#### 场景 2：对输出有影响力（usageInRecommendations ≥ 5）

```dart
// Fact 记忆被系统用于推荐/建议 5 次以上
// usageInRecommendations = 7

await useCases.updateImportance(id, 0.75);
// ↓ 触发检测
// ↓ +25 分（hasImpactOnOutput = true）
// ↓ 容易达到晋升阈值
```

#### 场景 3：用户确认长期有效（userConfirmedLongTerm = true）

```dart
// 用户通过 UI 明确标记为"长期偏好"
final updated = summary.copyWith(
  userConfirmedLongTerm: true,
);
await useCases.updateSummary(updated);

// ↓ +25 分（用户确认）
// ↓ 显著增加晋升概率
```

## 📊 计分示例

### 示例 1：典型的用户偏好晋升

```dart
// 用户多次提到喜欢暗黑模式
final summary = SummaryEntity(
  title: '暗黑模式偏好',
  content: '我喜欢暗黑模式',
  type: MemoryType.session,
  contentType: MemoryContentType.userPreference,  // 自动推断
  
  // 晋升指标
  sessionSpan: 2,              // 提到 2 次
  userExplicitSave: false,     // 没有明确说"记住"
  referenceCount: 1,           // 被引用 1 次
  accessCount: 3,              // 访问 3 次
  
  // 权重计算
  // 基础分：40 (sessionSpan≥2) + 30 (referenceCount>0) + 30 (accessCount>0) = 100
  // 类型加权：100 × 1.2 (userPreference) = 120
  // 最终分数：min(120, 100) = 100 ✅ 晋升！
);
```

### 示例 2：临时任务不晋升

```dart
// 一次性待办事项
final summary = SummaryEntity(
  title: '买咖啡',
  content: '记得买咖啡',
  type: MemoryType.session,
  contentType: MemoryContentType.temporaryTask,  // 临时任务
  
  // 晋升指标
  sessionSpan: 1,              // 只提到 1 次
  userExplicitSave: false,
  referenceCount: 0,
  accessCount: 0,
  
  // 权重计算
  // 基础分：0（没有任何条件满足）
  // 类型加权：0 × 0.3 (temporaryTask) = 0
  // 最终分数：0 ❌ 不晋升
);
```

### 示例 3：项目上下文快速晋升

```dart
// 核心项目信息
final summary = SummaryEntity(
  title: 'LocalVault 项目',
  content: '这是一个本地优先的记忆管理应用',
  type: MemoryType.session,
  contentType: MemoryContentType.coreProject,

  // 晋升指标
  sessionSpan: 3,
  // 提到 3 次
  userExplicitSave: true,
  // 用户说"这是重要项目"
  referenceCount: 5,
  // 频繁引用
  accessCount: 10, // 经常访问

  // 权重计算
  // 基础分：40 (sessionSpan≥2) + 40 (userExplicitSave) + 30 (referenceCount>0) + 30 (accessCount>0) = 140
  // 但最多只能 100 分，所以先 clamp 到 100
  // 类型加权：100 × 1.5 (coreProject) = 150
  // 最终分数：min(150, 100) = 100 ✅ 快速晋升！
);
```

## 🔍 调试技巧

### 查看详细日志

所有晋升操作都会输出详细日志：

```bash
# Session → Fact 成功
flutter logs | grep "\[Promotion\]"

# 预期输出:
# I/flutter: ⬆️ [Promotion] Session eligible for promotion to Fact: GraphRAG 设计
# I/flutter: 📊 [Promotion] Score details:
# I/flutter:    - sessionSpan: 2
# I/flutter:    - userExplicitSave: false
# I/flutter:    - referenceCount: 1
# I/flutter:    - accessCount: 3
# I/flutter:    - contentType: projectContext
# I/flutter: ✅ [Promotion] Promoted: Session → Fact
```

### 手动检查晋升条件

```dart

final summary = useCases.getSummary(id);

// 检查 Session → Fact 条件
if (
summary.type == MemoryType.session) {
final score = PromotionScorer.scoreForSessionToFact(
sessionSpan: summary.sessionSpan,
userExplicitSave: summary.userExplicitSave,
referenceCount: summary.referenceCount,
accessCount: summary.accessCount,
contentType: summary.contentType,
hasConflict: summary.lastConflictAt != null &&
DateTime.now().difference(summary.lastConflictAt!).inDays < 7,
);

print('Session→Fact Score: $score / 100');
print('Should upgrade: ${score >= 70}');
}

// 检查 Fact → Core 条件
if (summary.type == MemoryType.fact) {
final score = PromotionScorer.scoreForFactToCore(
sessionSpan: summary.sessionSpan,
stabilityScore: summary.stabilityScore,
hasImpactOnOutput: summary.usageInRecommendations >= 5,
contentType: summary.contentType,
userConfirmedLongTerm: summary.userConfirmedLongTerm,
hasRecentConflict: summary.lastConflictAt != null &&
DateTime.now().difference(summary.lastConflictAt!).inDays < 30,
usageInRecommendations: summary.usageInRecommendations,
);

print('Fact→Core Score: $score / 100');
print('Should upgrade: ${score >= 75}');
}
```

## ⚙️ 自定义策略

### 调整晋升阈值

虽然默认配置已经经过优化，但你可以通过 `MemoryPolicyConfig` 调整：

```dart
// TODO: 未来支持
final customConfig = MemoryPolicyConfig(
  sessionToFact: SessionToFactPolicy(
    minScore: 60,  // 降低阈值（默认 70）
    minSessionSpan: 2,
  ),
  factToCore: FactToCorePolicy(
    minScore: 70,  // 降低阈值（默认 75）
    observationPeriod: Duration(days: 14),  // 缩短观察期（默认 30 天）
  ),
);

final useCases = SummaryUseCases(repository, slmService, policyConfig: customConfig);
```

### 添加自定义内容类型

```dart
// TODO: 未来扩展示例
enum CustomMemoryContentType {
  // ... 现有类型
  customType,  // 新增
}

// 在 TypeWeights 中添加对应权重
static const customType = TypeWeights(1.0, 1.0);  // 中等速度
```

## 🐛 常见问题

### Q1: 为什么我的 Session 没有晋升？

**检查清单**:

- [ ] sessionSpan 是否 ≥ 2？
- [ ] 是否有冲突（lastConflictAt 在 7 天内）？
- [ ] 分数是否 ≥ 70？

**调试方法**:

```dart
print
('sessionSpan: 
${summary.sessionSpan}');
print('lastConflictAt: ${summary.lastConflictAt}');
final score = PromotionScorer.scoreForSessionToFact(...);
print('
Score: 
$
score
'
);
```

### Q2: 如何手动触发晋升？

目前晋升是自动的，但如果想手动触发：

```dart
// 方式 1：模拟访问
await
useCases.recordAccess
(
id);

// 方式 2：更新重要性
await useCases.updateImportance(id, 0.8);

// 方式 3：直接修改（不推荐）
final updated = summary.copyWith(
type: MemoryType.fact,
state: MemoryState.fact,
);
await useCases.updateSummary(updated);
```

### Q3: 晋升失败会影响性能吗？

不会。计分计算是 O(1) 的轻量级操作，不会造成性能瓶颈。

如果有大量记忆同时保存，可以考虑：

- 添加防抖机制（TODO）
- 批量处理（TODO）
- 异步处理（已经是）

## 📝 最佳实践

1. **让系统自动工作** - 不需要手动干预，系统会自动检测并晋升
2. **关注日志输出** - `[Promotion]` 标签会告诉你发生了什么
3. **理解内容类型** - 不同类型有不同的晋升速度
4. **避免频繁修改** - 会降低 stabilityScore，影响晋升
5. **合理设置冲突** - 有冲突时优先解决冲突，而不是晋升

---

*更多详细信息请参考：[MEMORY_PROMOTION_MECHANISM.md](MEMORY_PROMOTION_MECHANISM.md)*
