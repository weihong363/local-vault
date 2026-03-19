# SLM 集成实施指南

> 更新时间：2026-03-18  
> 本文档已从“纯规划文档”更新为“当前落地状态 + 后续推进建议”。

## 当前结论

Local Vault 的 SLM 集成已经进入“可运行的增强层”阶段，而不是纸面设计阶段。

当前项目里的 SLM 方案具备以下特点：

- 已经有真实的 `MemorySLMService` 实现，而不是占位接口。
- 已经接入记忆合并、主题提取、升级理由、保存时标题标签生成。
- 已经把策略和提示词外置到 JSON 配置，而不是全部硬编码。
- 已经默认采用“模型不可用时立即回退规则”的安全策略。

换句话说，当前 SLM 的定位是：

**增强记忆质量，但绝不阻断保存、检索、展示和清理主流程。**

## 当前配置目标

### 模型与推理框架

- 推理框架：当前默认走本地规则引擎
- 当前配置目标模型：`qwen2.5-0.5b-instruct-q4_k_m.gguf`
- 模型资源路径配置：`models/qwen2.5-0.5b-instruct-q4_k_m.gguf`
- Android 构建会尝试从 `assets/models/` 同步该模型到生成资产目录

说明：

- 仓库当前配置已经从旧的 1.5B 目标切换为 0.5B 目标。
- 如果构建时或运行时找不到模型资源，不会阻断应用，而是直接切换到规则回退模式。

### 启用方式

当前 SLM 原生推理属于实验性启用：

```bash
flutter run --dart-define=ENABLE_MEDIAPIPE_SLM=true
```

如果未显式开启，或者运行环境缺少可用原生符号，`MemorySLMService` 会保持可初始化但不可用的降级状态。

## 当前已落地能力

| 能力           | 当前状态 | 主要落点                                                                    |
|--------------|------|-------------------------------------------------------------------------|
| Topic 提取     | 已落地  | `MemorySLMService.extractTopic()`                                       |
| 同主题判断        | 已落地  | `MemorySLMService.isSameTopic()`                                        |
| Session 批量合并 | 已落地  | `MemorySLMService.mergeSessions()` + `SummaryUseCases`                  |
| Core 升级理由生成  | 已落地  | `MemorySLMService.generateUpgradeReason()`                              |
| 保存时标题/标签生成   | 已落地  | `MemorySLMService.generateSummaryMetadata()` + `SummaryMetadataService` |
| 保存页推荐预览      | 已落地  | `SavePage` + `SummaryMetadataService.preparePreview()`                  |
| 队列、缓存、超时     | 已落地  | `MemorySLMService`                                                      |
| 规则回退         | 已落地  | `MemorySLMService` + `SummaryTextUtils`                                 |
| JSON 外置配置    | 已落地  | `assets/config/*.json`                                                  |
| 模型缓存清理与空间统计  | 已落地  | `StorageManagementService`                                              |

## 核心文件分工

### 1. SLM 配置

- `assets/config/slm_config.json`
- `lib/core/services/memory_slm_config.dart`

职责：

- 定义模型文件名、模型资源路径、缓存目录名
- 定义超时、最大队列等待时间、缓存上限、温度、`topK`
- 定义提示词、格式模板、长度限制和回退文案
- 支持通过 App Support Directory 下的 `slm/slm_config.override.json` 覆盖默认配置

### 2. SLM 运行时服务

- `lib/core/services/memory_slm_service.dart`

职责：

- 惰性初始化模型
- 检查原生推理是否可用
- 尝试复制 bundled model
- 串行调度推理请求
- 对 Topic / Upgrade Reason 做缓存
- 对所有能力统一返回 `success / fallbackUsed / latencyMs / errorCode`

### 3. 保存前元数据整理

- `lib/core/services/summary_metadata_service.dart`
- `lib/features/save/presentation/pages/save_page.dart`

职责：

- 统一处理标题压缩、备注合并、标签清洗
- 根据设置决定走规则生成还是 SLM 生成
- 支持预览模式和保存模式
- 如果用户手动填写了可靠的标题/标签，可优先保留人工输入

### 4. 和记忆策略的衔接

- `lib/core/domain/usecases/summary_usecases.dart`
- `lib/core/config/memory_policy_config.dart`
- `assets/config/memory_policy_config.json`

职责：

- 构建 Session 批次
- 根据规则分和 SLM 结果判断是否属于同一主题
- 自动合并成 Fact
- 根据访问次数和重要性阈值升级为 Core
- 执行遗忘曲线和 Session 清理

## 当前运行架构

```text
SavePage / SummarySaveService / SaveCoordinator
                    ↓
          SummaryMetadataService
          ├─ 规则生成标题与标签
          └─ 或调用 MemorySLMService
                    ↓
             SummaryUseCases
          ├─ 去重
          ├─ Session 批量合并
          ├─ Fact -> Core 自动升级
          └─ 遗忘曲线 / 清理
                    ↓
            HiveSummaryRepository
```

## 当前降级策略

`MemorySLMService` 当前有 4 种返回模式：

| 模式         | 含义         | 触发场景               |
|------------|------------|--------------------|
| `none`     | 成功使用模型     | 模型可用且结果可解析         |
| `cache`    | 命中缓存       | 重复 Topic 或升级理由请求   |
| `rules`    | 规则回退       | 模型不可用、超时、结果为空、解析失败 |
| `disabled` | 显式禁用或环境不可用 | 当前构建不支持原生推理        |

当前的设计原则是：

1. 能用缓存就先用缓存。
2. 模型不可用时立即使用规则结果。
3. 即使没有模型，也不能影响保存、搜索、清理和展示。

## 当前策略参数

以下关键策略已经外置到 `memory_policy_config.json`：

- Session 最大年龄：2 小时
- 候选保护窗口：24 小时
- Fact 遗忘曲线开始时间：30 天
- Core 自动升级阈值：
  - `accessCount >= 10`
  - 或 `importance >= 0.8`
- Session 批量合并最小数量：3
- 规则与语义综合阈值：`0.75`

这些值不再需要改 Dart 常量才能调整。

## 当前提示词配置

`slm_config.json` 中已维护以下 prompt：

- `extractTopic`
- `sameTopic`
- `mergeSessions`
- `upgradeReason`
- `summaryMetadata`

同时还有这些配套配置：

- `formatting`: 标题、标签、内容的模板化格式
- `limits`: 内容截断长度、标签数量、主题长度
- `fallbacks`: 模型失败时的兜底标题、主题和升级理由
- `heuristics`: 标签重叠、升级阈值等启发式参数

这意味着后续优化 prompt 时，大部分改动已经可以不动业务代码。

## 和记忆系统的真实衔接方式

### 1. Session -> Fact

当前不是“只靠 LLM 判断”：

- 先按时间窗口、标题、语义相似度、标签重叠、来源等规则计算候选分数
- 分数达到一定条件后，再结合 SLM 判断或规则回退
- 只有满足阈值的批次才会自动合并

### 2. Fact -> Core

当前是自动升级逻辑先落地：

- `SummaryEntity.shouldUpgradeToCoreWithPolicy()`
- `SummaryUseCases` 在新增、更新、访问、重要性变化后触发检查

手动升级 UI 仍然是下一阶段工作。

### 3. 保存时标题和标签

当前保存链路已经全面接入 `SummaryMetadataService`：

- `preparePreview()` 用于保存页预览
- `prepareForSave()` 用于真实保存
- 可根据设置切换“规则生成”或“SLM 生成”
- 如果模型失败，会落回规则生成，不影响保存成功

## 存储与可维护性

SLM 不只体现在推理本身，当前还配套了存储能力：

- `StorageManagementService.inspectStorage()` 会统计模型文件和缓存占用
- `StorageManagementService.clearModelCache()` 可清理 SLM 运行缓存
- 备份导出不会丢失摘要和模板主数据
- 数据库查询页可直接检查摘要库是否存在旧模板遗留或脏数据

## 当前测试覆盖

本地已经补齐一批与 SLM 相关的测试：

- `test/core/services/memory_slm_config_test.dart`
- `test/core/services/summary_metadata_service_test.dart`
- `test/core/domain/usecases/summary_usecases_test.dart`
- `test/core/config/memory_policy_config_test.dart`
- `test/core/theme/memory_theme_config_test.dart`
- `test/core/services/storage_management_service_test.dart`

这些测试主要覆盖：

- 配置解析与 override 机制
- 元数据生成的规则回退
- Session 合并与升级阈值
- 备份、恢复、预览与非法格式校验

## 当前还没完成的部分

### 1. 真机原生推理闭环验证

当前代码已经具备原生推理入口，但还需要继续在支持环境下确认：

- 模型实际打包是否稳定
- 原生符号是否可用
- 首次复制模型和初始化耗时是否符合预期

### 2. 手动升级 UI

当前自动升级逻辑已完成，但缺少完整的“用户手动升级 Fact -> Core”交互入口。

### 3. 更强的可观测性

目前 `MemorySLMService` 已返回耗时和错误码，但还没有形成统一的可视化统计面板。

### 4. 模型版本管理

当前已经有模型路径配置和缓存清理，但还没有完整的模型版本切换、校验和回滚机制。

## 当前建议

如果接下来继续推进 SLM，建议按这个顺序：

1. 先补“真机原生推理可用性验证”。
2. 再补“手动升级 Core UI”。
3. 再做“模型版本管理与更多可观测性”。

这样可以保证当前规则回退主链路稳定的前提下，再逐步把 SLM 从增强层提升为更可靠的默认能力。
