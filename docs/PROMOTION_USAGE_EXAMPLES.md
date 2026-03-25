# Memory Promotion Mechanism Usage Examples

---

## 📖 Quick Start

### 1. Basic Usage - No Need to Modify Existing Code

The new promotion mechanism has been integrated into the existing save process, **no need to modify existing calling
code**.

```dart
// The original saving method remains unchanged
await
useCases.addSessionMemory
(
summary); // ✅ Automatically triggers Session → Fact detection
await useCases.recordAccess(id); // ✅ Automatically triggers two-level detection
await useCases.updateImportance(id, 0.8); // ✅ Automatically triggers two-level detection
```

### 2. View Promotion Status

```dart
final summary = useCases.getSummary(id);

// View current state
print
('Type: 
${summary.type}'); // session/fact/core
print('State: ${summary.state}'); // session/fact/core/observing/archived
print('Content Type: ${summary.contentType}'); // Automatic classification result

// View promotion indicators
print('Session Span: ${summary.sessionSpan}'); // Number of cross sessions
print('User Explicit Save: ${summary.userExplicitSave}'); // User explicitly requested
print('Reference Count: ${summary.referenceCount}'); // Number of references
print('Usage in Recommendations: ${
summary
.
usageInRecommendations
}
'
); // Influence
```

---

## 🔍 Promotion Scenarios

### Scenario 1: User Explicitly Asks to Remember

**Input**:

```dart
// User says: "Remember this: I prefer dark mode"
final summary = SummaryEntity(
  id: 'uuid-123',
  title: 'Preference: Dark Mode',
  content: 'I prefer dark mode for all applications',
  tags: ['preference', 'display'],
  userExplicitSave: true,
  // Key flag
  contentType: MemoryContentType.userPreference,
  // ... other fields
);

await
useCases.addSessionMemory
(
summary
);
```

**Expected Behavior**:

- ✅ Automatically detected as Session → Fact promotion candidate
- ✅ Score calculation: 40 (user explicit) + 30 (preference type) = 70 points
- ✅ No conflicts → promotion successful
- ✅ Log: "✅ [Promotion] Promoted: Session → Fact"

### Scenario 2: Memory Referenced Across Sessions

**Input**:

```dart
// First session
final summary1 = SummaryEntity(
  id: 'uuid-456',
  title: 'Project: LocalVault',
  content: 'Working on LocalVault memory app',
  tags: ['project', 'work'],
  contentType: MemoryContentType.projectContext,
  sessionSpan: 1,
  // ... other fields
);
await
useCases.addSessionMemory
(
summary1);

// Second session (later)
final summary2 = SummaryEntity(
id: 'uuid-456', // Same ID
title: 'Project: LocalVault',
content: 'Working on LocalVault memory app (continued)',
tags: ['project', 'work'],
contentType: MemoryContentType.projectContext,
sessionSpan: 2, // Key: cross session
// ... other fields
);
await useCases.updateSummary(summary2);
await useCases.recordAccess
(
'
uuid
-
456
'
);
```

**Expected Behavior**:

- ✅ Automatically detected as Session → Fact promotion candidate
- ✅ Score calculation: 40 (session span) + 30 (project type) = 70 points
- ✅ No conflicts → promotion successful
- ✅ Log: "✅ [Promotion] Promoted: Session → Fact"

### Scenario 3: Fact → Core Promotion

**Input**:

```dart
// Fact memory that's been consistent across sessions
final factSummary = SummaryEntity(
  id: 'uuid-789',
  title: 'Career: Flutter Developer',
  content: 'I work as a Flutter developer',
  tags: ['career', 'skill'],
  contentType: MemoryContentType.identityLevel,
  state: MemoryState.fact,
  sessionSpan: 3,
  // Key: 3+ sessions
  stabilityScore: 0.9,
  // Key: stable
  usageInRecommendations: 5, // Key: impacts output
  // ... other fields
);

await
useCases.updateSummary
(
factSummary);
await useCases.recordAccess('uuid-789');
```

**Expected Behavior**:

- ✅ Automatically detected as Fact → Core promotion candidate
- ✅ Score calculation: 25 (session span) + 25 (impacts output) + 25 (identity type) = 75 points
- ✅ Observation period completed → promotion successful
- ✅ Log: "✅ [Promotion] Fact promoted to Core after 30d observation"

---

## 📊 Scoring Examples

### Example 1: Session → Fact Scoring

| Rule                              | Condition                      | Points                              |
|-----------------------------------|--------------------------------|-------------------------------------|
| Repeated across 2 sessions        | `sessionSpan = 2`              | +40                                 |
| User explicitly asks to remember  | `userExplicitSave = false`     | 0                                   |
| Subsequently retrieved/referenced | `referenceCount = 1`           | +30                                 |
| Stable preference or project fact | `contentType = projectContext` | +30                                 |
| Type weighting                    | `projectContext = 1.5`         | ×1.5                                |
| **Total**                         |                                | **150 × 1.5 = 150 → capped at 100** |

**Result**: ✅ Promoted to Fact

### Example 2: Fact → Core Scoring

| Rule                          | Condition                               | Points                  |
|-------------------------------|-----------------------------------------|-------------------------|
| Consistent across 3+ sessions | `sessionSpan = 3, stabilityScore = 0.9` | +25                     |
| Continuously impacts output   | `usageInRecommendations = 6`            | +25                     |
| Long-term content type        | `contentType = identityLevel`           | +25                     |
| User confirmed long-term      | `userConfirmedLongTerm = true`          | +25                     |
| No conflict updates           | `daysSinceLastUpdate = 45`              | +20                     |
| Type weighting                | `identityLevel = 1.0`                   | ×1.0                    |
| **Total**                     |                                         | **120 → capped at 100** |

**Result**: ✅ Promoted to Core

### Example 3: Conflict Prevention

| Rule                              | Condition                      | Points |
|-----------------------------------|--------------------------------|--------|
| Repeated across 2 sessions        | `sessionSpan = 2`              | +40    |
| User explicitly asks to remember  | `userExplicitSave = true`      | +40    |
| Subsequently retrieved/referenced | `referenceCount = 0`           | 0      |
| Stable preference or project fact | `contentType = userPreference` | +30    |
| Type weighting                    | `userPreference = 1.2`         | ×1.2   |
| Conflict penalty                  | `conflictsWithId != null`      | **0**  |
| **Total**                         |                                | **0**  |

**Result**: ❌ Not promoted (conflict detected)

---

## 🛠️ Advanced Usage

### 1. Manually Trigger Promotion Check

```dart
// Force promotion check for a specific memory
await
useCases.checkPromotionStatus
(
id);

// Check promotion eligibility
final summary = useCases.getSummary(id);
final canPromoteToFact = summary.shouldUpgradeToFactWithPolicy();
final canPromoteToCore = summary.shouldUpgradeToCoreWithPolicy();

print('Can promote to Fact: $canPromoteToFact');
print(
'
Can promote to Core:
$
canPromoteToCore
'
);
```

### 2. Custom Promotion Policy

```dart
// Example: Adjust promotion thresholds
class CustomPromotionPolicy {
  static const sessionToFact = PromotionThreshold(
    minMainRules: 1,
    minScore: 65, // Lower threshold
    requireNoConflict: true,
  );

  static const factToCore = PromotionThreshold(
    minMainRules: 2,
    minScore: 70,
    // Lower threshold
    requireObservation: true,
    observationPeriod: Duration(days: 15),
    // Shorter period
    requireNoConflict: true,
  );
}

// Use custom policy
final scorer = PromotionScorer(policy: CustomPromotionPolicy);
final score = scorer.scoreForSessionToFact(summary);
```

### 3. Monitor Promotion Events

```dart
// Listen for promotion events
useCases.promotionEvents.listen
(
(event) {
switch (event.type) {
case PromotionEventType.promoted:
print('✅ Memory promoted: ${event.memoryId} from ${event.fromState} to ${event.toState}');
break;
case PromotionEventType.demoted:
print('⚠️ Memory demoted: ${event.memoryId} from ${event.fromState} to ${event.toState}');
break;
case PromotionEventType.observation:
print('⏳ Memory entered observation: ${event.memoryId}');
break;
}
});
```

---

## 📈 Performance Tips

### 1. Optimize for Promotion

- **Explicit saves**: Use `userExplicitSave: true` for important information
- **Consistent tagging**: Use consistent tags across sessions
- **Regular access**: Access important memories to increase reference count
- **Clear content**: Write clear, concise memory content

### 2. Avoid Unnecessary Promotions

- **Temporary tasks**: Mark as `temporaryTask` content type
- **One-time details**: Let them auto-cleanup
- **Conflicting information**: Resolve conflicts before promotion

---

## 🔧 Troubleshooting

### Common Issues

| Issue                        | Cause                     | Solution                                                     |
|------------------------------|---------------------------|--------------------------------------------------------------|
| Memory not promoting to Fact | Low score or conflict     | Check session span, user explicit save, or resolve conflicts |
| Memory not promoting to Core | Short observation period  | Wait for 30 days or check stability score                    |
| Promotion score too low      | Insufficient criteria     | Increase session span or reference count                     |
| Conflict detected            | Contradictory information | Resolve conflict or archive old memory                       |

### Debug Commands

```dart
// Check promotion score
final scorer = PromotionScorer();
final factScore = scorer.scoreForSessionToFact(summary);
final coreScore = scorer.scoreForFactToCore(summary);
print
('Fact score: $factScore, Core score: $coreScore');

// Check conflict status
final hasConflict = !summary.hasNoConflict();
print('Has conflict: $hasConflict');

// Check observation period
final inObservation = summary.state == MemoryState.observing;
print('In observation: 
$
inObservation
'
);
```

---

## 🎯 Best Practices

### 1. Content Organization

- **Use clear titles**: Help with automatic classification
- **Consistent tagging**: Improve cross-session detection
- **Separate concerns**: One memory per topic
- **Update existing memories**: Instead of creating new ones

### 2. User Intent Signaling

- **Explicit saves**: Use "remember this" keywords
- **Regular access**: Revisit important memories
- **Feedback loop**: Provide feedback on promotion decisions
- **Manual adjustments**: Use UI controls to adjust promotion status

### 3. System Integration

- **Batch operations**: Group memory updates
- **Background processing**: Use isolates for heavy promotion checks
- **Caching**: Cache promotion scores for frequently accessed memories
- **Logging**: Monitor promotion events for system health

---

## 📋 Use Case Examples

### Example 1: Project Management

**Scenario**: Tracking project information across multiple sessions

```dart
// First session
await
useCases.addSessionMemory
(
SummaryEntity(
title: 'Project: LocalVault',
content: 'Starting LocalVault memory app project',
tags: ['project', 'Flutter'],
contentType: MemoryContentType.projectContext,
userExplicitSave: true,
));

// Second session (next day)
await useCases.addSessionMemory(SummaryEntity(
title: 'Project: LocalVault',
content: 'Implemented memory storage with Hive',
tags: ['project', 'Flutter', 'Hive'],
contentType: MemoryContentType.projectContext,
userExplicitSave: true,
));

// Third session (next week)
await useCases.addSessionMemory(SummaryEntity(
title: 'Project: LocalVault',
content: 'Added memory promotion mechanism',
tags: ['project', 'Flutter', 'promotion'],
contentType: MemoryContentType.projectContext,
userExplicitSave: true,
)
);
```

**Expected Behavior**:

- After 2 sessions: Promoted to Fact
- After 3 sessions + observation: Promoted to Core
- Core memory retained for long-term project tracking

### Example 2: Personal Preferences

**Scenario**: Storing personal preferences that should be retained

```dart
await
useCases.addSessionMemory
(
SummaryEntity(
title: 'Preference: Coffee',
content: 'I prefer black coffee without sugar',
tags: ['preference', 'food'],
contentType: MemoryContentType.userPreference,
userExplicitSave: true,
));

// Later access
await useCases.recordAccess(id);
await useCases.recordAccess(
id
); // Multiple accesses
```

**Expected Behavior**:

- User explicit save + preference type → promoted to Fact
- Multiple accesses → increases reference count
- Stable preference → may promote to Core after observation

---

## ✅ Conclusion

The memory promotion mechanism provides an intelligent way to manage memory importance without manual intervention. By
following the examples and best practices outlined in this document, you can ensure that your important memories are
properly retained while temporary information is automatically cleaned up.

Key takeaways:

- **No code changes needed** for basic usage
- **Automatic promotion** based on usage patterns
- **Conflict detection** prevents incorrect information from being promoted
- **Observation period** ensures long-term stability for Core memories
- **Type-specific strategies** handle different types of information appropriately

The system is designed to be intuitive and low-maintenance, allowing users to focus on creating and using memories
without worrying about manual organization.

---

*Last updated: 2026-03-23*
*Version: v1.0.0*
