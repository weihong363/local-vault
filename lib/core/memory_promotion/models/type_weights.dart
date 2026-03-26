import 'memory_content_type.dart';

/// Type Weight Configuration
class TypeWeights {
  const TypeWeights(
    this.promotionSpeed,
    this.demotionThreshold,
  );

  /// Promotion speed coefficient (0.5-2.0)
  /// > 1.0 accelerate, < 1.0 decelerate
  final double promotionSpeed;

  /// Demotion threshold coefficient (0.8-1.5)
  /// > 1.0 harder to demote, < 1.0 easier to demote
  final double demotionThreshold;

  /// Temporary task: hard to promote, easy to demote
  static const temporaryTask = TypeWeights(0.3, 0.5);

  /// User preference: easy to promote, hard to demote
  static const userPreference = TypeWeights(1.2, 1.3);

  /// Project context: easy to promote, only mainline enters core
  static const projectContext = TypeWeights(1.5, 1.0);

  /// Long-term goal: medium-fast
  static const longTermGoal = TypeWeights(1.3, 1.2);

  /// Core project: easy to promote, cautious demotion
  static const coreProject = TypeWeights(1.5, 1.1);

  /// Key constraint: medium, needs confirmation for core promotion
  static const keyConstraint = TypeWeights(1.2, 1.3);

  /// Identity level: medium, extremely hard to demote
  static const identityLevel = TypeWeights(1.0, 1.5);

  /// One-time detail: no promotion, auto-demotion
  static const oneTimeDetail = TypeWeights(0.1, 0.2);

  /// Get weights by content type
  static TypeWeights forType(MemoryContentType type) {
    switch (type) {
      case MemoryContentType.temporaryTask:
        return temporaryTask;
      case MemoryContentType.userPreference:
        return userPreference;
      case MemoryContentType.projectContext:
        return projectContext;
      case MemoryContentType.longTermGoal:
        return longTermGoal;
      case MemoryContentType.coreProject:
        return coreProject;
      case MemoryContentType.keyConstraint:
        return keyConstraint;
      case MemoryContentType.identityLevel:
        return identityLevel;
      case MemoryContentType.oneTimeDetail:
        return oneTimeDetail;
    }
  }
}
