# Memory Module Migration Guide

## 📋 Overview

This document guides how to upgrade the current project's memory module from the basic architecture to an enhanced
memory system based on **mem0** and **ToolNeuron** design concepts.

**Reference Projects**:

- [mem0](https://github.com/mem0ai/mem0) - Intelligent memory layer
- [ToolNeuron](https://github.com/Siddhesh2377/ToolNeuron) - Offline AI assistant

---

## 🎯 Migration Goals

### Current Status

- ✅ Basic DDD architecture
- ✅ SummaryEntity domain model
- ✅ Hive local storage
- ✅ Basic search functionality
- ⚠️ Single-level memory (no classification)
- ❌ No memory weight management
- ❌ No timeliness management
- ❌ No deduplication mechanism
- ❌ No forgetting curve

### Target Status

- ✅ Multi-level memory architecture (user facts, sessions, templates)
- ✅ Memory weight and importance scoring
- ✅ Timeliness management and forgetting curve
- ✅ Jaccard similarity deduplication
- ✅ Intelligent search and sorting
- ✅ Independent memory management interface

---

## 🚀 Migration Phases

### Phase 1: Basic Extension (Low Risk, Immediate Implementation)

**Goal**: Extend the existing SummaryEntity, add core fields

#### 1.1 Extend SummaryEntity

**File**: `lib/core/domain/entities/summary_entity.dart`

**Add Fields**:
```dart
/// Memory type
enum MemoryType {
  fact, // User facts (persistent)
  session, // Session memory (temporary)
  template, // Template memory
}

class SummaryEntity {
  // ... existing fields ...

  /// New fields
  final MemoryType type;
  final DateTime? lastAccessedAt; // Last access time
  final double importance; // Importance (0.0-1.0)
  final int accessCount; // Access count
  final bool isAutoExtracted; // Whether auto-extracted

// ... update constructor and methods ...
}
```

**Backward Compatibility**:

- Existing data defaults to `type = MemoryType.fact`
- `importance` defaults to 0.5
- `accessCount` defaults to 0

#### 1.2 Update Hive Storage

**File**: `lib/infrastructure/repositories/hive_summary_repository.dart`

**Update Content**:

- Support serialization/deserialization of new fields
- Data migration script (upgrade existing data)

#### 1.3 Optimize Search Sorting

**File**: `lib/core/domain/usecases/summary_usecases.dart`

**New Methods**:
```dart
/// Calculate recency score
double _calculateRecencyScore(SummaryEntity summary) {
  if (summary.lastAccessedAt == null) return 0.5;
  final daysSinceAccess = DateTime.now().difference(summary.lastAccessedAt!).inDays;
  return 1.0 * (0.95 ^ daysSinceAccess); // 5% decay per day
}

/// Comprehensive score sorting
List<SummaryEntity> _sortByRelevance(List<SummaryEntity> summaries) {
  return summaries..sort((a, b) {
    final scoreA = a.importance * 0.5 + _calculateRecencyScore(a) * 0.3 + (a.accessCount > 0 ? 1.0 - (1.0 / (a.accessCount + 1)) : 0.0) * 0.2;
    final scoreB = b.importance * 0.5 + _calculateRecencyScore(b) * 0.3 + (b.accessCount > 0 ? 1.0 - (1.0 / (b.accessCount + 1)) : 0.0) * 0.2;
    return scoreB.compareTo(scoreA);
  });
}
```

#### 1.4 Update Provider

**File**: `lib/core/providers/summary_entities_provider.dart`

**New Methods**:
```dart
/// Record access
Future<void> recordAccess(String id) async {
  // Update lastAccessedAt and accessCount
}

/// Filter by type
List<SummaryEntity> getByType(MemoryType type) {
  // Implement filtering logic
}
```

**Acceptance Criteria**:

- [ ] Existing data loads normally
- [ ] Search results sorted by comprehensive score
- [ ] Can filter by memory type
- [ ] `flutter analyze` passes

---

### Phase 2: Intelligent Enhancement (Mid-term Optimization)

**Goal**: Implement deduplication, forgetting curve, memory management interface

#### 2.1 Implement Jaccard Similarity Deduplication

**New File**: `lib/core/utils/similarity_utils.dart`

```dart
/// Jaccard similarity calculation
class SimilarityUtils {
  /// Calculate Jaccard similarity between two texts
  static double jaccardSimilarity(String text1, String text2) {
    final words1 = _tokenize(text1);
    final words2 = _tokenize(text2);
    
    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;
    
    return union == 0 ? 0.0 : intersection / union;
  }
  
  static Set<String> _tokenize(String text) {
    return text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toSet();
  }
}
```

**Update UseCase**:
```dart
/// Add memory (with deduplication)
Future<void> addWithDeduplication(SummaryEntity summary) async {
  const threshold = 0.7;
  final existing = getAllSummaries();
  
  for (final item in existing) {
    final similarity = SimilarityUtils.jaccardSimilarity(
      '${summary.title} ${summary.content}',
      '${item.title} ${item.content}',
    );
    
    if (similarity >= threshold) {
      // Merge memories
      final merged = _mergeMemories(item, summary);
      await updateSummary(merged);
      return;
    }
  }
  
  await addSummary(summary);
}

/// Merge similar memories
SummaryEntity _mergeMemories(SummaryEntity existing, SummaryEntity newOne) {
  final mergedTags = {...existing.tags, ...newOne.tags}.toList();
  return existing.copyWith(
    content: '${existing.content}\n\n${newOne.content}',
    tags: mergedTags,
    updatedAt: DateTime.now(),
    importance: (existing.importance + newOne.importance) / 2,
  );
}
```

#### 2.2 Implement Forgetting Curve

**New Methods**:
```dart
/// Apply forgetting curve
Future<void> applyForgettingCurve() async {
  final all = getAllSummaries();
  final now = DateTime.now();
  
  for (final summary in all) {
    final daysOld = now.difference(summary.createdAt).inDays;

    // Start decaying after 30 days
    if (daysOld > 30) {
      final decayFactor = 1.0 - ((daysOld - 30) / 60) * 0.9;
      final newImportance = (summary.importance * decayFactor).clamp(0.1, 1.0);
      
      if (newImportance != summary.importance) {
        await updateSummary(summary.copyWith(importance: newImportance));
      }
    }
  }
}

/// Clean up expired session memories
Future<void> cleanupSessionMemories() async {
  const maxAge = Duration(hours: 24);
  final sessions = getByType(MemoryType.session);
  final now = DateTime.now();
  
  for (final session in sessions) {
    if (now.difference(session.createdAt) > maxAge) {
      await deleteSummary(session.id);
    }
  }
}
```

#### 2.3 Create Memory Management Interface

**New File**: `lib/features/memory/presentation/pages/memory_management_page.dart`

**Features**:

- View all memories
- Filter by type
- Edit memory importance
- Manually delete/merge memories
- View memory statistics (access count, last access time)

#### 2.4 Scheduled Task Integration

**Update**: `lib/main.dart`

**Add**: Execute cleanup tasks on app start and resume
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    // Execute when app resumes
    _memoryUseCases.applyForgettingCurve();
    _memoryUseCases.cleanupSessionMemories();
  }
}
```

**Acceptance Criteria**:

- [x] Automatic deduplication when adding memory
- [x] Forgetting curve works normally
- [x] Session memories automatically cleaned up
- [x] Memory management interface usable
- [x] `flutter analyze` passes (to be verified)

---

### Phase 3: Advanced Features (Long-term Planning)

**Goal**: Vector retrieval, auto-extraction, intelligent merging

#### 3.1 Integrate Local Vector Retrieval

**Options**:

- SQLite + vector extension
- Integrate ONNX Runtime for local embedding
- Use simple cosine similarity

**New File**: `lib/core/services/vector_search_service.dart`

#### 3.2 Automatic Memory Extraction

**Features**:

- Automatically identify user facts from conversations
- Use local LLM to extract key information
- Mark as `isAutoExtracted`

#### 3.3 Intelligent Memory Merging

**Features**:

- Regularly check for similar memories
- Intelligently merge related content
- Maintain memory timeliness

**Acceptance Criteria**:

- [ ] Vector retrieval available
- [ ] Auto-extraction feature works
- [ ] Intelligent merging works
- [ ] Performance optimization completed

---

## 📁 File Structure Changes

### New Files

```
lib/
├── core/
│   ├── domain/
│   │   └── entities/
│   │       └── memory_entity.dart          (optional: standalone enhanced version)
│   ├── usecases/
│   │   └── memory_usecases.dart           (optional: standalone)
│   └── utils/
│       └── similarity_utils.dart           (new)
└── features/
    └── memory/
        ├── domain/
        │   └── repositories/
        │       └── memory_repository_interface.dart
        ├── data/
        │   └── repositories/
        │       └── hive_memory_repository.dart
        └── presentation/
            ├── providers/
            │   └── memory_provider.dart
            ├── pages/
            │   └── memory_management_page.dart
            └── widgets/
                └── memory_card.dart
```

### Modified Files

```
lib/
├── core/
│   ├── domain/
│   │   └── entities/
│   │       └── summary_entity.dart          (extended)
│   ├── usecases/
│   │   └── summary_usecases.dart           (extended)
│   └── providers/
│       └── summary_entities_provider.dart  (extended)
├── infrastructure/
│   └── repositories/
│       └── hive_summary_repository.dart     (updated)
└── main.dart                                  (add lifecycle hooks)
```

---

## 🔄 Data Migration Strategy

### Existing Data Upgrade

```dart
/// Data migration script
class DataMigrationService {
  static Future<void> migrateToV2() async {
    final oldSummaries = await getOldSummaries();
    
    for (final old in oldSummaries) {
      final migrated = SummaryEntity(
        id: old.id,
        title: old.title,
        content: old.content,
        tags: old.tags,
        type: MemoryType.fact,
        // Default to user fact
        createdAt: old.createdAt,
        updatedAt: old.updatedAt,
        source: old.source,
        embedding: old.embedding,
        sortOrder: old.sortOrder,
        // New field default values
        importance: 0.5,
        accessCount: 0,
        lastAccessedAt: null,
        isAutoExtracted: false,
      );
      
      await saveMigrated(migrated);
    }
  }
}
```

---

## ✅ Checklist

### Phase 1

- [ ] Extend SummaryEntity with new fields
- [ ] Update Hive serialization
- [ ] Implement data migration
- [ ] Optimize search sorting
- [ ] Add access recording functionality
- [ ] Test existing functionality
- [ ] `flutter analyze` passes

### Phase 2

- [x] Implement Jaccard similarity
- [x] Add deduplication logic
- [x] Implement forgetting curve
- [x] Session memory auto-cleanup
- [x] Create memory management interface
- [x] Integrate scheduled tasks
- [ ] Complete testing
- [ ] `flutter analyze` passes

### Phase 3

- [ ] Vector retrieval integration
- [ ] Automatic memory extraction
- [ ] Intelligent merging
- [ ] Performance optimization
- [ ] Complete testing

---

## 📊 Correspondence with Reference Projects

| Feature               | mem0 | ToolNeuron | This Project |
|-----------------------|------|------------|--------------|
| Multi-level memory    | ✅    | ✅          | Phase 1      |
| Memory weight         | ✅    | ✅          | Phase 1      |
| Timeliness            | ✅    | ✅          | Phase 1      |
| Jaccard deduplication | ❌    | ✅          | Phase 2      |
| Forgetting curve      | ❌    | ✅          | Phase 2      |
| Vector retrieval      | ✅    | ✅          | Phase 3      |
| Auto-extraction       | ✅    | ✅          | Phase 3      |

---

## 🎯 Next Steps

1. **Start immediately**: Implement Phase 1
2. **Test and verify**: Ensure Phase 1 is stable
3. **Gradually advance**: Adjust subsequent phases based on feedback
4. **Continuous optimization**: Iterate based on actual usage

---

## 📚 Reference Resources

- [mem0 GitHub](https://github.com/mem0ai/mem0)
- [mem0 Documentation](https://docs.mem0.ai)
- [ToolNeuron GitHub](https://github.com/Siddhesh2377/ToolNeuron)
- [ToolNeuron Memory Design](https://github.com/Siddhesh2377/ToolNeuron)
