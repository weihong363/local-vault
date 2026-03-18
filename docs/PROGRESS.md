# LocalVault 应用开发进度

> 更新时间：2026-03-18  
> 本文档依据当前本地工作区的 git changes 整理。

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
- [x] 兼容旧版 `template` 类型存储值，读取时统一降级为 `fact`

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

### 8. SLM 集成基础能力

- [x] `MemorySLMService` 基础框架
- [x] `extractTopic`
- [x] `isSameTopic`
- [x] `mergeSessions`
- [x] `generateUpgradeReason`
- [x] `generateSummaryMetadata`
- [x] 串行队列、缓存、超时与错误码封装
- [x] JSON 外置配置：`slm_config / memory_policy_config / memory_theme_config`
- [x] 规则回退兜底，保证模型不可用时主流程不中断

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
- 设置页新增“诊断”“查询数据库”“存储空间”“备份数据”等辅助能力。
- 备份页增加导入能力，并在导入前做 JSON 格式预校验。
- 手势和白名单配置改为同时同步原生层，便于服务侧真实生效。
- 诊断页可直接检查权限、服务运行状态、动作同步状态和白名单同步状态。
- SLM 相关配置被拆到 `assets/config/*.json`，不再全部写死在代码里。

## 当前待推进项

### 近期待办

- [ ] Fact 手动升级为 Core 的独立 UI 流程
- [ ] 真机环境下继续验证 MediaPipe 原生推理可用性
- [ ] 为 SLM 推理增加更完整的可观测性指标
- [ ] 继续优化列表性能与大数据量下的交互体验

### 中期目标

- [ ] 模型资源管理与版本管理
- [ ] iOS 适配
- [ ] 数据加密能力
- [ ] 更完整的备份恢复策略与冲突处理

## 当前已知约束

### 1. MediaPipe 原生推理仍属于增强能力

- 当前代码已经具备 `MemorySLMService`、模型配置、资源复制和回退链路。
- 但在默认环境下，项目仍以规则回退为安全基线。
- 若需要尝试原生推理，需要在支持环境下显式启用 `--dart-define=ENABLE_MEDIAPIPE_SLM=true`。

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
