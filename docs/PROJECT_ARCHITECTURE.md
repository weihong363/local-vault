# Local Vault Project Architecture Diagram

> Update time: 2026-03-18  
> This document is organized based on the actual code structure of the current local workspace, reflecting the latest
> memory module extraction, SLM configuration externalization, gesture diagnosis, backup import, and database query
> capabilities.

---

## Project Positioning

Local Vault is currently positioned as a 100% local, offline-first memory bank application, not a general chat shell.

Current first-level modules:

- Home
- Templates
- Memory
- Settings

Among them, "Memory Management" has been extracted from the settings page to become a first-level module in the bottom
navigation.

---

## Core Architecture Diagram

```
┌───────────────────────────────────────────────────────────────────┐
│                             APP                                 │
├───────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  │    Home     │  │  Templates  │  │   Memory   │  │  Settings   │
│  └─────┬───────┘  └─────┬───────┘  └─────┬───────┘  └─────┬───────┘
│        │                │                │                │
│        ▼                ▼                ▼                ▼
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  │ Home Logic  │  │  Template   │  │  Memory    │  │  Settings   │
│  │ & UI        │  │  Management │  │  Management │  │  Management │
│  └─────┬───────┘  └─────┬───────┘  └─────┬───────┘  └─────┬───────┘
│        │                │                │                │
│        └────────────────┼────────────────┼────────────────┘
│                         │                │
│                         ▼                ▼
│                  ┌─────────────┐  ┌─────────────┐
│                  │  Use Cases  │  │   SLM      │
│                  │  (Domain)   │  │  Service   │
│                  └─────┬───────┘  └─────┬───────┘
│                        │                │
│                        ▼                │
│                 ┌─────────────┐         │
│                 │ Repositories│         │
│                 │ (Data)      │◄────────┘
│                 └─────┬───────┘
│                       │
│                       ▼
│                ┌─────────────┐
│                │   Storage   │
│                │  (Hive)     │
│                └─────────────┘
│                                                                 │
└───────────────────────────────────────────────────────────────────┘
```

---

## Layered Architecture

### 1. Presentation Layer (UI)

**Responsibilities**:

- User interface rendering
- User interaction handling
- Navigation and routing
- State management (Riverpod)

**Key Files**:

```
lib/features/
├── home/presentation/
│   ├── home_screen.dart
│   └── home_controller.dart
├── memory/presentation/
│   ├── memory_list_screen.dart
│   ├── memory_detail_screen.dart
│   └── memory_controller.dart
├── templates/presentation/
│   ├── template_list_screen.dart
│   ├── template_detail_screen.dart
│   └── template_controller.dart
└── settings/presentation/
    ├── settings_screen.dart
    └── settings_controller.dart
```

### 2. Application/Services Layer

**Responsibilities**:

- Business logic orchestration
- Use case implementation
- Service coordination
- Transaction management

**Key Files**:

```
lib/core/domain/usecases/
├── summary_usecases.dart          # Memory-related use cases
├── template_usecases.dart         # Template-related use cases
└── backup_usecases.dart           # Backup-related use cases

lib/core/domain/services/
├── memory_slm_service.dart        # SLM service
├── topic_extractor.dart           # Topic extraction service
└── memory_merger.dart             # Memory merging service
```

### 3. Domain Layer

**Responsibilities**:

- Core business rules
- Entity definitions
- Value objects
- Domain services

**Key Files**:

```
lib/core/domain/entities/
├── summary_entity.dart            # Memory summary entity
├── template_entity.dart           # Template entity
└── backup_entity.dart             # Backup entity

lib/core/domain/value_objects/
├── memory_content_type.dart       # Memory content type
└── memory_state.dart              # Memory state
```

### 4. Data Layer (Infrastructure)

**Responsibilities**:

- Data persistence
- External service integration
- Repository pattern implementation
- Data access optimization

**Key Files**:

```
lib/core/data/repositories/
├── summary_repository.dart        # Memory repository
├── template_repository.dart       # Template repository
└── backup_repository.dart         # Backup repository

lib/core/data/datasources/
├── local/hive_datasource.dart     # Hive local storage
└── remote/api_datasource.dart     # API datasource (future)
```

---

## Core Modules

### 1. Memory Management Module

**Key Components**:

- **Memory List**: Paginated display, search, filter
- **Memory Detail**: View, edit, tag, share
- **Memory Promotion**: Three-tier promotion mechanism
- **Memory Merging**: Smart merging of similar memories
- **Memory Search**: Full-text and similarity search (in progress)

**Key Files**:

```
lib/features/memory/
├── presentation/
│   ├── memory_list_screen.dart
│   ├── memory_detail_screen.dart
│   └── memory_controller.dart
├── domain/
│   ├── entities/memory_entity.dart
│   └── usecases/memory_usecases.dart
└── data/
    ├── repositories/memory_repository.dart
    └── datasources/memory_datasource.dart
```

### 2. Template Management Module

**Key Components**:

- **Template List**: Categorized display, quick use
- **Template Editor**: Create and edit templates
- **Template Usage**: Apply templates to memories

**Key Files**:

```
lib/features/templates/
├── presentation/
│   ├── template_list_screen.dart
│   ├── template_detail_screen.dart
│   └── template_controller.dart
├── domain/
│   ├── entities/template_entity.dart
│   └── usecases/template_usecases.dart
└── data/
    ├── repositories/template_repository.dart
    └── datasources/template_datasource.dart
```

### 3. SLM Integration Module

**Key Components**:

- **MemorySLMService**: SLM service implementation
- **External Configuration**: Strategies and prompts in JSON
- **Fallback Mechanism**: Automatically fallback to rules

**Key Files**:

```
lib/core/domain/services/
├── memory_slm_service.dart        # SLM service
└── slm_strategy.dart              # SLM strategy

assets/configs/
└── slm_strategies.json            # SLM configuration
```

### 4. Backup & Restore Module

**Key Components**:

- **Export**: Export memories to JSON
- **Import**: Import memories from JSON
- **Multi-platform Support**: Cross-device compatibility

**Key Files**:

```
lib/features/settings/
├── presentation/
│   └── backup_screen.dart
├── domain/
│   └── usecases/backup_usecases.dart
└── data/
    ├── repositories/backup_repository.dart
    └── datasources/backup_datasource.dart
```

---

## Navigation Architecture

### Bottom Navigation

| Tab       | Route        | Screen               | Description                     |
|-----------|--------------|----------------------|---------------------------------|
| Home      | `/`          | `HomeScreen`         | Main dashboard, recent memories |
| Templates | `/templates` | `TemplateListScreen` | Template management             |
| Memory    | `/memory`    | `MemoryListScreen`   | Memory management               |
| Settings  | `/settings`  | `SettingsScreen`     | App settings                    |

### Nested Routes

```
/
├── templates
│   ├── create
│   └── detail/:id
├── memory
│   ├── create
│   ├── detail/:id
│   └── search
└── settings
    ├── backup
    ├── storage
    └── about
```

**Key Files**:

```
lib/core/presentation/
├── app_router.dart                # Navigation routes
└── app.dart                       # App entry point
```

---

## State Management

### Riverpod Providers

| Provider                     | Type                    | Purpose               |
|------------------------------|-------------------------|-----------------------|
| `summaryRepositoryProvider`  | `Provider`              | Memory repository     |
| `templateRepositoryProvider` | `Provider`              | Template repository   |
| `backupRepositoryProvider`   | `Provider`              | Backup repository     |
| `summaryUseCasesProvider`    | `Provider`              | Memory use cases      |
| `templateUseCasesProvider`   | `Provider`              | Template use cases    |
| `backupUseCasesProvider`     | `Provider`              | Backup use cases      |
| `memorySLMServiceProvider`   | `Provider`              | SLM service           |
| `memoryControllerProvider`   | `StateNotifierProvider` | Memory screen state   |
| `templateControllerProvider` | `StateNotifierProvider` | Template screen state |
| `settingsControllerProvider` | `StateNotifierProvider` | Settings screen state |

**Key Files**:

```
lib/core/presentation/providers/
├── repository_providers.dart      # Repository providers
├── usecase_providers.dart         # Use case providers
├── service_providers.dart         # Service providers
└── controller_providers.dart      # Controller providers
```

---

## Data Storage

### Hive Boxes

| Box Name         | Purpose          | Key Type        | Value Type       |
|------------------|------------------|-----------------|------------------|
| `summaries`      | Memory storage   | `String` (UUID) | `SummaryEntity`  |
| `templates`      | Template storage | `String` (UUID) | `TemplateEntity` |
| `settings`       | App settings     | `String`        | `dynamic`        |
| `backupMetadata` | Backup metadata  | `String`        | `BackupMetadata` |

### Data Models

**SummaryEntity**:

```dart
class SummaryEntity {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final MemoryContentType contentType;
  final MemoryState state;
  final double importance;
  final int sessionSpan;
  final bool userExplicitSave;
  final int accessCount;
  final int referenceCount;
  final int usageInRecommendations;
  final double stabilityScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAccessedAt;
  final String? conflictsWithId;
  final bool hasNewerVersion;

// ... methods
}
```

**TemplateEntity**:

```dart
class TemplateEntity {
  final String id;
  final String name;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

// ... methods
}
```

---

## SLM Integration Architecture

### Core Flow

```
┌─────────────┐
│  User Input │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ MemorySLM   │
│ Service     │
└──────┬──────┘
       │
       ▼
┌─────────────┐     No     ┌─────────────┐
│ Model       │──────────►│ Rule Engine │
│ Available?  │            └──────┬──────┘
└──────┬──────┘                  │
       │ Yes                     │
       ▼                         │
┌─────────────┐                  │
│ SLM         │                  │
│ Processing  │◄─────────────────┘
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Result      │
│ Processing  │
└─────────────┘
```

### External Configuration

**`slm_strategies.json`**:

```json
{
  "strategies": {
    "topic_extraction": {
      "prompt": "Extract a concise topic from this content: {content}",
      "max_length": 50
    },
    "memory_merging": {
      "prompt": "Merge these two memories into one coherent memory: {memory1}\n{memory2}",
      "max_length": 500
    },
    "title_generation": {
      "prompt": "Generate a concise title for this memory: {content}",
      "max_length": 100
    }
  }
}
```

---

## Performance Optimization

### Key Strategies

1. **Lazy Loading**: Only load data when needed
2. **Isolates**: Use isolates for heavy processing
3. **Caching**: Cache frequently accessed data
4. **Batch Operations**: Group database operations
5. **Pagination**: Limit data retrieval

### Memory Management

- **Memory Pooling**: Reuse memory objects
- **Garbage Collection**: Properly dispose resources
- **Memory Limits**: Enforce memory usage limits

---

## Security Considerations

### Data Protection

- **Local Storage**: Encrypt sensitive data
- **Backup**: Encrypt backup files
- **No Network**: No unintended network requests
- **Data Minimization**: Only store necessary data

### Code Security

- **Input Validation**: Validate all user inputs
- **Error Handling**: Proper error handling
- **Logging**: No sensitive data in logs
- **Dependency Security**: Regular dependency updates

---

## Cross-Platform Support

### Target Platforms

- **Android**: API 21+
- **iOS**: iOS 13+
- **Web**: Chrome, Safari, Firefox
- **Desktop**: Windows, macOS, Linux (future)

### Platform-Specific Considerations

| Platform | Considerations              | Mitigation                           |
|----------|-----------------------------|--------------------------------------|
| Android  | Varying device capabilities | Feature gating, adaptive layouts     |
| iOS      | Stricter memory limits      | More aggressive memory management    |
| Web      | Limited local storage       | IndexedDB, cloud sync option         |
| Desktop  | Larger screen sizes         | Adaptive layouts, keyboard shortcuts |

---

## Development Workflow

### Git Branch Strategy

- **main**: Production-ready code
- **develop**: Development branch
- **feature/**: Feature branches
- **bugfix/**: Bug fix branches

### CI/CD Pipeline

1. **Code Linting**: `flutter analyze`
2. **Tests**: `flutter test`
3. **Build**: `flutter build`
4. **Deployment**: App Store, Play Store

---

## Future Architecture Enhancements

### Planned Improvements

1. **Cloud Sync**: Optional encrypted cloud backup
2. **Advanced Search**: Vector similarity search
3. **Voice Integration**: Voice commands and dictation
4. **Gesture Control**: Custom gestures for quick actions
5. **Plugin System**: Extensible architecture

### Technical Debt

| Item                  | Impact | Plan                |
|-----------------------|--------|---------------------|
| **Memory Search**     | Medium | Implement in v1.1.0 |
| **UI Tests**          | Low    | Add in v1.2.0       |
| **Performance Tests** | Medium | Add in v1.1.0       |

---

*Last updated: 2026-03-18*
*Version: v1.0.0*
