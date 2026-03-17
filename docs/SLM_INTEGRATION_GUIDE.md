# SLM 集成实施指南

## 📋 概述

**目标**: 引入 MediaPipe LLM Inference + Qwen2.5-1.5B-Instruct 模型，实现智能记忆管理

**核心功能**:

- ✅ 智能 Topic 提取和聚类
- ✅ 语义相似度判断
- ✅ Session 批量合并为 Fact
- ✅ Fact 升级为 Core 的完整流程

**预计时间**: 7-8 天  
**难度等级**: ⭐⭐⭐⭐☆ (中等偏难)

---

## 🏗️ 架构规格

### 三层记忆架构

```
┌─────────────────────────────────────────────┐
│ Layer 3: Core Memory (核心记忆)              │
│ - 永久保存，不受遗忘曲线影响                  │
│ - 访问次数 ≥ 10 或重要性 ≥ 0.8               │
│ - 用户手动升级                               │
│ - 搜索优先级最高                             │
└─────────────────────────────────────────────┘
                ↑ ↓ 自动/手动升级
┌─────────────────────────────────────────────┐
│ Layer 2: Fact Memory (普通事实)              │
│ - 持久化存储，受遗忘曲线影响                  │
│ - 主动保存的重要信息                         │
│ - 30 天后开始重要性衰减                      │
│ - SLM 智能合并 Session                       │
└─────────────────────────────────────────────┘
                ↑ 自动合并
┌─────────────────────────────────────────────┐
│ Layer 1: Session Memory (会话记忆)           │
│ - 临时工作记忆                               │
│ - 2 小时自动清理                             │
│ - 相同 Topic ≥ 3 条自动合并为 Fact            │
│ - SLM 提取 Topic 和语义判断                   │
└─────────────────────────────────────────────┘
```

### 各层特性对比

| 特性       | Session  | Fact  | Core |
|----------|----------|-------|------|
| **保存时间** | 2 小时     | 永久    | 永久   |
| **遗忘曲线** | ❌ 不适用    | ✅ 受影响 | ❌ 免疫 |
| **清理方式** | 自动       | 手动    | 保护   |
| **触发来源** | 快速操作     | 分享/手动 | 升级   |
| **合并策略** | SLM 智能合并 | 用户主导  | 不可变  |
| **搜索权重** | 低        | 中     | 高    |
| **显示位置** | 普通       | 正常    | 置顶   |
| **数量限制** | 无        | 无     | ≤ 50 |

---

## 📦 技术规格

### 选型方案

**模型**: Qwen2.5-1.5B-Instruct-GGUF (q4_k_m 量化)  
**推理框架**: MediaPipe LLM Inference  
**模型大小**: ~1GB  
**支持语言**: 中文、英文双语

### 性能指标

| 操作         | 目标时间  | 说明    |
|------------|-------|-------|
| 模型加载       | < 5 秒 | 首次启动  |
| Topic 提取   | < 2 秒 | 单次推理  |
| 主题判断       | < 2 秒 | 单次推理  |
| Session 合并 | < 3 秒 | 3 条合并 |
| 升级理由生成     | < 2 秒 | 单次推理  |

### 运行约束与降级策略

为避免 SLM 集成影响主流程，以下约束必须同时满足：

| 项目     | 约束              | 说明                    |
|--------|-----------------|-----------------------|
| 冷启动策略  | 默认懒加载           | 首屏不阻塞，首次使用智能能力时再初始化模型 |
| 峰值内存   | 目标 < 1.8GB      | 超出后自动进入降级模式           |
| 并发推理   | 同时最多 1 个        | 统一进入队列，避免多任务争抢内存      |
| 单次排队时长 | < 10 秒          | 超时则降级为规则策略            |
| 存储占用   | 模型 + 缓存 < 2.5GB | 超限时停止下载并提示清理          |
| 网络失败   | 不阻塞保存流程         | 模型不可用时仅关闭智能功能，不影响记忆写入 |

**降级优先级**:

1. 使用缓存结果（已有 Topic / 合并结果 / 升级理由）
2. 使用规则策略（关键词、标题归一化、时间窗口）
3. 跳过智能合并，仅保留原始 Session / Fact
4. 保持基础记忆功能可用，不因为 SLM 失败阻断保存、搜索、展示

### SLM 服务方法规格

```
MemorySLMService
├── initialize()                    // 初始化并加载模型
├── extractTopic(title, content)    // 提取主题标签 (3-6 字)
├── isSameTopic(entityA, entityB)   // 判断是否同一主题
├── mergeSessions(List<Session>)    // 合并为结构化 Fact
├── generateUpgradeReason(Fact)     // 生成升级理由
└── dispose()                       // 释放资源
```

### 智能判定补充设计

#### Topic 语言策略

- 输入是中文时，输出中文 Topic
- 输入是英文时，输出英文 Topic
- 中英混合时，优先跟随标题主语言
- UI 展示允许多语言，不强制统一翻译为中文

#### 重要性评分规则

`importanceScore` 统一使用 `0.0 ~ 1.0` 浮点值，避免人工和自动逻辑冲突。

**建议组成**:

- 用户主动保存/分享：`+0.30`
- 被访问一次：`+0.05`，上限 `+0.30`
- 被搜索命中并点击：`+0.10`
- 被手动编辑：`+0.15`
- 被标记收藏或升级意图：`+0.20`
- 超过 30 天未访问：按周衰减 `-0.05`

**升级到 Core 建议条件**:

- `visitCount >= 10`，或
- `importanceScore >= 0.8`，或
- 用户手动确认升级

#### 合并判定规则

Session 自动合并不能只依赖 LLM 语义判断，必须增加规则层兜底：

1. 先做规则预筛选：标题归一化、标签重叠、时间窗口、来源类型
2. 再做 SLM Topic 提取与主题一致性判断
3. 仅当“规则分数 + 语义分数”达到阈值时才允许合并
4. 对低置信度结果保守处理：宁可不合并，也不要误合并

**推荐阈值**:

- 规则分数 `< 0.3`：直接判定不同主题
- 规则分数 `0.3 ~ 0.6`：进入 SLM 判断
- 综合分数 `>= 0.75`：允许自动合并
- 综合分数 `< 0.75`：保留原始 Session

#### Session 生命周期保护

- Session 默认 2 小时清理
- 若某条 Session 已进入候选批次，则至少延长 24 小时再清理
- 若批次内已有 2 条同 Topic Session，则新增同 Topic Session 进入保护窗口
- 清理任务必须跳过“待合并”“排队中”“推理失败待重试”的 Session

#### 模型分发与版本控制

- 模型下载必须支持断点续传
- 下载完成后必须校验 SHA256
- 模型文件命名包含版本号，例如：`qwen2.5-1.5b-instruct-q4_k_m.v1.gguf`
- 仅保留 1 个活跃版本和 1 个回滚版本
- 存储空间不足时，不启动下载并提示用户清理
- 模型升级不能影响已有记忆数据结构

#### 隐私与数据边界

- 推理默认完全本地执行，不上传记忆正文
- 日志中禁止记录完整原文，最多记录哈希、长度、耗时和错误码
- Topic 缓存和推理缓存需可清理
- 若后续接入远程模型，必须显式二次确认并提供开关

#### 可观测性指标

至少记录以下指标，用于后续调优：

- 模型初始化耗时
- 推理成功率 / 失败率
- 平均排队时长
- Topic 提取平均耗时
- 自动合并触发次数
- 自动合并撤销率或用户修正率
- Core 升级接受率

---

## 🎯 实施步骤

### 阶段 1：基础集成（第 1-2 天）

#### 步骤 1.1：添加依赖

**文件**: `pubspec.yaml`

```yaml
dependencies:
  media_pipe_llm_inference: ^0.1.0
  path_provider: ^2.1.3
  http: ^1.2.0
```

**执行**:

```bash
flutter pub get
```

**验证**:

```bash
flutter pub deps | grep media_pipe
```

---

#### 步骤 1.2：创建 SLM 服务类

**新建文件**: `lib/core/services/memory_slm_service.dart`

**核心思路**:

1. 使用单例模式，避免重复加载模型
2. 使用懒加载，在首次需要智能能力时再初始化模型
3. 首次使用时自动下载模型到应用目录，并支持断点续传、校验和版本管理
4. 实现 4 个核心推理方法：Topic 提取、主题判断、Session 合并、升级理由生成
5. 添加进度回调，支持 UI 显示下载进度
6. 增加任务队列与超时控制，避免多次并发推理
7. 提供降级策略：缓存命中、规则回退、智能功能关闭但基础功能可继续使用

**Prompt 设计语料**:

```
# Topic 提取 Prompt
角色：记忆整理助手
任务：从标题和内容中提取一个精确的主题标签
要求：
- 只输出一个 3-6 个字的主题标签
- 能够概括核心内容
- 不要包含标点符号
- 输出语言跟随输入主语言

# 主题判断 Prompt
角色：文本相似度判断助手
任务：判断两段文字是否讨论同一主题
输入：两段文字的标题和内容（前 100 字）
要求：
- 综合考虑标题和内容的语义
- 如果主题相似或相关，认为是同一主题
- 只回答"是"或"否"

# Session 合并 Prompt
角色：信息整理专家
任务：将多条零散记录整合为结构化的知识
要求：
- 提取一个精确的标题（10 字以内）
- 合并重复内容，保留关键信息
- 按逻辑分组，使用小标题
- 总字数控制在 300 字以内
- 提取 3-5 个关键词作为标签

# 升级理由生成 Prompt
角色：记忆管理顾问
任务：解释为什么这条记忆值得升级为核心记忆
输入：记忆的标题、访问次数、重要性、创建时间
要求：
- 用一句话说明升级理由
- 强调其价值和重要性
- 语气积极，突出优点
```

**验证**:

```bash
dart analyze lib/core/services/memory_slm_service.dart
```

**补充要求**:

- 初始化过程不得阻塞 App 首屏渲染
- 下载失败时，保存/展示/搜索流程必须继续可用
- 所有推理方法都应返回结构化结果：`success / fallbackUsed / latencyMs / errorCode`
- 加入 LRU 缓存，避免重复 Topic 提取和重复升级理由生成

---

#### 步骤 1.3：修改记忆类型定义

**文件**: `lib/core/domain/entities/summary_entity.dart`

**修改内容**:

1. 修改 `MemoryType` 枚举顺序和注释
2. 添加 `shouldUpgradeToCore` getter

**验证**:

```bash
dart analyze lib/core/domain/entities/summary_entity.dart
```

---

### 阶段 2：核心功能（第 3-5 天）

#### 步骤 2.1：优化 UseCase

**文件**: `lib/core/domain/usecases/summary_usecases.dart`

**新增方法**:

- `checkAndMergeSessionBatches()` - 检查并合并 Session 批次

**实现思路**:

1. 获取所有 Session 记忆
2. 先使用规则层预筛选候选批次（时间窗口、来源、标题、标签）
3. 使用 SLM 提取每个 Session 的 Topic
4. 按 Topic 聚类，并对边界情况做语义复核
5. 对满足条件的批次执行合并（≥3 条、总字符≥100、有访问记录）
6. 仅在 Fact 创建成功后删除原始 Session，避免数据丢失
7. 为待合并批次增加保护窗口，防止 2 小时内被提前清理

**修改方法**:

- `applyForgettingCurve()` - 跳过 Core 层，增加自动升级检查
- `cleanupSessionMemories()` - 清理时间改为 2 小时

**验证**:

```bash
dart analyze lib/core/domain/usecases/summary_usecases.dart
```

---

#### 步骤 2.2：修改保存服务

**文件**: `lib/core/services/summary_save_service.dart`

**修改点**: `memoryType` 分配逻辑

**规则**:

- QuickAction/Gesture/Voice → Session
- Share/Manual → Fact
- 其他 → Fact

**补充规则**:

- 保存动作失败时允许重试，但不得重复创建多条内容相同的 Session
- 对连续快速写入做去重保护（例如 30 秒内标题和正文高度相似）
- 若 SLM 不可用，仍按上述规则完成落库，不依赖模型可用性

**验证**:

```bash
dart analyze lib/core/services/summary_save_service.dart
```

---

### 阶段 3：UI 增强（第 6-7 天）

#### 步骤 3.1：创建升级对话框组件

**新建文件**: `lib/features/home/presentation/widgets/upgrade_dialog.dart`

**功能规格**:

1. 异步加载升级理由（调用 SLM）
2. 显示升级后的特权说明
3. 展示当前状态（访问次数、重要性）
4. 提供确认/取消按钮
5. 加载中显示进度指示器
6. 如果 SLM 超时或失败，使用预设文案兜底，不阻塞用户升级
7. 展示升级依据来源（访问次数达标 / 重要性达标 / 用户主动升级）

**验证**:

```bash
dart analyze lib/features/home/presentation/widgets/upgrade_dialog.dart
```

---

#### 步骤 3.2：在卡片上添加升级按钮

**文件**: `lib/features/home/presentation/widgets/summary_card.dart`

**UI 规格**:

- 图标：`Icons.star_outline`
- 颜色：`Colors.amber`
- 显示条件：`type == MemoryType.fact && shouldUpgradeToCore`
- 点击触发升级对话框
- 若处于自动推荐状态，增加轻量提示文案，避免用户不理解升级原因

**验证**:

```bash
dart analyze lib/features/home/presentation/widgets/summary_card.dart
```

---

## 🧪 测试验证

### 单元测试清单

```dart
// test/slm_service_test.dart

void main() {
  group('MemorySLMService Tests', () {
    test('模型初始化');
    test('Topic 提取');
    test('主题判断');
    test('Session 合并');
    test('升级理由生成');
  });

  group('三层架构 Tests', () {
    test('Session 自动清理');
    test('Session 批量合并');
    test('Fact 自动升级');
    test('Core 不受遗忘曲线影响');
  });

  group('降级策略 Tests', () {
    test('模型下载失败时不阻塞保存');
    test('SLM 超时后回退到规则策略');
    test('推理队列限制并发数为 1');
    test('候选 Session 在保护窗口内不会被清理');
  });

  group('数据安全 Tests', () {
    test('Fact 创建成功前不删除原始 Session');
    test('旧枚举数据可以正确迁移');
    test('日志不记录完整正文');
  });
}
```

**运行测试**:

```bash
flutter test test/slm_service_test.dart
```

---

## 🐛 常见问题排查

### 问题 1: 模型下载失败

**症状**: `Exception: 模型下载失败：HTTP 404`

**原因**: 网络连接问题或 HuggingFace 访问受限

**解决**:

### 方案 A: 使用国内镜像（推荐）

```bash
# 使用 ModelScope 镜像（阿里达摩院，速度快）
cd /tmp
curl -L -o qwen2.5-1.5b-instruct-q4_k_m.gguf \
  https://modelscope.cn/models/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf
```

### 方案 B: 使用 huggingface.com 镜像站

```bash
# 使用 hf-mirror.com 镜像
cd /tmp
curl -L -o qwen2.5-1.5b-instruct-q4_k_m.gguf \
  https://hf-mirror.com/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf
```

### 推送到安卓设备

```bash
# 查看连接的设备
adb devices

# 推送到模拟器或真机
adb push /tmp/qwen2.5-1.5b-instruct-q4_k_m.gguf \
  /sdcard/Android/data/com.ironion.localvault/files/models/

# 如果有多个设备，指定设备 ID
adb -s <device-id> push /tmp/qwen2.5-1.5b-instruct-q4_k_m.gguf \
  /sdcard/Android/data/com.ironion.localvault/files/models/
```

### 验证文件完整性

```bash
# 检查文件大小（应该约 1GB）
ls -lh /tmp/qwen2.5-1.5b-instruct-q4_k_m.gguf

# 检查 MD5（可选）
md5 /tmp/qwen2.5-1.5b-instruct-q4_k_m.gguf
```

---

### 问题 2: 编译错误 "MemoryType not found"

**症状**: 编译时报错找不到 `MemoryType.template`

**原因**: 代码中还有地方引用了旧的枚举值

**解决**:

```bash
# 搜索所有引用
grep -r "MemoryType.template" lib/

# 修改或删除相关代码
```

---

### 问题 3: 推理速度慢

**症状**: 每次推理超过 5 秒

**可能原因**:

1. 模型文件过大
2. 设备性能不足
3. 参数设置不合理

**优化方案**:

1. 降低 `maxTokens`: 设置为 `128` 而不是 `256`
2. 使用更小的模型：`Qwen2.5-0.5B`
3. 添加缓存机制（缓存常用 Topic 结果）
4. 批处理多个请求

---

### 问题 4: 内存占用过高

**症状**: 应用运行一段时间后内存持续增长

**解决**:

1. 确保及时调用 `dispose()` 释放资源
2. 避免频繁创建新的 LLM 实例（使用单例）
3. 控制并发请求数量
4. 监控内存使用情况

---

## ✅ 验收标准

完成所有步骤后，逐一验证以下功能：

### 基础功能

- [ ] 模型成功下载并加载 (< 5 秒)
- [ ] SLM 服务初始化成功
- [ ] 无编译错误和警告
- [ ] 首屏渲染不因模型初始化而阻塞
- [ ] 模型下载支持断点续传和 SHA256 校验

### 核心功能

- [ ] Topic 提取功能正常 (< 2 秒，输出语言跟随输入主语言)
- [ ] 主题判断功能正常 (< 2 秒，准确率 > 80%)
- [ ] Session 可以自动合并为 Fact (≥3 条同 Topic)
- [ ] Fact 可以升级为 Core (自动 + 手动)
- [ ] 升级按钮正确显示 (仅当满足条件时)
- [ ] 升级理由生成失败时可使用兜底文案

### 架构逻辑

- [ ] 遗忘曲线不影响 Core 层
- [ ] Session 在 2 小时后自动清理
- [ ] 自动升级逻辑正常工作
- [ ] 记忆类型分配符合预期
- [ ] 候选合并批次在保护窗口内不会被提前清理
- [ ] 合并逻辑采用“规则层 + SLM”双重判定
- [ ] Fact 落库成功后才删除原始 Session
- [ ] 旧数据枚举迁移无异常

### 用户体验

- [ ] 模型下载有进度提示
- [ ] 升级对话框显示正常
- [ ] 升级理由生成合理
- [ ] UI 响应流畅无明显卡顿
- [ ] 模型不可用时用户仍可正常保存、搜索、浏览记忆
- [ ] 失败提示可理解，不暴露底层技术细节

### 观测与隐私

- [ ] 可查看模型初始化耗时、推理成功率、自动合并次数等指标
- [ ] 日志中不包含完整记忆正文
- [ ] 用户可以清理模型缓存与推理缓存

---

## 📝 下一步

完成集成后：

1. **性能优化**: 添加缓存、批处理、减少推理次数，优先解决冷启动和内存峰值
2. **用户反馈**: 收集实际使用数据，调整阈值参数，重点观察误合并/漏合并
3. **模型调优**: 根据反馈优化 prompt 表述，并验证中英双语输出稳定性
4. **可观测性建设**: 建立指标面板，持续跟踪初始化耗时、超时率、升级接受率
5. **功能扩展**: 添加更多 SLM 应用场景（如自动摘要、标签推荐）

---

## 📚 参考资源

- **MediaPipe 官方文档**: https://developers.google.com/mediapipe/solutions/genai/llm_inference
- **Qwen2.5 GitHub**: https://github.com/QwenLM/Qwen2.5
- **GGUF 模型格式**: https://github.com/ggerganov/ggml/blob/master/docs/gguf.md
- **HuggingFace 模型页**: https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF

---

**最后更新**: 2026-03-18  
**维护者**: Ironion
