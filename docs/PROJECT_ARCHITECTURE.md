# Local Vault 项目架构图

## 🎯 项目整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │  UI Widgets  │  │   Pages      │  │  Providers   │        │
│  │  (Flutter)   │  │              │  │  (Riverpod)  │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Application Layer                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    UseCases (业务用例)                      │  │
│  │  ┌──────────────────────┐  ┌──────────────────────┐     │  │
│  │  │  SummaryUseCases    │  │  TemplateUseCases    │     │  │
│  │  └──────────────────────┘  └──────────────────────┘     │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        Domain Layer                              │
│  ┌──────────────────────┐  ┌──────────────────────┐            │
│  │   Entities (实体)    │  │  Repositories (接口) │            │
│  │  - SummaryEntity     │  │  - SummaryRepository  │            │
│  │  - TemplateEntity    │  │  - TemplateRepository │            │
│  └──────────────────────┘  └──────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Repository Implementations                   │  │
│  │  ┌──────────────────────┐  ┌──────────────────────┐     │  │
│  │  │ HiveSummaryRepository │  │ HiveTemplateRepository│     │  │
│  │  └──────────────────────┘  └──────────────────────┘     │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  Data Sources                              │  │
│  │  ┌──────────────────────┐  ┌──────────────────────┐     │  │
│  │  │   Hive Boxes         │  │   Other (未来)       │     │  │
│  │  └──────────────────────┘  └──────────────────────┘     │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 详细目录结构

```
lib/
├── main.dart                                  # 应用入口
├── core/                                      # 核心模块
│   ├── constants/                             # 常量
│   │   ├── app_routes.dart                   # 路由定义
│   │   └── app_theme.dart                    # 主题配置
│   │
│   ├── di/                                    # 依赖注入
│   │   └── service_locator.dart              # GetIt 配置
│   │
│   ├── domain/                                # 领域层（新架构）
│   │   ├── entities/                          # 领域实体
│   │   │   ├── summary_entity.dart           # 摘要实体
│   │   │   └── template_entity.dart          # 模板实体
│   │   │
│   │   ├── repositories/                      # 仓库接口
│   │   │   ├── summary_repository_interface.dart
│   │   │   └── template_repository_interface.dart
│   │   │
│   │   └── usecases/                          # 业务用例
│   │       ├── summary_usecases.dart
│   │       └── template_usecases.dart
│   │
│   ├── providers/                             # 状态管理
│   │   ├── summary_provider.dart              # 旧架构 Provider
│   │   ├── template_provider.dart             # 旧架构 Provider
│   │   ├── summary_entities_provider.dart    # 新架构 Provider
│   │   └── template_entities_provider.dart   # 新架构 Provider
│   │
│   ├── services/                              # 核心服务
│   │   ├── summary_save_service.dart          # 摘要保存服务
│   │   ├── share_service.dart                # 分享服务
│   │   ├── floating_window_service.dart       # 悬浮窗服务
│   │   └── memory_slm_service.dart           # SLM 记忆处理服务（新增）
│   │
│   ├── utils/                                 # 工具类
│   │   ├── storage_initializer.dart           # 存储初始化
│   │   ├── app_permission_manager.dart        # 权限管理
│   │   ├── summary_adapter.dart              # Summary 新旧模型适配器
│   │   ├── template_adapter.dart             # Template 新旧模型适配器
│   │   ├── architecture_verifier.dart        # 架构验证工具
│   │   └── similarity_utils.dart             # 相似度计算工具
│   │
│   └── widgets/                               # 通用组件
│       ├── bottom_navigation.dart             # 底部导航
│       └── quick_action_activity_page.dart    # 快捷操作页面
│
├── features/                                  # 功能模块
│   ├── home/                                  # 首页
│   │   └── presentation/
│   │       └── pages/
│   │           ├── home_page.dart             # 旧架构首页
│   │           └── new_home_page.dart         # 新架构首页（示例）
│   │
│   ├── summary/                               # 摘要
│   │   ├── models/
│   │   │   └── summary.dart                   # 旧架构 Summary 模型
│   │   ├── domain/
│   │   │   ├── repositories/
│   │   │   │   └── summary_repository.dart   # 旧架构仓库
│   │   │   └── providers/
│   │   │       └── summary_provider.dart      # 旧架构 Provider
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── summary_detail_page.dart   # 摘要详情页
│   │       │   └── save_page.dart             # 保存页
│   │       └── widgets/
│   │           ├── summary_card.dart           # 摘要卡片
│   │           └── empty_state.dart            # 空状态
│   │
│   ├── template/                              # 模板
│   │   ├── models/
│   │   │   └── template.dart                  # 旧架构 Template 模型
│   │   ├── domain/
│   │   │   ├── repositories/
│   │   │   │   └── template_repository.dart  # 旧架构仓库
│   │   │   └── providers/
│   │   │       └── template_provider.dart     # 旧架构 Provider
│   │   └── presentation/
│   │       └── pages/
│   │           └── template_page.dart          # 模板页
│   │
│   ├── quick_action/                          # 快捷操作
│   │   ├── models/
│   │   │   └── quick_action_type.dart        # 快捷操作类型
│   │   └── presentation/
│   │       └── pages/
│   │           └── quick_action_page.dart      # 快捷操作页
│   │
│   ├── settings/                              # 设置
│   │   └── presentation/
│   │       └── pages/
│   │           ├── settings_page.dart          # 设置页
│   │           └── feedback_page.dart          # 反馈页
│   │
│   ├── search/                                # 搜索
│   │   └── presentation/
│   │       └── pages/
│   │           └── search_page.dart            # 搜索页
│   │
│   ├── inject/                                # 注入
│   │   └── presentation/
│   │       └── pages/
│   │           └── inject_page.dart            # 注入页
│   │
│   ├── gesture_config/                        # 手势配置
│   │   └── presentation/
│   │       └── pages/
│   │           └── gesture_config_page.dart    # 手势配置页
│   │
│   └── app_whitelist/                         # 应用白名单
│       └── presentation/
│           └── pages/
│               └── app_whitelist_page.dart     # 白名单页
│
├── infrastructure/                            # 基础设施层（新架构）
│   └── repositories/
│       ├── hive_summary_repository.dart       # Hive 摘要仓库实现
│       └── hive_template_repository.dart      # Hive 模板仓库实现
│
├── models/                                    # AI 模型文件（新增）
│   └── qwen2.5-1.5b-instruct.gguf            # Qwen2.5 SLM 模型 (~1GB)
│
└── ... 其他文件
```

---

## 🧠 记忆三层架构（SLM 增强版）

### 架构图

```
┌─────────────────────────────────────────────┐
│ Layer 3: Core Memory (核心记忆)              │
│ - 永久保存，不受遗忘曲线影响                  │
│ - 访问次数 ≥ 10 或重要性 ≥ 0.8               │
│ - 用户手动升级                               │
│ - 搜索优先级最高                             │
│ - SLM 生成升级理由                           │
└─────────────────────────────────────────────┘
                ↑ ↓ 自动/手动升级
┌─────────────────────────────────────────────┐
│ Layer 2: Fact Memory (普通事实)              │
│ - 持久化存储，受遗忘曲线影响                  │
│ - 主动保存的重要信息                         │
│ - 30 天后开始重要性衰减                      │
│ - 可升级为 Core                              │
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

### 升级机制

#### Session → Fact（自动）

```dart
条件：
1. 相同 Topic ≥ 3 条
2. 时间窗口：24 小时内
3. 总字符数 ≥ 100
4. 至少有一条被访问过

执行:
- SLM 提取公共 Topic
- SLM 智能合并内容
- 生成结构化 Fact
- 删除原始 Sessions
```

#### Fact → Core（半自动）

```dart
条件（满足任一即可）:
1. 访问次数 ≥ 10 次
2. 重要性 ≥ 0.8
3. 用户手动升级
4. 被引用/分享 ≥ 5 次

执行:
- SLM 生成升级理由
- 显示升级对话框
- 用户确认后升级
- 设置 importance = 0.8
```

### SLM 在三层架构中的作用

```
MemorySLMService
├── extractTopic()        → Session 聚类
├── isSameTopic()         → Topic 判断
├── mergeSessions()       → Session → Fact
├── generateUpgradeReason() → Fact → Core
└── (未来) summarizeFact()  → Fact 摘要优化
```

---

## 🔄 数据流

### 新架构数据流
```
用户操作 (UI)
    ↓
Provider (Riverpod)
    ↓
UseCases (业务用例)
    ↓
Repository Interface (抽象接口)
    ↓
Repository Implementation (Hive实现)
    ↓
Data Source (Hive Box)
```

### 旧架构数据流（保持兼容）
```
用户操作 (UI)
    ↓
Provider (旧)
    ↓
Repository (旧，直接实现)
    ↓
Data Source (Hive Box)
```

---

## 📊 新旧架构对比

| 方面 | 旧架构 | 新架构 |
|------|--------|--------|
| 依赖方向 | 高层依赖低层 | 依赖倒置 |
| 模型 | 直接依赖 Hive | 纯 Dart 实体 |
| Repository | 直接实现 | 接口 + 实现 |
| 测试 | 高难度 | 低难度 |
| 可替换性 | 低 | 高 |
| 向后兼容 | - | ✅ |

---

## 🎯 迁移策略

### 阶段 1：渐进式（当前）
- ✅ 新功能使用新架构
- ✅ 保持旧代码运行
- ✅ 通过 Adapter 互转

### 阶段 2：完全迁移（未来）
- ⏳ 迁移所有 UI 到新架构
- ⏳ 删除旧代码
- ⏳ 简化项目结构

---

## 💡 快速参考

### 获取 UseCase
```dart
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';

final useCases = sl<SummaryUseCases>();
```

### 使用新 Provider
```dart
import 'package:local_vault/core/providers/summary_entities_provider.dart';

final summaries = ref.watch(summaryEntityNotifierProvider);
```

### 测试新架构
1. 设置 → 架构测试 → 新架构首页测试
2. 设置 → 架构测试 → 运行架构验证
