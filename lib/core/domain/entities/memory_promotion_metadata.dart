/// Memory Promotion Metadata - used for storing auxiliary information related to memory promotion
///
/// 💡 **Design Purpose**:
/// - Separate promotion-related dynamic metrics from core business data (SummaryEntity)
/// - Support independent version iteration without affecting existing memory data
/// - Reduce main Box data volume and improve query performance
class MemoryPromotionMetadata {
  /// Associated SummaryEntity.id
  final String summaryId;

  /// Associated SummaryEntity.title (for easy viewing)
  final String summaryTitle;

  /// Number of sessions spanned (for Session → Fact determination)
  final int sessionSpan;

  /// User explicitly requested save (keyword trigger)
  final bool userExplicitSave;

  /// Number of references (for reuse value determination)
  final int referenceCount;

  /// Stability score (0-1)
  final double stabilityScore;

  /// Content hash (for consistency detection)
  final String? contentHash;

  /// Number of versions
  final int versionCount;

  /// Last conflict time
  final DateTime? lastConflictAt;

  /// Observation period start time (for Fact → Core)
  final DateTime? observationStartedAt;

  /// User confirmed long-term validity
  final bool userConfirmedLongTerm;

  /// User modified
  final bool userModified;

  /// User revoked
  final bool userRevoked;

  /// Usage count in recommendations (influence metric)
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

  /// Copy and modify
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

  /// Convert to JSON
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

  /// Parse from JSON
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
