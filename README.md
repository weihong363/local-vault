# Local Vault

一个隐私优先的本地 AI 聊天应用，帮助用户在各 AI 平台之间参考上下文，同时确保数据隐私。

## ✨ 功能特性

- 📝 **本地保存** - 所有数据存储在本地，不上传云端
- 🔍 **快速搜索** - 全文搜索标题、内容和标签
- 📱 **快捷操作** - 控制中心快捷方式、悬浮窗手势唤醒
- 🎯 **模板管理** - 自定义快捷模板
- 🔐 **隐私保护** - 完全离线，数据加密
- 🚀 **性能优化** - 支持拖拽排序、响应式设计

## 🏗️ 架构

项目采用**清洁架构（Clean Architecture）**，分为以下层次：

- **Domain Layer** - 领域层（实体、接口、业务用例）
- **Infrastructure Layer** - 基础设施层（Hive 实现）
- **Application Layer** - 应用层（UseCases）
- **Presentation Layer** - 展示层（UI、Riverpod）

### 架构文档

- [项目架构图](PROJECT_ARCHITECTURE.md) - 完整架构图和目录结构
- [重构总结](ARCHITECTURE_SUMMARY.md) - 清洁架构重构总结
- [迁移指南](MIGRATION_GUIDE.md) - 新旧架构迁移指南
- [使用示例](ARCHITECTURE_EXAMPLE.md) - 快速使用示例

## 🛠️ 技术栈

- **框架**: Flutter 3+
- **状态管理**: Riverpod
- **路由**: GoRouter
- **本地存储**: Hive
- **依赖注入**: GetIt
- **架构**: 清洁架构（Clean Architecture）

## 📱 快速开始

### 1. 安装依赖
```bash
flutter pub get
```

### 2. 运行应用
```bash
flutter run
```

### 3. 测试新架构
1. 打开应用
2. 进入「设置」页面
3. 找到「架构测试」部分
4. 点击「运行架构验证」或「新架构首页测试」

## 📚 文档

更多详细信息请查看：

- [项目架构图](PROJECT_ARCHITECTURE.md)
- [清洁架构重构总结](ARCHITECTURE_SUMMARY.md)
- [迁移指南](MIGRATION_GUIDE.md)
- [使用示例](ARCHITECTURE_EXAMPLE.md)
- [进度记录](PROGRESS.md)

## 🎯 使用新架构

### 直接使用 UseCase
```dart
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';

final useCases = sl<SummaryUseCases>();
await useCases.addSummary(summary);
```

### 使用 Riverpod Provider
```dart
import 'package:local_vault/core/providers/summary_entities_provider.dart';

final summaries = ref.watch(summaryEntityNotifierProvider);
```

## 📄 许可证

本项目采用 MIT 许可证。

