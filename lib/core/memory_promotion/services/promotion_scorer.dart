import 'package:flutter/foundation.dart';

import '../models/memory_content_type.dart';
import '../models/type_weights.dart';

/// Memory Promotion Scoring Engine
class PromotionScorer {
  /// Session → Fact scoring (max 100, ≥70 and no conflict can promote)
  static double scoreForSessionToFact({
    required int sessionSpan,
    required bool userExplicitSave,
    required int referenceCount,
    required int accessCount,
    required MemoryContentType contentType,
    required bool hasConflict,
  }) {
    double score = 0;

    // Main Rule 1: Appears repeatedly across 2+ sessions
    if (sessionSpan >= 2) {
      score += 40; // High weight
      debugPrint('📊 [Scorer] sessionSpan >= 2: +40');
    }

    // Main Rule 2: User explicitly requested to remember
    if (userExplicitSave) {
      score += 40; // High weight
      debugPrint('📊 [Scorer] userExplicitSave: +40');
    }

    // Main Rule 3: Referenced/accessed subsequently
    if (referenceCount > 0 || accessCount > 0) {
      score += 30; // Medium weight
      debugPrint('📊 [Scorer] referenceCount/accessCount > 0: +30');
    }

    // Main Rule 4: Clearly belongs to stable preference or project fact
    if (contentType == MemoryContentType.userPreference ||
        contentType == MemoryContentType.projectContext) {
      score += 30; // Medium weight
      debugPrint('📊 [Scorer] stable type: +30');
    }

    // Type weighting
    final weights = TypeWeights.forType(contentType);
    score *= weights.promotionSpeed;
    debugPrint(
        '📊 [Scorer] After type weight (${weights.promotionSpeed}): $score');

    // Conflict penalty (if has conflict, set to zero directly)
    if (hasConflict) {
      debugPrint('📊 [Scorer] Has conflict, score set to 0');
      return 0;
    }

    final finalScore = (score.clamp(0, 100)).toDouble();
    debugPrint('📊 [Scorer] Final score: $finalScore');
    return finalScore;
  }

  /// Fact → Core scoring (max 100, ≥75 and passed observation period can promote)
  static double scoreForFactToCore({
    required int sessionSpan,
    required double stabilityScore,
    required bool hasImpactOnOutput,
    required MemoryContentType contentType,
    required bool userConfirmedLongTerm,
    required bool hasRecentConflict,
    required int usageInRecommendations,
  }) {
    double score = 0;
    int rulesMet = 0;

    // Main Rule 1: Consistent across 3+ sessions
    if (sessionSpan >= 3 && stabilityScore >= 0.8) {
      score += 25;
      rulesMet++;
      debugPrint('📊 [Scorer] sessionSpan >= 3 && stability >= 0.8: +25');
    }

    // Main Rule 2: Continues to have impact on output
    if (hasImpactOnOutput || usageInRecommendations >= 5) {
      score += 25;
      rulesMet++;
      debugPrint('📊 [Scorer] has impact on output: +25');
    }

    // Main Rule 3: Belongs to long-term preference/goal/project/constraint
    if (_isLongTermType(contentType)) {
      score += 25;
      rulesMet++;
      debugPrint('📊 [Scorer] long term type: +25');
    }

    // Main Rule 4: User explicitly confirmed long-term validity
    if (userConfirmedLongTerm) {
      score += 25;
      rulesMet++;
      debugPrint('📊 [Scorer] user confirmed long term: +25');
    }

    // Main Rule 5: No conflicting updates for a period
    if (!hasRecentConflict) {
      score += 20;
      rulesMet++;
      debugPrint('📊 [Scorer] no recent conflict: +20');
    }

    // Must meet at least 2-3 rules to enter observation period
    if (rulesMet < 2) {
      debugPrint('📊 [Scorer] Rules met ($rulesMet) < 2, score set to 0');
      return 0;
    }

    // Type weighting
    final weights = TypeWeights.forType(contentType);
    score *= weights.promotionSpeed;
    debugPrint(
        '📊 [Scorer] After type weight (${weights.promotionSpeed}): $score');

    final finalScore = (score.clamp(0, 100)).toDouble();
    debugPrint('📊 [Scorer] Final score: $finalScore, rules met: $rulesMet');
    return finalScore;
  }

  /// Demotion risk assessment (max 100, ≥60 consider demotion)
  static double scoreForDemotion({
    required bool hasNewerConflictingFact,
    required bool isLongUnusedAndTemporary,
    required bool userModified,
    required bool userRevoked,
    required bool isCore,
  }) {
    double score = 0;

    // Demotion condition 1: Overridden by newer conflicting fact
    if (hasNewerConflictingFact) {
      score += 50;
      debugPrint('📊 [Scorer] has newer conflicting fact: +50');
    }

    // Demotion condition 2: Long unused and temporary
    if (isLongUnusedAndTemporary) {
      score += 40;
      debugPrint('📊 [Scorer] long unused and temporary: +40');
    }

    // Demotion condition 3: User actively modified or revoked
    if (userModified || userRevoked) {
      score += 60; // User behavior weight is highest
      debugPrint('📊 [Scorer] user modified/revoked: +60');
    }

    // Core demotion needs to be more conservative
    if (isCore) {
      score *= 0.7; // Reduce by 30%
      debugPrint('📊 [Scorer] is core, multiply by 0.7: $score');
    }

    final finalScore = (score.clamp(0, 100)).toDouble();
    debugPrint('📊 [Scorer] Final demotion score: $finalScore');
    return finalScore;
  }

  static bool _isLongTermType(MemoryContentType type) {
    return type == MemoryContentType.longTermGoal ||
        type == MemoryContentType.coreProject ||
        type == MemoryContentType.keyConstraint ||
        type == MemoryContentType.identityLevel;
  }
}
