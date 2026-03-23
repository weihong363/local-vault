/// 记忆晋升元数据 - 用于存储记忆晋升相关的辅助信息
///
/// 💡 **设计目的**：
/// - 将晋升相关的动态指标与核心业务数据 (SummaryEntity) 分离
/// - 支持独立的版本迭代，避免影响已有记忆数据
/// - 减少主 Box 的数据量，提升查询性能
class MemoryPromotionMetadata {
  /// 关联的 SummaryEntity.id
  final String summaryId;

  /// 关联的 SummaryEntity.title（方便查看）
  final String summaryTitle;

  /// 跨越的 session 数量（用于 Session → Fact 判断）
  final int sessionSpan;

  /// 用户明确要求记住（关键词触发）
  final bool userExplicitSave;

  /// 被引用次数（用于复用价值判断）
  final int referenceCount;

  /// 稳定性分数 (0-1)
  final double stabilityScore;

  /// 内容哈希（用于检测一致性）
  final String? contentHash;

  /// 版本数量
  final int versionCount;

  /// 最后冲突时间
  final DateTime? lastConflictAt;

  /// 观察期开始时间（Fact → Core 用）
  final DateTime? observationStartedAt;

  /// 用户确认长期有效
  final bool userConfirmedLongTerm;

  /// 用户修改过
  final bool userModified;

  /// 用户撤销
  final bool userRevoked;

  /// 在推荐中使用次数（影响力指标）
  final int usageInRecommendations;

  MemoryPromotionMetadata({
    required this.summaryId,
    required this.summaryTitle,
    this.sessionSpan = 0,
    this.userExplicitSave = false,
    this.referenceCount = 0,
    this.stabilityScore = 1.0,
    this.contentHash,
    this.versionCount = 1,
    this.lastConflictAt,
    this.observationStartedAt,
    this.userConfirmedLongTerm = false,
    this.userModified = false,
    this.userRevoked = false,
    this.usageInRecommendations = 0,
  });

  /// 复制并修改
  MemoryPromotionMetadata copyWith({
    String? summaryId,
    String? summaryTitle,
    int? sessionSpan,
    bool? userExplicitSave,
    int? referenceCount,
    double? stabilityScore,
    String? contentHash,
    int? versionCount,
    DateTime? lastConflictAt,
    DateTime? observationStartedAt,
    bool? userConfirmedLongTerm,
    bool? userModified,
    bool? userRevoked,
    int? usageInRecommendations,
  }) {
    return MemoryPromotionMetadata(
      summaryId: summaryId ?? this.summaryId,
      summaryTitle: summaryTitle ?? this.summaryTitle,
      sessionSpan: sessionSpan ?? this.sessionSpan,
      userExplicitSave: userExplicitSave ?? this.userExplicitSave,
      referenceCount: referenceCount ?? this.referenceCount,
      stabilityScore: stabilityScore ?? this.stabilityScore,
      contentHash: contentHash ?? this.contentHash,
      versionCount: versionCount ?? this.versionCount,
      lastConflictAt: lastConflictAt ?? this.lastConflictAt,
      observationStartedAt: observationStartedAt ?? this.observationStartedAt,
      userConfirmedLongTerm:
          userConfirmedLongTerm ?? this.userConfirmedLongTerm,
      userModified: userModified ?? this.userModified,
      userRevoked: userRevoked ?? this.userRevoked,
      usageInRecommendations:
          usageInRecommendations ?? this.usageInRecommendations,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'summaryId': summaryId,
      'summaryTitle': summaryTitle,
      'sessionSpan': sessionSpan,
      'userExplicitSave': userExplicitSave,
      'referenceCount': referenceCount,
      'stabilityScore': stabilityScore,
      'contentHash': contentHash,
      'versionCount': versionCount,
      'lastConflictAt': lastConflictAt?.toIso8601String(),
      'observationStartedAt': observationStartedAt?.toIso8601String(),
      'userConfirmedLongTerm': userConfirmedLongTerm,
      'userModified': userModified,
      'userRevoked': userRevoked,
      'usageInRecommendations': usageInRecommendations,
    };
  }

  /// 从 JSON 解析
  factory MemoryPromotionMetadata.fromJson(Map<String, dynamic> json) {
    return MemoryPromotionMetadata(
      summaryId: json['summaryId'] as String,
      summaryTitle: json['summaryTitle'] as String? ?? '',
      sessionSpan: switch (json['sessionSpan']) {
        int value => value,
        double value => value.toInt(),
        _ => 0,
      },
      userExplicitSave: json['userExplicitSave'] as bool? ?? false,
      referenceCount: switch (json['referenceCount']) {
        int value => value,
        double value => value.toInt(),
        _ => 0,
      },
      stabilityScore: switch (json['stabilityScore']) {
        int value => value.toDouble(),
        double value => value,
        _ => 1.0,
      },
      contentHash: json['contentHash'] as String?,
      versionCount: switch (json['versionCount']) {
        int value => value,
        double value => value.toInt(),
        _ => 1,
      },
      lastConflictAt: json['lastConflictAt'] != null
          ? DateTime.parse(json['lastConflictAt'] as String)
          : null,
      observationStartedAt: json['observationStartedAt'] != null
          ? DateTime.parse(json['observationStartedAt'] as String)
          : null,
      userConfirmedLongTerm: json['userConfirmedLongTerm'] as bool? ?? false,
      userModified: json['userModified'] as bool? ?? false,
      userRevoked: json['userRevoked'] as bool? ?? false,
      usageInRecommendations: switch (json['usageInRecommendations']) {
        int value => value,
        double value => value.toInt(),
        _ => 0,
      },
    );
  }

  @override
  String toString() {
    return 'MemoryPromotionMetadata(id=$summaryId, title=$summaryTitle, '
        'sessionSpan=$sessionSpan, userExplicitSave=$userExplicitSave, '
        'referenceCount=$referenceCount, stabilityScore=$stabilityScore, '
        'usageInRecommendations=$usageInRecommendations)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemoryPromotionMetadata &&
        other.summaryId == summaryId &&
        other.summaryTitle == summaryTitle &&
        other.sessionSpan == sessionSpan &&
        other.userExplicitSave == userExplicitSave &&
        other.referenceCount == referenceCount &&
        other.stabilityScore == stabilityScore &&
        other.contentHash == contentHash &&
        other.versionCount == versionCount &&
        other.lastConflictAt == lastConflictAt &&
        other.observationStartedAt == observationStartedAt &&
        other.userConfirmedLongTerm == userConfirmedLongTerm &&
        other.userModified == userModified &&
        other.userRevoked == userRevoked &&
        other.usageInRecommendations == usageInRecommendations;
  }

  @override
  int get hashCode {
    return Object.hash(
      summaryId,
      summaryTitle,
      sessionSpan,
      userExplicitSave,
      referenceCount,
      stabilityScore,
      contentHash,
      versionCount,
      lastConflictAt,
      observationStartedAt,
      userConfirmedLongTerm,
      userModified,
      userRevoked,
      usageInRecommendations,
    );
  }
}
