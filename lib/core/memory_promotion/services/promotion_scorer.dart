import 'package:flutter/foundation.dart';
import '../models/memory_content_type.dart';
import '../models/type_weights.dart';

/// 记忆晋升计分引擎
class PromotionScorer {
  /// Session → Fact 计分（满分 100，≥70 且无冲突可晋升）
  static double scoreForSessionToFact({
    required int sessionSpan,
    required bool userExplicitSave,
    required int referenceCount,
    required int accessCount,
    required MemoryContentType contentType,
    required bool hasConflict,
  }) {
    double score = 0;

    // 主规则 1：跨 2 个 session 重复出现
    if (sessionSpan >= 2) {
      score += 40; // 高权重
      debugPrint('📊 [Scorer] sessionSpan >= 2: +40');
    }

    // 主规则 2：用户明确要求记住
    if (userExplicitSave) {
      score += 40; // 高权重
      debugPrint('📊 [Scorer] userExplicitSave: +40');
    }

    // 主规则 3：后续检索/引用过
    if (referenceCount > 0 || accessCount > 0) {
      score += 30; // 中权重
      debugPrint('📊 [Scorer] referenceCount/accessCount > 0: +30');
    }

    // 主规则 4：明显属于稳定偏好或项目事实
    if (contentType == MemoryContentType.userPreference ||
        contentType == MemoryContentType.projectContext) {
      score += 30; // 中权重
      debugPrint('📊 [Scorer] stable type: +30');
    }

    // 类型加权
    final weights = TypeWeights.forType(contentType);
    score *= weights.promotionSpeed;
    debugPrint(
        '📊 [Scorer] After type weight (${weights.promotionSpeed}): $score');

    // 冲突惩罚（如果有冲突，直接归零）
    if (hasConflict) {
      debugPrint('📊 [Scorer] Has conflict, score set to 0');
      return 0;
    }

    final finalScore = (score.clamp(0, 100)).toDouble();
    debugPrint('📊 [Scorer] Final score: $finalScore');
    return finalScore;
  }

  /// Fact → Core 计分（满分 100，≥75 且通过观察期可晋升）
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

    // 主规则 1：跨 3+ 个 session 保持一致
    if (sessionSpan >= 3 && stabilityScore >= 0.8) {
      score += 25;
      rulesMet++;
      debugPrint('📊 [Scorer] sessionSpan >= 3 && stability >= 0.8: +25');
    }

    // 主规则 2：对后续输出持续有影响
    if (hasImpactOnOutput || usageInRecommendations >= 5) {
      score += 25;
      rulesMet++;
      debugPrint('📊 [Scorer] has impact on output: +25');
    }

    // 主规则 3：属于长期偏好/目标/项目/约束
    if (_isLongTermType(contentType)) {
      score += 25;
      rulesMet++;
      debugPrint('📊 [Scorer] long term type: +25');
    }

    // 主规则 4：用户明确确认长期有效
    if (userConfirmedLongTerm) {
      score += 25;
      rulesMet++;
      debugPrint('📊 [Scorer] user confirmed long term: +25');
    }

    // 主规则 5：一段时间内没有冲突更新
    if (!hasRecentConflict) {
      score += 20;
      rulesMet++;
      debugPrint('📊 [Scorer] no recent conflict: +20');
    }

    // 至少满足 2-3 条才能进入观察期
    if (rulesMet < 2) {
      debugPrint('📊 [Scorer] Rules met ($rulesMet) < 2, score set to 0');
      return 0;
    }

    // 类型加权
    final weights = TypeWeights.forType(contentType);
    score *= weights.promotionSpeed;
    debugPrint(
        '📊 [Scorer] After type weight (${weights.promotionSpeed}): $score');

    final finalScore = (score.clamp(0, 100)).toDouble();
    debugPrint('📊 [Scorer] Final score: $finalScore, rules met: $rulesMet');
    return finalScore;
  }

  /// 降级风险评估（满分 100，≥60 考虑降级）
  static double scoreForDemotion({
    required bool hasNewerConflictingFact,
    required bool isLongUnusedAndTemporary,
    required bool userModified,
    required bool userRevoked,
    required bool isCore,
  }) {
    double score = 0;

    // 降级条件 1：被新事实冲突覆盖
    if (hasNewerConflictingFact) {
      score += 50;
      debugPrint('📊 [Scorer] has newer conflicting fact: +50');
    }

    // 降级条件 2：长时间未使用且是阶段性
    if (isLongUnusedAndTemporary) {
      score += 40;
      debugPrint('📊 [Scorer] long unused and temporary: +40');
    }

    // 降级条件 3：用户主动修改或撤销
    if (userModified || userRevoked) {
      score += 60; // 用户行为权重最高
      debugPrint('📊 [Scorer] user modified/revoked: +60');
    }

    // Core 降级需要更保守
    if (isCore) {
      score *= 0.7; // 降低 30%
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
