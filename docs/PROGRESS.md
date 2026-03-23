# LocalVault 应用开发进度

> 更新时间：2026-03-19  
> 本文档依据当前本地工作区的 git changes 整理。
>
> **技术路线调整**：经实践验证，MediaPipe + GGUF 方案存在兼容性问题（GGUF 格式不被 MediaPipe 支持），已切换至纯规则引擎方案。

## 项目概述

Local Vault 已经从早期“本地 AI 聊天壳”的方向，收敛为一个以本地记忆管理为核心的应用：

- 所有摘要、模板和备份均保存在本地。
- SLM 作为增强层接入，不阻断主流程。
- 当前主导航为“首页 / 模板 / 记忆 / 设置”。

## 当前状态概览

- 记忆三层模型 `session / fact / core` 已落地，并且有规则策略与 SLM 增强双链路。
- 记忆管理已经从设置中抽离为一级模块，模板记忆类型已移除，只保留事实、核心、会话三类记忆。
- 手势链路、白名单同步、诊断页、数据库查询页、备份导入页都已补齐。
- 保存链路已经支持保存前标题/标签预处理，以及保存页内的推荐预览。
- 事实记忆已支持手动升级为核心记忆，SLM 诊断页也已补齐设备内自检入口。

## 已完成能力

### 1. 应用壳与基础架构

- [x] Flutter + Riverpod + GoRouter + Hive 本地架构
- [x] `GetIt` 依赖注入初始化
- [x] Material 3 深浅色主题
- [x] 底部导航统一为“首页 / 模板 / 记忆 / 设置”
- [x] 设置页、搜索页、反馈页等基础路由整理完成

### 2. 记忆与摘要主链路

- [x] `SummaryEntity` 三层记忆模型：`session / fact / core`
- [x] Hive 摘要仓库 `summaries_v3`
- [x] 保存页新增标题、标签、备注统一整理逻辑
- [x] `SummaryMetadataService` 接入保存前标题与标签生成
- [x] 保存页支持“推荐标题和标签”预览并回填
- [x] 重复事实记忆检测与访问计数累加
- [x] 事实记忆合并候选返回与差异确认页
- [x] Session 批量构建、候选保护窗口、自动合并为 Fact
- [x] Fact 自动升级为 Core
- [x] 遗忘曲线与 App 恢复时清理
- [x] 首页摘要卡片颜色改为稳定、确定性的语义配色

### 3. 记忆管理模块

- [x] 记忆管理从设置中抽离为一级模块
- [x] 模块 UI 与其他页面风格对齐
- [x] 仅保留 `fact / core / session` 三类筛选
- [x] 移除记忆管理中的模板 tab
- [x] 支持搜索、统计概览、手动合并相似事实
- [x] 支持将事实记忆手动升级为核心记忆
- [x] 兼容旧版 `template` 类型存储值，读取时统一降级为 `fact`
- [x] 列表改为按需构建，减少大列表场景下的首屏构建压力

### 4. 模板模块

- [x] 模板独立存储为 `templates_v2`
- [x] 模板列表、增删改查
- [x] 默认模板自动初始化
- [x] 模板与记忆体系彻底解耦

### 5. 快捷操作与分享保存

- [x] Android TileService 快捷入口
- [x] QuickActionActivity / QuickSaveActivity
- [x] 文本分享、图片分享、剪贴板静默保存
- [x] `SaveCoordinator` 统一处理静默保存路径
- [x] 快捷操作复制与摘要访问链路统一走访问计数更新

### 6. 手势唤醒、白名单与诊断

- [x] 悬浮窗手势唤醒总开关
- [x] 手势配置页
- [x] 应用白名单页
- [x] Flutter 手势配置同步到原生偏好
- [x] Flutter 白名单同步到原生偏好
- [x] `FloatingWindowService` 直接拉起 QuickAction / QuickSave 原生活动页
- [x] 手势诊断页
- [x] 手势权限、服务状态、动作同步、白名单同步状态可视化

### 7. 设置、存储与备份

- [x] 存储空间页
- [x] 备份数据页
- [x] 创建本地备份
- [x] 分享备份
- [x] 删除备份
- [x] 导入备份
- [x] 导入前预解析与格式校验
- [x] 备份恢复覆盖当前摘要与模板
- [x] 模型缓存统计与清理
- [x] 数据库查询页，可直接查看摘要库和模板库原始记录

### 8. SLM 集成基础能力（已调整为规则引擎）

- [x] `MemorySLMService` 基础框架（保留降级回退逻辑）
- [x] `extractTopic`（规则引擎实现）
- [x] `isSameTopic`（Jaccard + BM25-lite 复合相似度）
- [x] `mergeSessions`（规则合并：去重 + 结构化）
- [x] `generateUpgradeReason`（规则生成）
- [x] `generateSummaryMetadata`（规则提取）
- [x] 串行队列、缓存、超时与错误码封装
- [x] JSON 外置配置：`slm_config / memory_policy_config / memory_theme_config`
- [x] 规则回退兜底，保证模型不可用时主流程不中断
- [x] SLM 诊断信息与设备内自检入口
- [ ] ❌ MediaPipe + GGUF 方案已废弃（技术路线调整） -> 目标方案llama.cpp

### 9. 测试与工程化

- [x] 记忆策略配置测试
- [x] 记忆主题配置测试
- [x] `SummaryEntity` 单元测试
- [x] `SummaryUseCases` 单元测试
- [x] `SummaryMetadataService` 单元测试
- [x] `StorageManagementService` 单元测试
- [x] `GestureDiagnosticsService` 单元测试
- [x] 手势配置 Provider 测试
- [x] 白名单 Provider 测试
- [x] 占位 OCR 集成测试已迁回 `test/`，不再阻塞全量 `flutter test`

## 最近一轮本地变更重点

- 记忆管理升级为一级模块，并重新整理了 UI 风格。
- 模板不再属于记忆类型，遗留模板型摘要仅做兼容读取。
- 设置页新增"诊断""查询数据库""存储空间""备份数据"等辅助能力。
- 备份页增加导入能力，并在导入前做 JSON 格式预校验。
- 手势和白名单配置改为同时同步原生层，便于服务侧真实生效。
- 诊断页可直接检查权限、服务运行状态、动作同步状态和白名单同步状态。
- 诊断页新增 SLM 运行状态、自检结果、模型文件与缓存可视化。
- 记忆管理页新增"升级为核心"交互，并把列表改成按需构建。
- SLM 相关配置被拆到 `assets/config/*.json`，不再全部写死在代码里。
- **技术路线调整**：放弃 MediaPipe + GGUF 方案，改用纯规则引擎 + 可选云端增强架构。
- Android 构建已移除 MediaPipe 原生库下载步骤，缓存目录命名已收敛为通用 `slm_cache`。
- `MemorySLMService` 已简化为纯规则引擎实现，不再尝试模型拷贝、符号探测或原生推理。
- 多语言兼容继续推进：权限弹窗、OCR 失败提示、悬浮保存按钮等用户可见文案已接入 `AppLocalizations`。
- 手势默认名称已改为稳定内部标识（`tap_2 / tap_3`），避免把中文展示文案写入持久化配置。
- 未使用的中文时间格式工具 `app_formatter.dart` 已清理，避免后续误接入旧中文相对时间格式。
- 二次复核已补齐摘要详情页“显示完整内容”按钮的本地化，并清理未使用的 `AppErrorHandler` 与中文异常消息。
- 占位主题兼容已集中到 `TopicPlaceholderUtils`，补齐 `通用主题` 以及西/法/德占位别名与前缀清理规则。
- `SummaryTextUtils` 与 `MemorySLMService` 已补充拉丁语系重音字符支持，并扩展西/法/德的规则词典、前导填充词与领域关键词识别。
- SLM 诊断样本文本与模型格式描述已接入多语言资源，诊断链路不再依赖写死的中英文提示。
- `de / es / fr / ja / ko` 的缺失翻译已补齐；当前对照 `app_en.arb` 的 key 缺口已归零，不再依赖英文回退兜底。
- `extractTopic()` 已补齐模板主题候选评分，优先从标题、标签与正文中抽取稳定主题而不是退回占位词。
- `SimilarityUtils` 已升级为 Jaccard + BM25-lite 复合相似度，并增加大写术语共现信号，兼顾英文近重复与中英混合技术主题。
- `mergeSessions()` 已支持按句去重、代表标题选择与标签并集，输出更稳定的结构化合并结果。
- 规则引擎已引入共享 `RuleSemanticProfile` 语义画像，开始把领域键、子主题、展示 topic/title 与标签从同一条规则链中解耦。
- Session batching 已改为基于 cluster 语义画像进行匹配，而不是只用首条记录做锚点，后续扩展规则时不再需要回改业务流程。

## 当前待推进项

### 近期待办（进行中）

- [x] Fact 手动升级为 Core 的独立 UI 流程
- [x] 增加设备内 SLM 自检入口，支持在目标真机上验证原生推理可用性
- [x] 为 SLM 推理增加更完整的可观测性指标
- [x] 优化记忆管理列表性能与大数据量下的交互体验
- [x] 清理 MediaPipe 相关依赖和代码（技术债清理）
  - [x] `pubspec.yaml` 中已无 `mediapipe_core` 和 `mediapipe_genai`
  - [x] 已移除 `android/app/build.gradle.kts` 中的 MediaPipe 原生库下载逻辑
  - [x] `memory_slm_service.dart` 已简化为纯规则引擎
- [x] 多语言兼容优化（i18n）
  - [x] 规则引擎中的占位标题/主题硬编码已完成收敛
    - [x] `MemorySLMService.generateSummaryMetadata()` 的默认标题改为 `AppLocalizations.pendingSummary`
    - [x] `extractTopic()` 回退主题改为基于 `temporaryTopic / generalTopic`
    - [x] 扩展占位词识别，兼容中英文日文韩文 `pending / untitled / temporary / uncategorized`
    - [x] 规则引擎标题/标签提取已补充中英日韩关键字、分词与脚本识别
    - [x] 权限说明、Usage Access 提示、OCR 文件读取失败提示、悬浮保存按钮已接入多语言资源
    - [x] 手势默认名称改为语言中立内部标识，避免本地化文案进入持久化层
    - [x] 已复核运行时用户可见硬编码文案，当前未发现新的 UI 漏网项
    - [x] 已继续检查其余规则文本中的语言耦合，收敛历史兼容别名、领域关键词词典与诊断自检样本文本
    - [x] 已补齐 `de / es / fr / ja / ko` 的剩余翻译覆盖，减少英文回退
- [x] 实现完整的规则引擎核心功能
  - [x] Topic 提取器（关键词 + 模板匹配）
  - [x] 相似度计算优化（Jaccard + BM25-lite 复合评分）
  - [x] 会话合并规则（去重 + 结构化）
  - [x] 检查所有正则表达式中的语言硬编码
  - [x] 为规则引擎添加多语言支持（中英文日文韩文检测与处理）

### 近期执行计划（2026-03-23 ~ 2026-04-15）

#### 第一阶段：状态压缩层增强 ✅ (已完成 - 2026-03-23)

- [x] 扩展 StateRecord schema，支持 task_state / project_state / user_preference_state / topic_state
- [x] 在 RuleBasedMemoryCompressor 中实现 compressToState 方法
- [x] 实现状态覆盖式更新与版本控制
- [x] 优化 _rebuildStateRecords 逻辑，支持多类型状态推导
- 📄 详细实现文档：`docs/implementation/state_compression_enhancement.md`

#### 第二阶段：标题生成结构化增强 ✅ (已完成 - 2026-03-23)

- [x] 构建 Topic Taxonomy 白名单和同义词映射表
- [x] 为 StructuredMemoryTitleGenerator 添加同义词归一化逻辑
- [x] 实现主题映射到标准主题（canonical topic）
- [x] 优化候选打分机制和标题长度动态压缩（8-20 字）
- [x] 添加多语言支持（中文、英文、西班牙文、法文等）
- [x] 实现单词边界匹配机制，避免误匹配
- [x] 通过 19 个测试用例验证优化效果
- 📄 详细实现文档：`docs/implementation/stage2_title_generation_enhancement.md`

#### 第三阶段：Hybrid Memory 三层架构落地

- [ ] 创建 HybridMemoryVault 类，实现分层读取策略
- [ ] 在 RuleBasedMemoryRetriever 中实现 Layer 1/2/3 智能检索
- [ ] 将 buildContext 接入现有记忆运行时流程
- [ ] 性能基准测试与集成测试

#### 第四阶段：用户体验优化

- [ ] 设置页说明当前使用"规则模式"及优势
- [ ] 添加降级提示（快速、离线、隐私）
- [ ] 设计可选的"云端增强"开关

### 中期目标

- [ ] 模型资源管理与版本管理（如启用云端增强）
- [ ] iOS 适配（规则引擎优先，云端增强可选）
- [ ] 数据加密能力
- [ ] 更完整的备份恢复策略与冲突处理
- [ ] 可选的云端 LLM 集成（DeepSeek、通义千问等）

## 当前已知约束

### 1. 技术路线调整：纯规则引擎 ✅

- **原方案问题**：MediaPipe + GGUF 存在技术不兼容（GGUF 格式不被 MediaPipe 支持）
- **新方案**：纯规则引擎 + 可选云端增强
  - 默认使用规则引擎（快速、离线、隐私）
  - 可选启用云端 LLM 增强（需联网，用户授权）
- **优势**：
  - ✅ 零依赖，包体积小（-500MB）
  - ✅ 毫秒级响应（< 50ms vs 2-5s）
  - ✅ 完全可控，行为可预测
  - ✅ 保持离线，符合隐私保护原则

### 2. 模型打包链路依赖本地资源

- Android 构建脚本会尝试从 `assets/models/` 同步模型到生成资产目录。
- 如果目标模型文件不存在，运行时会自动回退规则模式，而不是阻断应用启动。

### 3. 仍保留少量兼容层

- `StorageInitializer` 仍注册旧 `SummaryAdapter`。
- `features/summary/models/summary.dart` 等旧模型仍存在，用于兼容历史存储和渐进迁移。

## 结论

项目当前已经具备一条可用的本地记忆产品主链路：

- 可以保存、整理、搜索和管理本地摘要。
- 可以通过模板、分享、磁贴和手势快速进入保存流程。
- 可以诊断原生手势状态、查看数据库原始记录、备份和导入数据。
  - 可以在不依赖模型稳定可用的前提下，持续迭代 SLM 增强能力。 
