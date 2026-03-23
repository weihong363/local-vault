# Local Vault 架构迁移指南

## 📋 概述

本指南介绍如何将 Local Vault 项目从现有架构迁移到清洁架构（Clean Architecture）。

---

## 🏗️ 架构对比

### 旧架构
```
lib/features/summary/
├── models/
│   └── summary.dart (直接依赖 Hive)
├── domain/
│   ├── repositories/
│   │   └── summary_repository.dart (直接实现)
│   └── providers/
│       └── summary_provider.dart
```

### 新架构
```
lib/
├── core/
│   ├── di/
│   │   └── service_locator.dart (GetIt)
│   ├── domain/
│   │   ├── entities/
│   │   │   └── summary_entity.dart (纯 Dart)
│   │   ├── repositories/
│   │   │   └── summary_repository_interface.dart (接口)
│   │   └── usecases/
│   │       └── summary_usecases.dart (业务逻辑)
│   ├── providers/
│   │   └── summary_entities_provider.dart (新 Provider)
│   └── utils/
│       └── summary_adapter.dart (新旧模型互转)
└── infrastructure/
    └── repositories/
        └── hive_summary_repository.dart (Hive 实现)
```

---

## 📦 已完成的工作

### ✅ 1. Domain Layer（领域层）
- [x] `SummaryEntity` - 摘要领域实体
- [x] `TemplateEntity` - 模板领域实体
- [x] `SummaryRepositoryInterface` - 摘要仓库接口
- [x] `TemplateRepositoryInterface` - 模板仓库接口
- [x] `SummaryUseCases` - 摘要业务用例
- [x] `TemplateUseCases` - 模板业务用例

### ✅ 2. Infrastructure Layer（基础设施层）
- [x] `HiveSummaryRepository` - Hive 摘要仓库实现
- [x] `HiveTemplateRepository` - Hive 模板仓库实现

### ✅ 3. DI Layer（依赖注入）
- [x] `service_locator.dart` - GetIt 配置
- [x] `main.dart` - 初始化调用

### ✅ 4. 应用层重构
- [x] `SummarySaveService` - 静默保存已使用新架构

### ✅ 5. 新架构 Provider
- [x] `summary_entities_provider.dart` - 新架构 Summary Provider
- [x] `template_entities_provider.dart` - 新架构 Template Provider

### ✅ 6. 适配器（向后兼容）
- [x] `summary_adapter.dart` - Summary 新旧模型互转
- [x] `template_adapter.dart` - Template 新旧模型互转

---

## 🚀 迁移步骤

### 阶段 1：渐进式迁移（当前）
保持现有代码运行，逐步迁移新功能。

#### 使用新架构添加新功能
```dart
// 推荐：新功能使用新架构
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';

// 获取 UseCase
final useCases = sl<SummaryUseCases>();

// 创建并保存摘要
final summary = SummaryEntity.create(
  title: '新功能',
  content: '使用新架构...',
);
await useCases.addSummary(summary);
```

### 阶段 2：完全迁移（未来）
将所有 UI 层迁移到新架构。

---

## 💡 使用示例

### 1. 直接使用 UseCase（推荐）
```dart
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';

// 获取 UseCase
final useCases = sl<SummaryUseCases>();

// 添加摘要
await useCases.addSummary(summary);

// 查询所有摘要
final summaries = useCases.getAllSummaries();

// 搜索摘要
final results = useCases.searchSummaries('关键词');
```

### 2. 使用 Riverpod Provider
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';

// 在 ConsumerWidget 中使用
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(summaryEntityNotifierProvider);
    
    return summariesAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('错误: $error'),
      data: (summaries) => ListView.builder(
        itemCount: summaries.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(summaries[index].title),
        ),
      ),
    );
  }
}
```

### 3. 使用适配器（向后兼容）
```dart
import 'package:local_vault/core/utils/summary_adapter.dart';
import 'package:local_vault/features/summary/models/summary.dart' as old;

// 旧模型转新模型
final oldSummary = old.Summary.create(...);
final newEntity = SummaryAdapter.toEntity(oldSummary);

// 新模型转旧模型
final entity = SummaryEntity.create(...);
final oldModel = SummaryAdapter.fromEntity(entity);
```

---

## 📁 完整文件清单

### 新增文件
```
lib/
├── core/
│   ├── di/
│   │   └── service_locator.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── summary_entity.dart
│   │   │   └── template_entity.dart
│   │   ├── repositories/
│   │   │   ├── summary_repository_interface.dart
│   │   │   └── template_repository_interface.dart
│   │   └── usecases/
│   │       ├── summary_usecases.dart
│   │       └── template_usecases.dart
│   ├── providers/
│   │   ├── summary_entities_provider.dart
│   │   └── template_entities_provider.dart
│   └── utils/
│       ├── summary_adapter.dart
│       └── template_adapter.dart
├── infrastructure/
│   └── repositories/
│       ├── hive_summary_repository.dart
│       └── hive_template_repository.dart
├── ARCHITECTURE_EXAMPLE.md
└── MIGRATION_GUIDE.md (本文件)
```

### 修改文件
```
lib/
├── main.dart (添加 initializeDependencies 调用)
├── core/services/summary_save_service.dart (使用新架构静默保存)
pubspec.yaml (添加 get_it 依赖)
```

---

## 🎯 下一步行动

### 短期（推荐）
1. **新功能使用新架构** - 所有新增功能使用 UseCase
2. **逐步迁移 UI** - 选择 1-2 个页面先迁移到新 Provider
3. **添加单元测试** - 为 UseCase 编写测试

### 长期
1. **完全迁移 Summary UI** - 所有页面使用新 Provider
2. **完全迁移 Template UI** - 所有页面使用新 Provider
3. **删除旧代码** - 删除旧的 Repository 和 Provider
4. **添加 Memory 模块** - 使用新架构实现记忆功能

---

## ⚠️ 注意事项

1. **向后兼容** - 适配器保证新旧代码可以共存
2. **渐进式迁移** - 不要一次性全部迁移，风险太高
3. **测试覆盖** - 每个迁移步骤都要测试
4. **日志输出** - 关键操作添加 debugPrint 日志

---

## 📞 技术支持

如有问题，请检查：
1. `lib/ARCHITECTURE_EXAMPLE.md` - 使用示例
2. `lib/core/di/service_locator.dart` - 依赖注入配置
3. `lib/core/domain/usecases/` - 业务用例
