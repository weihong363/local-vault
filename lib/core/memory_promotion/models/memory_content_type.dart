import '../../utils/memory_multilingual_keywords.dart';

/// Memory Content Type Classification
///
/// Used to determine differentiated policies for promotion/demotion
enum MemoryContentType {
  /// Temporary task (hard to promote, easy to demote)
  temporaryTask,

  /// User preference (easy to promote, hard to demote)
  userPreference,

  /// Project context (easy to promote, only mainline enters core)
  projectContext,

  /// Long-term goal
  longTermGoal,

  /// Core project
  coreProject,

  /// Key constraint (medium, needs confirmation for core promotion)
  keyConstraint,

  /// Identity-level constraint (easier, but needs confirmation)
  identityLevel,

  /// One-time detail (not recommended, will not promote)
  oneTimeDetail;

  /// Automatically infer type from text content
  static MemoryContentType inferFromText(String title, String content) {
    final inferredType = MemoryTypeKeywords.inferType(title, content);

    return switch (inferredType) {
      'temporaryTask' => temporaryTask,
      'identityLevel' => identityLevel,
      'projectContext' => projectContext,
      'userPreference' => userPreference,
      _ => projectContext,
    };
  }
}
