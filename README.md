# Local Vault

A privacy-first local AI memory management application that helps users intelligently organize, search, and refine
knowledge while ensuring completely offline data storage.

## ✨ Core Features

### 🧠 Intelligent Memory Management

- **Three-Layer Memory Model** - Session → Fact → Core, simulating the human memory refinement process
- **Automatic Merging & Categorization** - Automatically merges related sessions based on semantic similarity to form
  structured facts
- **Smart Tag Extraction** - Automatically extracts keywords from content as tags for easier retrieval
- **Forgetting Curve Mechanism** - Memories not accessed for a long time are automatically downgraded or cleaned up to
  keep the knowledge base streamlined

### 🔐 Privacy & Security

- **100% Local Storage** - All data stored locally on the device, never uploaded to the cloud
- **Completely Offline Operation** - No network connection required, protecting user privacy
- **Encryption Support** - Sensitive data can be optionally encrypted; encryption is primarily used to protect "static
  data (storage)" and "backup data (export)"
- **No Tracking or Analytics** - Contains no third-party analytics or advertising SDKs

### ⚡ Quick Actions

- **Floating Window Gesture Activation** - Supports double-tap, triple-tap, and other gestures to quickly invoke the
  save interface -- In Development
- **Text/Image Share Save** - One-tap sharing from other apps to Local Vault -- In Development
- **Clipboard Silent Save** - Automatically detects clipboard content and saves quickly

### 🎯 Template System

- **Custom Template Library** - Pre-configured common formats for quick structured note creation
- **Template Category Management** - Organizes templates by scenario for improved reuse efficiency
- **Default Template Initialization** - Built-in templates for meeting notes, learning notes, and more

### 🔍 Efficient Search

- **Full-Text Search** - Multi-dimensional search across titles, content, and tags
- **Semantic Filtering** - Filter by memory type (Session/Fact/Core), tags, and time range
- **Smart Sorting** - Sort by relevance, access time, importance, and more

### 🌍 Multi-Language Support

- **Complete Internationalization** - Supports Chinese, English, Japanese, Korean, German, French, and Spanish
- **Localized UI** - All user-facing content adapted for multiple languages
- **Smart Language Recognition** - Automatically identifies the language type of input content

## 🏗️ Architecture Design

The project adopts **Clean Architecture** + **Domain-Driven Design (DDD)**, organized into the following layers:

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

### Architecture Documentation

- [Project Architecture](docs/PROJECT_ARCHITECTURE.md) - Complete architecture diagram and directory structure
- [Development Progress](docs/PROGRESS.md) - Detailed feature completion status and pending items
- [Memory Architecture](docs/MEMORY_ARCHITECTURE.md) - Three-layer memory model details
- [SLM Integration Guide](docs/SLM_INTEGRATION_GUIDE.md) - SLM rule engine integration plan -- To be updated
- [Enhancement Process](docs/ENHANCEMENT_PROCESS.md) - State compression and title generation enhancements

## 🛠️ Technology Stack

### Core Frameworks

- **Flutter** 3+ - Cross-platform UI framework
- **Dart** 3+ - Type-safe programming language

### State Management

- **Riverpod** - Compile-time safe state management
- **GoRouter** - Declarative routing navigation

### Data Storage

- **Hive** - Lightweight NoSQL local database
- **SharedPreferences** - Preferences storage
- **JSON** - Backup file format

### Architecture Patterns

- **Clean Architecture** - Clean architecture
- **Domain-Driven Design** - Domain-driven design
- **Repository Pattern** - Repository pattern

### Tools & Libraries

- **GetIt** - Service locator (dependency injection)
- **path_provider** - File system path retrieval
- **share_plus** - System sharing functionality
- **permission_handler** - Permission management
- **image_picker** - Image selection capability

### SLM & Intelligent Processing

- **Pure Rule Engine** - Local intelligent processing based on keyword matching, BM25-lite, and Jaccard similarity
- **Fallback Strategy** - Automatically falls back to rule engine when model is unavailable, ensuring uninterrupted main
  workflow

## 📱 Quick Start

### Environment Requirements

- Flutter SDK >= 3.16
- Dart SDK >= 3.2
- Android Studio / Xcode
- Android API 21+ / iOS 12+

### 1. Clone the Repository

```bash
git clone <repository-url>
cd local-vault
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the Application
```bash
# Android
flutter run

# iOS (macOS only)
flutter run -d ios
```

### 4. Build Release Version

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

### 5. Run Tests

```bash
# Unit tests
flutter test

# With coverage report
flutter test --coverage

# Real device data test (requires data export first)
flutter test test/core/services/memory_rule_engine_real_data_test.dart
```

## 📚 Documentation Index

### Architecture & Design

- [Project Architecture](docs/PROJECT_ARCHITECTURE.md) - Complete architecture diagram and directory structure
- [Development Progress](docs/PROGRESS.md) - Detailed feature completion status and pending items

### Feature Documentation

- [Memory Architecture](docs/MEMORY_ARCHITECTURE.md) - Three-layer memory model details
- [SLM Integration Guide](docs/SLM_INTEGRATION_GUIDE.md) - Rule engine and SLM enhancement plan
- [Memory Merge Optimization](docs/MEMORY_MERGE_FIXES.md) - Intelligent merging and theme extraction mechanism
- [Promotion Mechanism](docs/MEMORY_PROMOTION_MECHANISM.md) - Automatic upgrade logic from Fact to Core

## 🤝 Contributing

Issues and Pull Requests are welcome!

## 🎯 Core Feature Usage

### Memory Management Workflow

#### 1. Save Content

```dart
// Save content via SaveCoordinator
final coordinator = sl<SaveCoordinator>();
await
coordinator.saveContent
(
text: 'Learned about Flutter\'s Riverpod state management today...',
source: SaveSource.share,
);
```

#### 2. View and Manage Memories

- Open the "Memories" tab
- Filter by type: Session/Fact/Core
- Search by keywords or tags
- Long-press to edit, delete, upgrade, etc.

#### 3. Use Templates

```dart
// Select a template on the save page
final template = TemplateEntity(
  title: 'Meeting Notes',
  content: '## Meeting Topic\n## Attendees\n## Discussion Points\n## Action Items',
);
```

### Code Examples

#### Using UseCase Directly
```dart
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';

final useCases = sl<SummaryUseCases>();
await useCases.addSummary(summary);
```

#### Using Riverpod Provider
```dart
import 'package:local_vault/core/providers/summary_entities_provider.dart';

final summaries = ref.watch(summaryEntityNotifierProvider);
```

#### Calling the Rule Engine

```dart
import 'package:local_vault/core/services/memory_slm_service.dart';

final engine = sl<MemorySLMService>();

// Extract topic
final topicResponse = await
engine.extractTopic
(title, content);

final topic = topicResponse.data;

// Check similarity
final isSame = await
engine.isSameTopic
(entityA, entityB);

// Merge sessions
final result = await
engine.mergeSessions
(
sessions
);
```

### Technical Roadmap

Current SLM capabilities use a **pure rule engine + optional cloud enhancement** approach:

- ✅ **Rule Engine**: Local intelligent processing based on keyword matching, BM25-lite similarity, and Jaccard
  coefficient
- ✅ **Fallback Strategy**: Automatically falls back to rule engine when model is unavailable, ensuring uninterrupted
  main workflow
- ❌ **MediaPipe + GGUF**: Deprecated due to compatibility issues
- 🔮 **Future Extensions**: SLM interfaces preserved for future integration with llama.cpp or other edge inference
  frameworks

## 📄 License

This project is licensed under the Apache License 2.0.

View full license: [LICENSE](LICENSE)

