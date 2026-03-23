# 记忆晋升与降级机制规范

> 本文档定义了 LocalVault 记忆系统中 Session、Fact、Core 三层记忆之间的动态流转机制。

## 🎯 核心理念

**三层动态流转机制**：

```
session ⇄ fact ⇄ core
   ↑        ↑
   └────────┘ (可降级)
```

**核心原则**：

- 晋升 = 条件满足 + 无冲突检测
- 降级 = 保守执行 + 用户优先
- 有冲突的记忆，优先更新状态，不急着晋升层级

---

## 1️⃣ Session → Fact 晋升规则

### **主规则**（满足任意 1 条）+ **无明显冲突**

| 序号 | 条件                     | 权重 | 检测方式                                     | 说明               |
|----|------------------------|----|------------------------------------------|------------------|
| ✅  | **跨 2 个 session 重复出现** | 高  | `sessionSpan ≥ 2`                        | 不是单次会话的偶然提及      |
| ✅  | **用户明确要求记住**           | 高  | `userExplicitSave = true`                | "记住这个"/"记下来"等关键词 |
| ✅  | **后续检索/引用过**           | 中  | `accessCount > 0` ∨ `referenceCount > 0` | 证明有复用价值          |
| ✅  | **明显属于稳定偏好或项目事实**      | 中  | `contentType ∈ {preference, project}`    | 基于内容分类判断         |

### **前置条件：无冲突检测**

```dart
bool hasNoConflict() {
  // 检查是否有矛盾信息
  if (conflictsWithId != null) return false;

  // 检查稳定性（最近没有被大幅修改）
  if (stabilityScore < 0.6) return false;

  // 检查是否有更新的版本
  if (hasNewerVersion) return false;

  return true;
}
```

### **计分模型**（满分 100，≥70 且无冲突可晋升）

```dart
double scoreForSessionToFact() {
  double score = 0;

  // 主规则 1：跨 2 个 session 重复出现
  if (sessionSpan >= 2) score += 40;

  // 主规则 2：用户明确要求记住
  if (userExplicitSave) score += 40;

  // 主规则 3：后续检索/引用过
  if (referenceCount > 0 || accessCount > 0) score += 30;

  // 主规则 4：明显属于稳定偏好或项目事实
  if (contentType == userPreference || contentType == projectContext) score += 30;

  // 类型加权
  score *= typeWeights[contentType].promotionSpeed;

  // 冲突惩罚（如果有冲突，直接归零）
  if (!hasNoConflict()) return 0;

  return score.clamp(0, 100);
}
```

---

## 2️⃣ Fact → Core 晋升规则

### **主规则**（满足至少 2-3 条）+ **观察期**

| 序号 | 条件                      | 权重 | 检测方式                                                             | 说明         |
|----|-------------------------|----|------------------------------------------------------------------|------------|
| ✅  | **跨 3+ 个 session 保持一致** | 高  | `sessionSpan ≥ 3` ∧ `contentHash` 稳定                             | 长期一致性验证    |
| ✅  | **对后续输出持续有影响**          | 高  | `usageInRecommendations ≥ 5`                                     | 被系统反复使用    |
| ✅  | **属于长期偏好/目标/项目/约束**     | 高  | `contentType ∈ {longTermPreference, coreProject, keyConstraint}` | 内容分类 + 重要性 |
| ✅  | **用户明确确认长期有效**          | 高  | `userConfirmedLongTerm = true`                                   | 显式标记       |
| ✅  | **一段时间内没有冲突更新**         | 中  | `lastConflictAt == null` ∧ `daysSinceLastUpdate ≥ 30`            | 稳定性验证      |

### **观察期机制**

- **观察期时长**：30 天
- **进入条件**：满足至少 2 条主规则且 `stabilityScore ≥ 0.8`
- **晋升条件**：观察期结束且期间无新冲突

### **计分模型**（满分 100，≥75 且通过观察期可晋升）

```dart
double scoreForFactToCore() {
  double score = 0;
  int rulesMet = 0;
  
  // 主规则 1：跨 3+ 个 session 保持一致
  if (sessionSpan >= 3 && stabilityScore >= 0.8) {
    score += 25;
    rulesMet++;
  }
  
  // 主规则 2：对后续输出持续有影响
  if (hasImpactOnOutput()) {
    score += 25;
    rulesMet++;
  }
  
  // ... 其他规则
  
  // 至少满足 2-3 条才能进入观察期
  if (rulesMet < 2) return 0;
  
  // 类型加权
  score *= typeWeights[contentType].promotionSpeed;
  
  return score.clamp(0, 100);
}
```

---

## 3️⃣ 降级规则（保守执行）

### **Fact → Session 或 Archive**

**满足以下任意 2 条**：

| 条件                 | 检测方式                                              | 说明     |
|--------------------|---------------------------------------------------|--------|
| ⚠️ **被新事实冲突覆盖**    | `hasNewerFactWithConflict = true`                 | 如技术栈转换 |
| ⚠️ **长时间未使用且是阶段性** | `lastAccessedAt > 60 days` ∧ `isTemporary = true` | 临时任务过期 |
| ⚠️ **用户主动修改或撤销**   | `userModified = true` ∨ `userRevoked = true`      | 用户行为   |

### **Core → Fact**

**满足以下任意 2 条**：

| 条件                           | 检测方式                        | 说明   |
|------------------------------|-----------------------------|------|
| ⚠️ **原来以为是长期规则，后来发现只是阶段性偏好** | `cognitiveReversal = true`  | 认知反转 |
| ⚠️ **连续出现冲突信息**              | `consecutiveConflicts ≥ 2`  | 多次矛盾 |
| ⚠️ **用户明确改口**                | `userExplicitChange = true` | 用户撤销 |

### **降级计分模型**（满分 100，≥60 考虑降级）

```dart
double scoreForDemotion() {
  double score = 0;
  
  // 降级条件 1：被新事实冲突覆盖
  if (hasNewerConflictingFact) score += 50;
  
  // 降级条件 2：长时间未使用且是阶段性
  if (isLongUnusedAndTemporary()) score += 40;
  
  // 降级条件 3：用户主动修改或撤销
  if (userModified || userRevoked) score += 60;  // 用户行为权重最高
  
  // Core 降级需要更保守
  if (state == MemoryState.core) score *= 0.7;  // 降低 30%
  
  return score.clamp(0, 100);
}
```

---

## 4️⃣ 记忆内容类型分类

不同类型采用不同的晋升/降级阈值：

| 类型        | 升 Fact | 升 Core     | 降级策略 | 示例                 |
|-----------|--------|------------|------|--------------------|
| **临时任务**  | ❌ 很少   | ❌ 几乎不      | 快速降级 | "买咖啡"、"查快递"        |
| **用户偏好**  | 🟢 较容易 | 🟡 中等谨慎    | 慢速降级 | "喜欢暗黑模式"、"咖啡不加糖"   |
| **项目上下文** | 🟢 容易  | 🟡 仅长期主线   | 中速降级 | "在做 LocalVault 项目" |
| **身份级约束** | 🟡 中等  | 🟢 较容易但要确认 | 极慢降级 | "我是程序员"、"我在上海"     |
| **一次性细节** | ❌ 不建议  | ❌ 不会       | 自动清理 | "今天天气不错"           |

### **类型权重表**

```dart

const typeWeights = {
  MemoryContentType.temporaryTask: TypeWeights(0.3, 0.5), // 难升易降
  MemoryContentType.userPreference: TypeWeights(1.2, 1.3), // 易升难降
  MemoryContentType.projectContext: TypeWeights(1.5, 1.0), // 易升，仅主线进 core
  MemoryContentType.longTermGoal: TypeWeights(1.3, 1.2), // 中等偏快
  MemoryContentType.coreProject: TypeWeights(1.5, 1.1), // 易升，谨慎降
  MemoryContentType.keyConstraint: TypeWeights(1.2, 1.3), // 中等，升 core 要确认
  MemoryContentType.identityLevel: TypeWeights(1.0, 1.5), // 中等，极难降
  MemoryContentType.oneTimeDetail: TypeWeights(0.1, 0.2), // 不升自降
};
```

---

## 5️⃣ 冲突处理机制

### **核心原则**

> 有冲突的记忆，优先更新状态，不急着晋升层级。

### **冲突场景示例**

```dart
// 示例 1：技术栈转换
旧：
"
我现在主要做 Flutter
" (2024-01)
新："我现在转 React Native 了" (2024-06)

// 示例 2：居住地变更
旧："我住在上海" (2023-01)
新："我搬到北京了" (2024
-
03
)
```

### **冲突处理策略**

1. **保留时间戳**：记录新旧信息的更替关系
2. **降低稳定分**：`stabilityScore *= 0.7`
3. **用新信息覆盖旧状态**：更新 content，保留历史版本
4. **旧信息转 archive**：不移除，而是归档

### **冲突解决动作**

```dart
enum ResolutionAction {
  UPDATE_AND_ARCHIVE,  // 更新新的，归档旧的
  MERGE_AND_KEEP_BOTH, // 合并共存
  FLAG_FOR_REVIEW,     // 标记待用户确认
}
```

---

## 6️⃣ 完整流程图

```
┌─────────────┐
│  Session    │
└──────┬──────┘
       │
       │ 检测晋升条件（至少 1 条 + 无冲突）
       │ □ 跨 2 个 session (+40 分)
       │ □ 用户要求记住 (+40 分)
       │ □ 被检索/引用 (+30 分)
       │ □ 稳定偏好/项目 (+30 分)
       │
       │ 总分 ≥ 70？
       │ 且无冲突？
       ▼
┌─────────────┐
│    Fact     │ ← ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
└──────┬──────┘                        │
       │                              │ 降级（保守）
       │ 检测晋升条件（2-3 条 + 观察期）  □ 新事实冲突
       │ □ 跨 3+ session (+25 分)       □ 长时未用 + 阶段性
       │ □ 影响输出 (+25 分)           □ 用户修改/撤销
       │ □ 长期类型 (+25 分)
       │ □ 用户确认 (+25 分)
       │ □ 无冲突更新 (+20 分)
       │
       │ 总分 ≥ 75？
       │ 且规则数 ≥ 2？
       │ 且观察期 ≥ 30 天？
       ▼
┌─────────────┐
│    Core     │
└─────────────┘
```

---

## 7️⃣ 实现架构

### **包结构**

```
lib/core/memory_promotion/
├── models/
│   ├── memory_content_type.dart      # 内容类型枚举
│   ├── promotion_score.dart          # 计分组
│   ├── conflict_resolution.dart      # 冲突解决
│   └── type_weights.dart             # 类型权重
├── services/
│   ├── promotion_scorer.dart         # 计分引擎
│   ├── conflict_detector.dart        # 冲突检测
│   └── promotion_state_machine.dart  # 状态机
├── policies/
│   ├── promotion_policy.dart         # 晋升策略配置
│   └── demotion_policy.dart          # 降级策略配置
└── memory_promotion.dart             # 统一出口
```

### **与现有代码集成**

#### **现有代码位置**（已替换/增强）：

1. **`SummaryEntity.shouldUpgradeToCoreWithPolicy()`**
    - 位置：`lib/core/domain/entities/summary_entity.dart:146`
    - 状态：✅ **已完成** - 扩展为多维度评分（使用新的 PromotionScorer）
    - 变更：旧逻辑已删除，完全迁移到新计分引擎

2. **`SummaryUseCases._upgradeFactToCoreIfNeeded()`**
    - 位置：`lib/core/domain/usecases/summary_usecases.dart:747`
    - 状态：✅ **已完成** - 使用新的 PromotionScorer
    - 变更：添加了详细日志输出和状态字段更新

3. **`SummaryUseCases.addSessionMemory()`**
    - 位置：`lib/core/domain/usecases/summary_usecases.dart:420`
    - 状态：✅ **已完成** - 添加 Session → Fact 自动检测
    - 变更：保存后自动触发 `_upgradeSessionToFactIfNeeded()`

4. **`SummaryUseCases.recordAccess()`** 和 **`updateImportance()`**
    - 位置：`lib/core/domain/usecases/summary_usecases.dart:274, 281`
    - 状态：✅ **已完成** - 触发晋升检测（Session → Fact → Core）
    - 变更：两个方法都会触发两级晋升检测

5. **新增：`SummaryEntity.shouldUpgradeToFactWithPolicy()`**
    - 位置：`lib/core/domain/entities/summary_entity.dart:179`
    - 状态：✅ **已完成** - Session → Fact 判断方法
    - 变更：基于多维度评分的自动检测

---

## 8️⃣ 配置化策略

```dart
class MemoryPromotionPolicy {
  // Session → Fact
  static const sessionToFact = PromotionThreshold(
    minMainRules: 1,           // 至少满足 1 条主规则
    minScore: 70,              // 最低分数
    requireNoConflict: true,   // 必须无冲突
  );
  
  // Fact → Core
  static const factToCore = PromotionThreshold(
    minMainRules: 2,           // 至少满足 2 条
    minScore: 75,              // 最低分数
    requireObservation: true,  // 需要观察期
    observationPeriod: Duration(days: 30),
    requireNoConflict: true,   // 必须无冲突
  );
  
  // 降级
  static const demotion = DemotionThreshold(
    minReasons: 2,             // 至少满足 2 条原因
    minScore: 60,              // 最低分数
    requireUserConfirmForCore: true, // Core 降级需要用户确认
  );
}
```

---

## 9️⃣ 日志与调试

### **预期日志输出**

```dart
// Session → Fact 成功
I/flutter: ⬆
️
[
Promotion]

Session eligible
for

promotion to
Fact: GraphRAG 设计
I/flutter: ✅
[
Promotion] Promoted: Session →

Fact

// Fact → Core 进入观察期
I
/
flutter: ⏳
[
Promotion]

Fact entered

observation period
for
Core: Flutter 开发
偏
好
I/flutter: 📊
[
Promotion] Score: 78
,
Rules
met: 2
/
2

// Fact → Core 晋升成功
I/flutter: ✅
[
Promotion]

Fact promoted

to Core
after 30d
observation: Flutter 开发
偏
好

// 降级警告
I/flutter: ⚠
️
[
Demotion]

Fact at

risk of
demotion: 临
时
任
务
提
醒
I/flutter: 📊
[
Demotion] Score: 65
,
Reasons: 2
/
2

// 冲突检测
I/flutter: ⚠
️
[
Conflict]

Detected conflicting
memories: 技
术
栈
偏
好
I/flutter: 🔧
[
Conflict] Resolution: UPDATE_AND_ARCHIVE
```

---

## 🔟 单元测试要点

### **测试覆盖**

1. **计分准确性**：各种场景下的分数计算
2. **冲突检测**：识别矛盾信息
3. **观察期逻辑**：时间判断和状态流转
4. **类型权重**：不同类型的差异化处理
5. **降级保守性**：Core 降级需要用户确认

---

## 📋 变更清单

### **新增文件**

- ✅ `lib/core/memory_promotion/` (整个包)
    - ✅ `models/memory_content_type.dart` - 内容类型枚举
    - ✅ `models/memory_state.dart` - 记忆状态枚举
    - ✅ `models/type_weights.dart` - 类型权重配置
    - ✅ `services/promotion_scorer.dart` - 计分引擎
    - ✅ `memory_promotion.dart` - 统一出口

- ✅ `docs/MEMORY_PROMOTION_MECHANISM.md` (本文档)

### **修改文件**

- ✅ `lib/core/domain/entities/summary_entity.dart`
    - ✅ 添加：晋升相关字段（sessionSpan, userExplicitSave, referenceCount 等 15 个字段）
    - ✅ 添加：MemoryContentType 和 MemoryState 类型
    - ✅ 添加：`shouldUpgradeToFactWithPolicy()` 方法
    - ✅ 扩展：`shouldUpgradeToCoreWithPolicy()` 使用新计分
    - ✅ 更新：copyWith、toJson、fromJson 支持新字段

- ✅ `lib/core/domain/usecases/summary_usecases.dart`
    - ✅ 添加：`_upgradeSessionToFactIfNeeded()` 方法
    - ✅ 修改：`recordAccess()` 触发 Session → Fact 检测
    - ✅ 修改：`updateImportance()` 触发 Session → Fact 检测
    - ✅ 修改：`addSessionMemory()` 添加自动检测和 sessionSpan 累加
    - ✅ 修改：`_upgradeFactToCoreIfNeeded()` 使用新 Scorer 并添加日志

### **删除文件**

- ❌ 无（保持向后兼容，旧逻辑已迁移至 memory_promotion 包）
- ⚠️ 注意：旧的简单阈值判断逻辑已被新的多维度评分机制替代

---

## ✅ 实施步骤

1. ✅ 创建文档和规范
2. ✅ 实现 `memory_promotion` 包
    - ✅ MemoryContentType 枚举和自动分类
    - ✅ MemoryState 状态枚举
    - ✅ TypeWeights 类型权重
    - ✅ PromotionScorer 计分引擎
3. ✅ 在 `SummaryEntity` 中添加新方法
    - ✅ 15 个晋升相关字段
    - ✅ shouldUpgradeToFactWithPolicy() 方法
    - ✅ 更新序列化方法
4. ✅ 在 `SummaryUseCases` 中集成新逻辑
    - ✅ _upgradeSessionToFactIfNeeded() 方法
    - ✅ recordAccess() 触发两级检测
    - ✅ updateImportance() 触发两级检测
    - ✅ addSessionMemory() 添加 sessionSpan 累加
5. ⏳ 添加单元测试
    - ⏳ Session → Fact 场景测试
    - ⏳ Fact → Core 场景测试
    - ⏳ 降级风险评估测试
6. ⏳ 真机测试验证
    - ⏳ 实际保存流程验证
    - ⏳ 日志输出验证
    - ⏳ 性能影响评估

---

*最后更新时间：2026-03-23*
*版本：v1.0.0*
