# Memory Promotion and Demotion Mechanism Specification

> This document defines the dynamic flow mechanism between Session, Fact, and Core memory layers in the LocalVault
> memory system.

## 🎯 Core Concepts

**Three-tier Dynamic Flow Mechanism**:

```
session ⇄ fact ⇄ core
   ↑        ↑
   └────────┘ (Can be demoted)
```

**Core Principles**:

- Promotion = Condition satisfaction + No conflict detection
- Demotion = Conservative execution + User priority
- For conflicting memories, prioritize updating state rather than rushing to promote levels

---

## 1️⃣ Session → Fact Promotion Rules

### **Main Rules** (Meet any 1) + **No obvious conflicts**

| No. | Condition                                                | Weight | Detection Method                         | Description                                     |
|-----|----------------------------------------------------------|--------|------------------------------------------|-------------------------------------------------|
| ✅   | **Repeated across 2 sessions**                           | High   | `sessionSpan ≥ 2`                        | Not an accidental mention in a single session   |
| ✅   | **User explicitly asks to remember**                     | High   | `userExplicitSave = true`                | Keywords like "remember this"/"write this down" |
| ✅   | **Subsequently retrieved/referenced**                    | Medium | `accessCount > 0` ∨ `referenceCount > 0` | Proves reuse value                              |
| ✅   | **Clearly belongs to stable preference or project fact** | Medium | `contentType ∈ {preference, project}`    | Based on content classification                 |

### **Precondition: No Conflict Detection**

```dart
bool hasNoConflict() {
  // Check for contradictory information
  if (conflictsWithId != null) return false;

  // Check stability (not significantly modified recently)
  if (stabilityScore < 0.6) return false;

  // Check for newer versions
  if (hasNewerVersion) return false;

  return true;
}
```

### **Scoring Model** (Max 100, ≥70 and no conflict to promote)

```dart
double scoreForSessionToFact() {
  double score = 0;

  // Main rule 1: Repeated across 2 sessions
  if (sessionSpan >= 2) score += 40;

  // Main rule 2: User explicitly asks to remember
  if (userExplicitSave) score += 40;

  // Main rule 3: Subsequently retrieved/referenced
  if (referenceCount > 0 || accessCount > 0) score += 30;

  // Main rule 4: Clearly belongs to stable preference or project fact
  if (contentType == userPreference || contentType == projectContext) score += 30;

  // Type weighting
  score *= typeWeights[contentType].promotionSpeed;

  // Conflict penalty (if conflict, directly zero)
  if (!hasNoConflict()) return 0;

  return score.clamp(0, 100);
}
```

---

## 2️⃣ Fact → Core Promotion Rules

### **Main Rules** (Meet at least 2-3) + **Observation period**

| No. | Condition                                                   | Weight | Detection Method                                                 | Description                         |
|-----|-------------------------------------------------------------|--------|------------------------------------------------------------------|-------------------------------------|
| ✅   | **Consistent across 3+ sessions**                           | High   | `sessionSpan ≥ 3` ∧ `contentHash` stable                         | Long-term consistency verification  |
| ✅   | **Continuously impacts subsequent output**                  | High   | `usageInRecommendations ≥ 5`                                     | Repeatedly used by the system       |
| ✅   | **Belongs to long-term preference/goal/project/constraint** | High   | `contentType ∈ {longTermPreference, coreProject, keyConstraint}` | Content classification + importance |
| ✅   | **User explicitly confirms long-term validity**             | High   | `userConfirmedLongTerm = true`                                   | Explicit marking                    |
| ✅   | **No conflicting updates for a period**                     | Medium | `lastConflictAt == null` ∧ `daysSinceLastUpdate ≥ 30`            | Stability verification              |

### **Observation Period Mechanism**

- **Observation period length**: 30 days
- **Entry condition**: Meet at least 2 main rules and `stabilityScore ≥ 0.8`
- **Promotion condition**: Observation period ends and no new conflicts during period

### **Scoring Model** (Max 100, ≥75 and through observation period to promote)

```dart
double scoreForFactToCore() {
  double score = 0;
  int rulesMet = 0;

  // Main rule 1: Consistent across 3+ sessions
  if (sessionSpan >= 3 && stabilityScore >= 0.8) {
    score += 25;
    rulesMet++;
  }

  // Main rule 2: Continuously impacts subsequent output
  if (hasImpactOnOutput()) {
    score += 25;
    rulesMet++;
  }

  // ... other rules

  // At least 2-3 rules to enter observation period
  if (rulesMet < 2) return 0;

  // Type weighting
  score *= typeWeights[contentType].promotionSpeed;
  
  return score.clamp(0, 100);
}
```

---

## 3️⃣ Demotion Rules (Conservative Execution)

### **Fact → Session or Archive**

**Meet any 2 of the following**:

| Condition                                  | Detection Method                                  | Description                   |
|--------------------------------------------|---------------------------------------------------|-------------------------------|
| ⚠️ **Overridden by new conflicting facts** | `hasNewerFactWithConflict = true`                 | Such as tech stack transition |
| ⚠️ **Long unused and temporary**           | `lastAccessedAt > 60 days` ∧ `isTemporary = true` | Temporary task expiration     |
| ⚠️ **User actively modified or revoked**   | `userModified = true` ∨ `userRevoked = true`      | User action                   |

### **Core → Fact**

**Meet any 2 of the following**:

| Condition                                                                                   | Detection Method            | Description             |
|---------------------------------------------------------------------------------------------|-----------------------------|-------------------------|
| ⚠️ **Originally thought to be long-term rule, later found to be only temporary preference** | `cognitiveReversal = true`  | Cognitive reversal      |
| ⚠️ **Consecutive conflicting information**                                                  | `consecutiveConflicts ≥ 2`  | Multiple contradictions |
| ⚠️ **User explicitly changed their mind**                                                   | `userExplicitChange = true` | User revocation         |

### **Demotion Scoring Model** (Max 100, ≥60 to consider demotion)

```dart
double scoreForDemotion() {
  double score = 0;

  // Demotion condition 1: Overridden by new conflicting facts
  if (hasNewerConflictingFact) score += 50;

  // Demotion condition 2: Long unused and temporary
  if (isLongUnusedAndTemporary()) score += 40;

  // Demotion condition 3: User actively modified or revoked
  if (userModified || userRevoked) score += 60; // User actions have highest weight

  // Core demotion needs to be more conservative
  if (state == MemoryState.core) score *= 0.7; // Reduce by 30%
  
  return score.clamp(0, 100);
}
```

---

## 4️⃣ Memory Content Type Classification

Different types use different promotion/demotion thresholds:

| Type                          | Promote to Fact    | Promote to Core                           | Demotion Strategy  | Example                                  |
|-------------------------------|--------------------|-------------------------------------------|--------------------|------------------------------------------|
| **Temporary Task**            | ❌ Rarely           | ❌ Almost never                            | Fast demotion      | "Buy coffee", "Check express delivery"   |
| **User Preference**           | 🟢 Relatively easy | 🟡 Moderately cautious                    | Slow demotion      | "Like dark mode", "Coffee without sugar" |
| **Project Context**           | 🟢 Easy            | 🟡 Only long-term mainline                | Medium demotion    | "Working on LocalVault project"          |
| **Identity-level Constraint** | 🟡 Medium          | 🟢 Relatively easy but needs confirmation | Very slow demotion | "I am a programmer", "I am in Shanghai"  |
| **One-time Detail**           | ❌ Not recommended  | ❌ Never                                   | Automatic cleanup  | "The weather is nice today"              |

### **Type Weights Table**

```dart

const typeWeights = {
  MemoryContentType.temporaryTask: TypeWeights(0.3, 0.5), // Hard to promote, easy to demote
  MemoryContentType.userPreference: TypeWeights(1.2, 1.3), // Easy to promote, hard to demote
  MemoryContentType.projectContext: TypeWeights(1.5, 1.0), // Easy to promote, only mainline to core
  MemoryContentType.longTermGoal: TypeWeights(1.3, 1.2), // Medium to fast
  MemoryContentType.coreProject: TypeWeights(1.5, 1.1), // Easy to promote, cautious demotion
  MemoryContentType.keyConstraint: TypeWeights(1.2, 1.3), // Medium, core promotion needs confirmation
  MemoryContentType.identityLevel: TypeWeights(1.0, 1.5), // Medium, very hard to demote
  MemoryContentType.oneTimeDetail: TypeWeights(0.1, 0.2), // No promotion, auto demotion
};
```

---

## 5️⃣ Conflict Handling Mechanism

### **Core Principle**

> For conflicting memories, prioritize updating state rather than rushing to promote levels.

### **Conflict Scenario Examples**

```dart
// Example 1: Tech stack transition
Old:
"

I mainly
do

Flutter now
" (2024-01)
New: "

I switched

to React

Native now
"
(2024-
06
)

// Example 2: Residence change
Old: "I live in Shanghai" (2023-01)
New:
"
I moved to Beijing
"
(
2024
-
03
)
```

### **Conflict Handling Strategy**

1. **Preserve timestamps**: Record the replacement relationship between old and new information
2. **Reduce stability score**: `stabilityScore *= 0.7`
3. **Overwrite old state with new information**: Update content, preserve historical versions
4. **Archive old information**: Don't remove, but archive

### **Conflict Resolution Actions**

```dart
enum ResolutionAction {
  UPDATE_AND_ARCHIVE, // Update new, archive old
  MERGE_AND_KEEP_BOTH, // Merge and keep both
  FLAG_FOR_REVIEW, // Flag for user confirmation
}
```

---

## 6️⃣ Complete Flow Chart

```
┌─────────────┐
│  Session    │
└──────┬──────┘
       │
       │ Check promotion conditions (at least 1 + no conflict)
       │ □ Across 2 sessions (+40 points)
       │ □ User asks to remember (+40 points)
       │ □ Retrieved/referenced (+30 points)
       │ □ Stable preference/project (+30 points)
       │
       │ Total score ≥ 70?
       │ And no conflict?
       ▼
┌─────────────┐
│    Fact     │ ← ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
└──────┬──────┘                        │
       │                              │ Demotion (conservative)
       │ Check promotion conditions (2-3 + observation period)  □ New fact conflict
       │ □ Across 3+ sessions (+25 points)       □ Long unused + temporary
       │ □ Impacts output (+25 points)           □ User modified/revoked
       │ □ Long-term type (+25 points)
       │ □ User confirmation (+25 points)
       │ □ No conflict updates (+20 points)
       │
       │ Total score ≥ 75?
       │ And rules ≥ 2?
       │ And observation period ≥ 30 days?
       ▼
┌─────────────┐
│    Core     │
└─────────────┘
```

---

## 7️⃣ Implementation Architecture

### **Package Structure**

```
lib/core/memory_promotion/
├── models/
│   ├── memory_content_type.dart      # Content type enum
│   ├── promotion_score.dart          # Scoring group
│   ├── conflict_resolution.dart      # Conflict resolution
│   └── type_weights.dart             # Type weights
├── services/
│   ├── promotion_scorer.dart         # Scoring engine
│   ├── conflict_detector.dart        # Conflict detection
│   └── promotion_state_machine.dart  # State machine
├── policies/
│   ├── promotion_policy.dart         # Promotion policy configuration
│   └── demotion_policy.dart          # Demotion policy configuration
└── memory_promotion.dart             # Unified export
```

### **Integration with Existing Code**

#### **Existing Code Locations** (Replaced/Enhanced):

1. **`SummaryEntity.shouldUpgradeToCoreWithPolicy()`**
    - Location: `lib/core/domain/entities/summary_entity.dart:146`
    - Status: ✅ **Completed** - Extended to multi-dimensional scoring (using new PromotionScorer)
    - Change: Old logic deleted, fully migrated to new scoring engine

2. **`SummaryUseCases._upgradeFactToCoreIfNeeded()`**
    - Location: `lib/core/domain/usecases/summary_usecases.dart:747`
    - Status: ✅ **Completed** - Using new PromotionScorer
    - Change: Added detailed log output and state field updates

3. **`SummaryUseCases.addSessionMemory()`**
    - Location: `lib/core/domain/usecases/summary_usecases.dart:420`
    - Status: ✅ **Completed** - Added Session → Fact automatic detection
    - Change: Automatically triggers `_upgradeSessionToFactIfNeeded()` after saving

4. **`SummaryUseCases.recordAccess()`** and **`updateImportance()`**
    - Location: `lib/core/domain/usecases/summary_usecases.dart:274, 281`
    - Status: ✅ **Completed** - Trigger promotion detection (Session → Fact → Core)
    - Change: Both methods trigger two-level promotion detection

5. **New: `SummaryEntity.shouldUpgradeToFactWithPolicy()`**
    - Location: `lib/core/domain/entities/summary_entity.dart:179`
    - Status: ✅ **Completed** - Session → Fact judgment method
    - Change: Automatic detection based on multi-dimensional scoring

---

## 8️⃣ Configurable Policies

```dart
class MemoryPromotionPolicy {
  // Session → Fact
  static const sessionToFact = PromotionThreshold(
    minMainRules: 1, // At least 1 main rule
    minScore: 70, // Minimum score
    requireNoConflict: true, // Must have no conflict
  );
  
  // Fact → Core
  static const factToCore = PromotionThreshold(
    minMainRules: 2,
    // At least 2 rules
    minScore: 75,
    // Minimum score
    requireObservation: true,
    // Requires observation period
    observationPeriod: Duration(days: 30),
    requireNoConflict: true, // Must have no conflict
  );

  // Demotion
  static const demotion = DemotionThreshold(
    minReasons: 2, // At least 2 reasons
    minScore: 60, // Minimum score
    requireUserConfirmForCore: true, // Core demotion requires user confirmation
  );
}
```

---

## 9️⃣ Logs and Debugging

### **Expected Log Output**

```dart
// Session → Fact success
I/flutter: ⬆
️
[
Promotion]

Session eligible
for

promotion to
Fact:

GraphRAG Design
I/flutter: ✅
[
Promotion] Promoted: Session →

Fact

// Fact → Core enters observation period
I
/
flutter: ⏳
[
Promotion]

Fact entered

observation period
for
Core:

Flutter Development

Preference
I
/
flutter: 📊
[
Promotion] Score: 78
,
Rules
met: 2
/
2

// Fact → Core promotion success
I/flutter: ✅
[
Promotion]

Fact promoted

to Core
after 30d
observation:

Flutter Development

Preference

// Demotion warning
I
/
flutter: ⚠
️
[
Demotion]

Fact at

risk of
demotion:

Temporary Task

Reminder
I
/
flutter: 📊
[
Demotion] Score: 65
,
Reasons: 2
/
2

// Conflict detection
I/flutter: ⚠
️
[
Conflict]

Detected conflicting
memories:

Tech Stack

Preference
I
/
flutter: 🔧
[
Conflict] Resolution: UPDATE_AND_ARCHIVE
```

---

## 🔟 Unit Test Points

### **Test Coverage**

1. **Scoring accuracy**: Score calculation in various scenarios
2. **Conflict detection**: Identifying contradictory information
3. **Observation period logic**: Time judgment and state flow
4. **Type weights**: Differential handling for different types
5. **Demotion conservatism**: Core demotion requires user confirmation

---

## 📋 Change List

### **New Files**

- ✅ `lib/core/memory_promotion/` (entire package)
    - ✅ `models/memory_content_type.dart` - Content type enum
    - ✅ `models/memory_state.dart` - Memory state enum
    - ✅ `models/type_weights.dart` - Type weight configuration
    - ✅ `services/promotion_scorer.dart` - Scoring engine
    - ✅ `memory_promotion.dart` - Unified export

- ✅ `docs/MEMORY_PROMOTION_MECHANISM.md` (this document)

### **Modified Files**

- ✅ `lib/core/domain/entities/summary_entity.dart`
    - ✅ Added: Promotion-related fields (sessionSpan, userExplicitSave, referenceCount, etc. - 15 fields)
    - ✅ Added: MemoryContentType and MemoryState types
    - ✅ Added: `shouldUpgradeToFactWithPolicy()` method
    - ✅ Extended: `shouldUpgradeToCoreWithPolicy()` using new scoring
    - ✅ Updated: copyWith, toJson, fromJson support new fields

- ✅ `lib/core/domain/usecases/summary_usecases.dart`
    - ✅ Added: `_upgradeSessionToFactIfNeeded()` method
    - ✅ Modified: `recordAccess()` triggers Session → Fact detection
    - ✅ Modified: `updateImportance()` triggers Session → Fact detection
    - ✅ Modified: `addSessionMemory()` adds automatic detection and sessionSpan accumulation
    - ✅ Modified: `_upgradeFactToCoreIfNeeded()` uses new Scorer and adds logs

### **Deleted Files**

- ❌ None (maintain backward compatibility, old logic migrated to memory_promotion package)
- ⚠️ Note: Old simple threshold judgment logic has been replaced by new multi-dimensional scoring mechanism

---

## ✅ Implementation Steps

1. ✅ Create documentation and specifications
2. ✅ Implement `memory_promotion` package
    - ✅ MemoryContentType enum and automatic classification
    - ✅ MemoryState state enum
    - ✅ TypeWeights type weights
    - ✅ PromotionScorer scoring engine
3. ✅ Add new methods in `SummaryEntity`
    - ✅ 15 promotion-related fields
    - ✅ shouldUpgradeToFactWithPolicy() method
    - ✅ Update serialization methods
4. ✅ Integrate new logic in `SummaryUseCases`
    - ✅ _upgradeSessionToFactIfNeeded() method
    - ✅ recordAccess() triggers two-level detection
    - ✅ updateImportance() triggers two-level detection
    - ✅ addSessionMemory() adds sessionSpan accumulation
5. ⏳ Add unit tests
    - ⏳ Session → Fact scenario tests
    - ⏳ Fact → Core scenario tests
    - ⏳ Demotion risk assessment tests
6. ⏳ Real device test verification
    - ⏳ Actual save flow verification
    - ⏳ Log output verification
    - ⏳ Performance impact assessment

---

*Last updated: 2026-03-23*
*Version: v1.0.0*
