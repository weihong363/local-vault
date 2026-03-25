# Local Vault Architecture Migration Guide

## 📋 Overview

This guide explains how to migrate the Local Vault project from the existing architecture to Clean Architecture.

---

## 🏗️ Architecture Comparison

### Old Architecture
```
lib/features/summary/
├── models/
│   └── summary.dart (directly depends on Hive)
├── domain/
│   ├── repositories/
│   │   └── summary_repository.dart (direct implementation)
│   └── providers/
│       └── summary_provider.dart
```

### New Architecture
```
lib/
├── core/
│   ├── di/
│   │   └── service_locator.dart (GetIt)
│   ├── domain/
│   │   ├── entities/
│   │   │   └── summary_entity.dart (pure Dart)
│   │   ├── repositories/
│   │   │   └── summary_repository_interface.dart (interface)
│   │   └── usecases/
│   │       └── summary_usecases.dart (business logic)
│   ├── providers/
│   │   └── summary_entities_provider.dart (new Provider)
│   └── utils/
│       └── summary_adapter.dart (old/new model conversion)
└── infrastructure/
    └── repositories/
        └── hive_summary_repository.dart (Hive implementation)
```

---

## 📦 Completed Work

### ✅ 1. Domain Layer

- [x] `SummaryEntity` - summary domain entity
- [x] `TemplateEntity` - template domain entity
- [x] `SummaryRepositoryInterface` - summary repository interface
- [x] `TemplateRepositoryInterface` - template repository interface
- [x] `SummaryUseCases` - summary business use cases
- [x] `TemplateUseCases` - template business use cases

### ✅ 2. Infrastructure Layer

- [x] `HiveSummaryRepository` - Hive summary repository implementation
- [x] `HiveTemplateRepository` - Hive template repository implementation

### ✅ 3. DI Layer

- [x] `service_locator.dart` - GetIt configuration
- [x] `main.dart` - initialization call

### ✅ 4. Application Layer Refactoring

- [x] `SummarySaveService` - silent saving already uses new architecture

### ✅ 5. New Architecture Provider

- [x] `summary_entities_provider.dart` - new architecture Summary Provider
- [x] `template_entities_provider.dart` - new architecture Template Provider

### ✅ 6. Adapters (Backward Compatibility)

- [x] `summary_adapter.dart` - Summary old/new model conversion
- [x] `template_adapter.dart` - Template old/new model conversion

---

## 🚀 Migration Steps

### Phase 1: Progressive Migration (Current)

Keep existing code running, gradually migrate new features.

#### Using New Architecture for New Features
```dart
// Recommended: Use new architecture for new features
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';

// Get UseCase
final useCases = sl<SummaryUseCases>();

// Create and save summary
final summary = SummaryEntity.create(
  title: 'New Feature',
  content: 'Using new architecture...',
);
await useCases.addSummary(summary);
```

### Phase 2: Complete Migration (Future)

Migrate all UI layers to the new architecture.

---

## 💡 Usage Examples

### 1. Directly Use UseCase (Recommended)
```dart
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';

// Get UseCase
final useCases = sl<SummaryUseCases>();

// Add summary
await useCases.addSummary(summary);

// Query all summaries
final summaries = useCases.getAllSummaries();

// Search summaries
final results = useCases.searchSummaries('keyword'
);
```

### 2. Using Riverpod Provider
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';

// Use in ConsumerWidget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(summaryEntityNotifierProvider);
    
    return summariesAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
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

### 3. Using Adapters (Backward Compatibility)
```dart
import 'package:local_vault/core/utils/summary_adapter.dart';
import 'package:local_vault/features/summary/models/summary.dart' as old;

// Old model to new model
final oldSummary = old.Summary.create(...);
final newEntity = SummaryAdapter.toEntity(oldSummary);

// New model to old model
final entity = SummaryEntity.create(...);
final oldModel = SummaryAdapter.fromEntity(entity);
```

---

## 📁 Complete File List

### New Files
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
└── MIGRATION_GUIDE.md (this file)
```

### Modified Files
```
lib/
├── main.dart (add initializeDependencies call)
├── core/services/summary_save_service.dart (use new architecture for silent saving)
pubspec.yaml (add get_it dependency)
```

---

## 🎯 Next Steps

### Short-term (Recommended)

1. **Use new architecture for new features** - All new features use UseCase
2. **Gradually migrate UI** - Select 1-2 pages to migrate to new Provider first
3. **Add unit tests** - Write tests for UseCase

### Long-term

1. **Complete migration of Summary UI** - All pages use new Provider
2. **Complete migration of Template UI** - All pages use new Provider
3. **Delete old code** - Remove old Repository and Provider
4. **Add Memory module** - Implement memory functionality using new architecture

---

## ⚠️ Notes

1. **Backward compatibility** - Adapters ensure old and new code can coexist
2. **Progressive migration** - Don't migrate all at once, too risky
3. **Test coverage** - Test each migration step
4. **Log output** - Add debugPrint logs for key operations

---

## 📞 Technical Support

If you have questions, please check:

1. `lib/ARCHITECTURE_EXAMPLE.md` - Usage examples
2. `lib/core/di/service_locator.dart` - Dependency injection configuration
3. `lib/core/domain/usecases/` - Business use cases
