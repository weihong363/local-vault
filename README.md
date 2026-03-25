# Local Vault

一个隐私优先的本地 AI 记忆管理应用，帮助用户智能整理、检索和沉淀知识，同时确保数据完全离线存储。

## ✨ 核心功能

### 🧠 智能记忆管理

- **三层记忆模型** - Session（会话）→ Fact（事实）→ Core（核心），模拟人类记忆沉淀过程
- **自动合并归类** - 基于语义相似度自动合并相关会话，形成结构化事实
- **智能标签提取** - 自动从内容中提取关键词作为标签，便于后续检索
- **遗忘曲线机制** - 长期未访问的记忆会自动降级或清理，保持知识库精简

### 🔐 隐私与安全

- **100% 本地存储** - 所有数据存储在设备本地，不上传云端
- **完全离线运行** - 无需网络连接，保护用户隐私
- **数据加密支持** - 敏感数据可选加密存储，加密主要用于保护“静态数据（存储）”和“备份数据（导出）”
- **无追踪分析** - 不包含任何第三方统计或广告 SDK

### ⚡ 快捷操作

- **悬浮窗手势唤醒** - 支持双击、三击等手势快速唤起保存界面 -- 开发中
- **文本/图片分享保存** - 从其他应用一键分享内容到 Local Vault -- 开发中
- **剪贴板静默保存** - 自动检测剪贴板内容并快速保存

### 🎯 模板系统

- **自定义模板库** - 预设常用格式，快速创建结构化笔记
- **模板分类管理** - 按场景组织模板，提高复用效率
- **默认模板初始化** - 内置会议记录、学习笔记等常用模板

### 🔍 高效检索

- **全文搜索** - 支持标题、内容、标签的多维度搜索
- **语义筛选** - 按记忆类型（会话/事实/核心）、标签、时间范围筛选
- **智能排序** - 按相关性、访问时间、重要性等多种排序方式

### 🌍 多语言支持

- **完整国际化** - 支持中文、英文、日文、韩文、德文、法文、西班牙文
- **本地化 UI** - 所有用户可见文案均已适配多语言
- **智能语言识别** - 自动识别输入内容的语言类型

## 🏗️ 架构设计

项目采用**清洁架构（Clean Architecture）** + **领域驱动设计（DDD）**，分为以下层次：

```
lib/
├── core/                    # 核心层
│   ├── di/                  # 依赖注入（GetIt）
│   ├── domain/              # 领域层（实体、接口、业务规则）
│   ├── infrastructure/      # 基础设施层（Hive 实现）
│   └── providers/           # Riverpod 状态管理
├── features/                # 功能模块
│   ├── home/                # 首页模块
│   ├── memory/              # 记忆管理模块
│   ├── templates/           # 模板模块
│   └── settings/            # 设置模块
└── l10n/                    # 国际化资源
```

### 架构文档

- [项目架构图](docs/PROJECT_ARCHITECTURE.md) - 完整架构图和目录结构
- [开发进度](docs/PROGRESS.md) - 详细的功能完成情况和待办事项
- [记忆架构](docs/MEMORY_ARCHITECTURE.md) - 三层记忆模型详解
- [SLM 集成指南](docs/SLM_INTEGRATION_GUIDE.md) - SLM 规则引擎集成方案 -- 待更新
- [增强处理流程](docs/ENHANCEMENT_PROCESS.md) - 状态压缩与标题生成增强

## 🛠️ 技术栈

### 核心框架

- **Flutter** 3+ - 跨平台 UI 框架
- **Dart** 3+ - 类型安全的编程语言

### 状态管理

- **Riverpod** - 编译时安全的状态管理
- **GoRouter** - 声明式路由导航

### 数据存储

- **Hive** - 轻量级 NoSQL 本地数据库
- **SharedPreferences** - 偏好设置存储
- **JSON** - 备份文件格式

### 架构模式

- **Clean Architecture** - 清洁架构
- **Domain-Driven Design** - 领域驱动设计
- **Repository Pattern** - 仓库模式

### 工具与库

- **GetIt** - 服务定位器（依赖注入）
- **path_provider** - 文件系统路径获取
- **share_plus** - 系统分享功能
- **permission_handler** - 权限管理
- **image_picker** - 图片选择能力

### SLM 与智能处理

- **纯规则引擎** - 基于关键词匹配、BM25-lite 和 Jaccard 相似度的本地智能处理
- **降级策略** - 模型不可用时自动回退到规则引擎，保证主流程不中断

## 📱 快速开始

### 环境要求

- Flutter SDK >= 3.16
- Dart SDK >= 3.2
- Android Studio / Xcode
- Android API 21+ / iOS 12+

### 1. 克隆项目

```bash
git clone <repository-url>
cd local-vault
```

### 2. 安装依赖
```bash
flutter pub get
```

### 3. 运行应用
```bash
# Android
flutter run

# iOS (macOS only)
flutter run -d ios
```

### 4. 构建发布版本

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

### 5. 运行测试

```bash
# 单元测试
flutter test

# 带覆盖率报告
flutter test --coverage

# 真机数据测试（需先导出数据）
flutter test test/core/services/memory_rule_engine_real_data_test.dart
```

## 📚 文档索引

### 架构与设计

- [项目架构图](docs/PROJECT_ARCHITECTURE.md) - 完整架构图和目录结构
- [开发进度](docs/PROGRESS.md) - 详细的功能完成情况和待办事项

### 功能说明

- [记忆架构](docs/MEMORY_ARCHITECTURE.md) - 三层记忆模型详解
- [SLM 集成指南](docs/SLM_INTEGRATION_GUIDE.md) - 规则引擎与 SLM 增强方案
- [记忆合并优化](docs/MEMORY_MERGE_FIXES.md) - 智能合并与主题提取机制
- [升级机制](docs/MEMORY_PROMOTION_MECHANISM.md) - Fact 到 Core 的自动升级逻辑

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 🎯 核心功能使用

### 记忆管理流程

#### 1. 保存内容

```dart
// 通过 SaveCoordinator 保存内容
final coordinator = sl<SaveCoordinator>();
await
coordinator.saveContent
(
text: '今天学习了 Flutter 的 Riverpod 状态管理...',
source: SaveSource.share,
);
```

#### 2. 查看和管理记忆

- 打开「记忆」标签页
- 按类型筛选：会话 / 事实 / 核心
- 搜索关键词或标签
- 长按可进行编辑、删除、升级等操作

#### 3. 使用模板

```dart
// 在保存页面选择模板
final template = TemplateEntity(
  title: '会议记录',
  content: '## 会议主题\n## 参会人员\n## 讨论内容\n## 待办事项',
);
```

### 代码示例

#### 直接使用 UseCase
```dart
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';

final useCases = sl<SummaryUseCases>();
await useCases.addSummary(summary);
```

#### 使用 Riverpod Provider
```dart
import 'package:local_vault/core/providers/summary_entities_provider.dart';

final summaries = ref.watch(summaryEntityNotifierProvider);
```

#### 调用规则引擎

```dart
import 'package:local_vault/core/services/memory_slm_service.dart';

final engine = sl<MemorySLMService>();

// 提取主题
final topicResponse = await
engine.extractTopic
(title, content);

final topic = topicResponse.data;

// 判断相似度
final isSame = await
engine.isSameTopic
(entityA, entityB);

// 合并会话
final result = await
engine.mergeSessions
(
sessions
);
```

### 技术路线说明

当前 SLM 相关能力采用**纯规则引擎 + 可选云端增强**方案：

- ✅ **规则引擎**：基于关键词匹配、BM25-lite 相似度、Jaccard 系数实现本地智能处理
- ✅ **降级策略**：模型不可用时自动回退到规则引擎，保证主流程不中断
- ❌ **MediaPipe + GGUF**：因兼容性问题已废弃
- 🔮 **未来扩展**：保留 SLM 接口，支持后续接入 llama.cpp 或其他端侧推理框架

## 📄 许可证

本项目采用 Apache License 2.0 许可证。

查看完整许可证：[LICENSE](LICENSE)

