# Local Vault 项目架构图

> 更新时间：2026-03-18  
> 本文档基于当前本地工作区的实际代码结构整理，反映最新的记忆模块抽离、SLM 配置外置、手势诊断、备份导入和数据库查询能力。

## 项目定位

Local Vault 当前定位为一个 100% 本地、离线优先的记忆库应用，而不是通用聊天壳。

当前一级模块为：

- 首页
- 模板
- 记忆
- 设置

其中“记忆管理”已经从设置页抽离，成为底部导航中的一级模块。

## 当前系统分层

```text
┌──────────────────────────────────────────────────────────────┐
│ Presentation                                                │
│ - Flutter Pages / Widgets                                   │
│ - Riverpod Providers / Notifiers                            │
│ - GoRouter + BottomNavigation                               │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ Application / Services                                      │
│ - SummaryUseCases / TemplateUseCases                        │
│ - SummarySaveService / SaveCoordinator                      │
│ - SummaryMetadataService                                    │
│ - MemorySLMService                                          │
│ - StorageManagementService                                  │
│ - GestureDiagnosticsService                                 │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ Domain                                                      │
│ - SummaryEntity / TemplateEntity                            │
│ - SummaryMergeModels                                        │
│ - Repository Interfaces                                     │
│ - MemoryPolicyConfig / MemoryThemeConfig                    │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ Infrastructure                                              │
│ - HiveSummaryRepository  -> summaries_v3                    │
│ - HiveTemplateRepository -> templates_v2                    │
│ - SharedPreferences / App Support Directory                 │
└──────────────────────────────────────────────────────────────┘
                            ↕
┌──────────────────────────────────────────────────────────────┐
│ Native Android                                              │
│ - MainActivity MethodChannels                               │
│ - FloatingWindowService                                     │
│ - QuickActionActivity / QuickSaveActivity                   │
│ - TileService 快捷入口                                       │
└──────────────────────────────────────────────────────────────┘
```

## 核心运行链路

### 1. 保存与分享链路

```text
系统分享 / 磁贴 / 手势 / 剪贴板
        ↓
main.dart / ShareService / QuickSaveActivity
        ↓
SaveCoordinator / SavePage
        ↓
SummaryMetadataService
  - 规则生成标题与标签
  - 或调用 MemorySLMService 生成标题与标签
        ↓
SummarySaveService / SummaryUseCases
        ↓
HiveSummaryRepository -> summaries_v3
```

关键点：

- 保存前会统一走 `SummaryMetadataService`，做标题压缩、标签清洗、备注合并，以及 SLM 或规则回退。
- 保存页支持“推荐标题和标签”的预览，再决定是否应用到表单。
- 新增事实记忆时不再直接粗暴合并，而是返回合并候选，交由 `MemoryMergeDiffPage` 让用户确认。

### 2. 记忆生命周期链路

```text
Session
  - 快捷操作 / 手势 / 静默保存
  - 2 小时会话时效
  - 24 小时候选保护窗口
        ↓
Session 批次构建 + 规则分 + SLM 语义判断
        ↓
自动合并为 Fact
        ↓
访问次数 / 重要性达到阈值
        ↓
自动升级为 Core
```

当前三层记忆：

- `session`: 临时工作记忆，可被清理或批量合并。
- `fact`: 持久化事实记忆，受遗忘曲线影响。
- `core`: 核心记忆，不受遗忘曲线衰减影响。

当前策略由 `assets/config/memory_policy_config.json` 驱动，启动时通过 `MemoryPolicyConfig.load()` 注入。

### 3. 手势唤醒与白名单链路

```text
SettingsPage
  ├─ 手势配置
  ├─ 应用白名单
  └─ 诊断
        ↓
Riverpod Provider
  ├─ gesture_config_provider
  └─ app_whitelist_provider
        ↓
MethodChannel 同步到原生 SharedPreferences
        ↓
FloatingWindowService
  - 加速度传感器监听
  - 使用情况统计权限判断前台应用
  - 白名单过滤
        ↓
QuickActionActivity / QuickSaveActivity
```

关键点：

- Flutter 侧手势配置与白名单会在加载和更新时同步到原生层。
- `FloatingWindowService` 当前直接拉起原生活动页，不再依赖未消费的 `pendingAction` 作为主触发路径。
- `GestureDiagnosticsService` 会汇总权限、服务状态、原生动作配置和白名单同步状态。

### 4. 存储、备份与诊断链路

```text
StorageManagementService
  ├─ inspectStorage()
  ├─ createBackup()
  ├─ previewBackup()
  ├─ restoreBackup()
  ├─ clearBackupFiles()
  └─ clearModelCache()
```

对应 UI：

- `StorageSpacePage`: 查看摘要、模板、备份、模型、缓存占用。
- `BackupDataPage`: 创建、分享、删除、导入、恢复备份。
- `DatabaseInspectorPage`: 直接查看 `summaries_v3` / `templates_v2` 原始记录，并提示候选异常。
- `DiagnosticsPage`: 展示手势权限、服务状态、动作同步、白名单同步状态。

## 当前目录结构

```text
lib/
├── main.dart
├── core/
│   ├── config/
│   │   └── memory_policy_config.dart
│   ├── constants/
│   │   ├── app_routes.dart
│   │   ├── app_storage.dart
│   │   └── app_theme.dart
│   ├── di/
│   │   └── service_locator.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── summary_entity.dart
│   │   │   ├── summary_merge_models.dart
│   │   │   └── template_entity.dart
│   │   ├── repositories/
│   │   │   ├── summary_repository_interface.dart
│   │   │   └── template_repository_interface.dart
│   │   └── usecases/
│   │       ├── summary_usecases.dart
│   │       └── template_usecases.dart
│   ├── providers/
│   │   ├── summary_entities_provider.dart
│   │   ├── template_entities_provider.dart
│   │   ├── locale_provider.dart
│   │   └── theme_provider.dart
│   ├── services/
│   │   ├── app_settings_service.dart
│   │   ├── floating_window_service.dart
│   │   ├── gesture_diagnostics_service.dart
│   │   ├── memory_slm_config.dart
│   │   ├── memory_slm_service.dart
│   │   ├── save_coordinator.dart
│   │   ├── share_service.dart
│   │   ├── storage_management_service.dart
│   │   ├── summary_metadata_service.dart
│   │   └── summary_save_service.dart
│   ├── theme/
│   │   ├── memory_theme.dart
│   │   └── memory_theme_config.dart
│   ├── utils/
│   │   ├── architecture_verifier.dart
│   │   ├── similarity_utils.dart
│   │   ├── storage_initializer.dart
│   │   ├── summary_adapter.dart
│   │   └── summary_text_utils.dart
│   └── widgets/
│       ├── bottom_navigation.dart
│       └── quick_action_activity_page.dart
├── features/
│   ├── app_whitelist/
│   ├── gesture_config/
│   ├── home/
│   ├── inject/
│   ├── memory/
│   │   ├── presentation/pages/memory_management_page.dart
│   │   └── presentation/pages/memory_merge_diff_page.dart
│   ├── quick_action/
│   ├── save/
│   ├── search/
│   ├── settings/
│   │   └── presentation/pages/
│   │       ├── settings_page.dart
│   │       ├── storage_space_page.dart
│   │       ├── backup_data_page.dart
│   │       ├── database_inspector_page.dart
│   │       ├── diagnostics_page.dart
│   │       └── feedback_page.dart
│   ├── summary/
│   └── template/
├── infrastructure/
│   └── repositories/
│       ├── hive_summary_repository.dart
│       └── hive_template_repository.dart
└── ...

assets/
└── config/
    ├── memory_policy_config.json
    ├── memory_theme_config.json
    └── slm_config.json

android/app/src/main/kotlin/com/ironion/localvault/
├── MainActivity.kt
├── FloatingWindowService.kt
├── QuickActionActivity.kt
├── QuickSaveActivity.kt
├── BaseTileService.kt
├── TemplateTileService.kt
├── SummariesTileService.kt
├── SaveSummaryTileService.kt
└── InjectSummaryTileService.kt

test/
├── core/
│   ├── config/
│   ├── domain/
│   ├── services/
│   └── theme/
├── features/
│   ├── app_whitelist/
│   └── gesture_config/
└── ocr_chinese_integration_placeholder_test.dart
```

## 数据与配置

| 类型     | 当前实现                                      | 说明                                            |
|--------|-------------------------------------------|-----------------------------------------------|
| 摘要库    | `summaries_v3`                            | 保存 `SummaryEntity`，支持 `session / fact / core` |
| 模板库    | `templates_v2`                            | 独立模板数据，仓库首次初始化会补 9 个默认模板                      |
| 备份目录   | `backups/`                                | JSON 备份文件，当前 `schemaVersion = 1`              |
| 记忆策略   | `assets/config/memory_policy_config.json` | 控制清理、保护窗口、批量合并、升级阈值、遗忘曲线                      |
| 记忆主题   | `assets/config/memory_theme_config.json`  | 控制不同重要性档位的浅色视觉规则                              |
| SLM 配置 | `assets/config/slm_config.json`           | 控制模型路径、提示词、超时、缓存、启发式阈值                        |
| 覆盖文件   | `*.override.json`                         | 三套配置都支持 App Support Directory 下的覆盖文件          |

## SLM 与本地规则的协作方式

`MemorySLMService` 当前不是单点依赖，而是“能用则用、不能用立即回退”的增强层：

- 可调用能力：
  - `extractTopic`
  - `isSameTopic`
  - `mergeSessions`
  - `generateUpgradeReason`
  - `generateSummaryMetadata`
- 运行约束：
  - 推理请求串行排队
  - 命中缓存优先返回
  - 超时、缺模型、缺原生符号、插件异常时直接切规则回退
- 启用方式：
  - 默认保持安全降级
  - 需要在支持环境下通过 `--dart-define=ENABLE_MEDIAPIPE_SLM=true` 尝试原生推理

## 兼容性说明

- `MemoryType.template` 已从摘要域模型中移除，模板模块现在完全独立于记忆库。
- 旧数据里若仍存在 `template` 或存储值 `2`，`SummaryEntity.fromJson` 会兼容读取为 `fact`。
- `StorageInitializer` 仍保留旧 `SummaryAdapter` 注册，用于兼容历史 Hive 结构。
- `DatabaseInspectorPage` 会专门标记旧模板遗留记录和候选脏数据。

## 当前架构结论

当前项目已经从“摘要列表 + 模板 + 快捷入口”的早期形态，演进为一个以本地记忆生命周期为核心的应用：

- 首页负责浏览和访问。
- 模板模块负责复用提示词内容。
- 记忆模块负责查看、筛选、合并和维护三层记忆。
- 设置模块负责权限、手势、存储、备份、诊断和调试工具。

SLM 现阶段被设计为增强层，而不是单点依赖，因此即使模型不可用，保存、搜索、展示、合并建议和记忆清理仍然可以继续工作。
