import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';

class DefaultMemoryPolicy implements MemoryPolicy {
  const DefaultMemoryPolicy({
    this.maxContextItemsValue = 5,
    this.preferredStateItemsValue = 2,
    this.maxKeywordsPerRecordValue = 8,
    this.maxCompressedSummaryCharsValue = 160,
    this.maxCompressedClausesValue = 4,
    this.archiveRetentionLimitValue = 200,
    this.memoryUnitMergeThresholdValue = 0.76,
    this.stateConfidenceThresholdValue = 0.55,
  });

  final int maxContextItemsValue;
  final int preferredStateItemsValue;
  final int maxKeywordsPerRecordValue;
  final int maxCompressedSummaryCharsValue;
  final int maxCompressedClausesValue;
  final int archiveRetentionLimitValue;
  final double memoryUnitMergeThresholdValue;
  final double stateConfidenceThresholdValue;

  @override
  int get archiveRetentionLimit => archiveRetentionLimitValue;

  @override
  int get maxCompressedClauses => maxCompressedClausesValue;

  @override
  int get maxCompressedSummaryChars => maxCompressedSummaryCharsValue;

  @override
  int get maxContextItems => maxContextItemsValue;

  @override
  int get maxKeywordsPerRecord => maxKeywordsPerRecordValue;

  @override
  double get memoryUnitMergeThreshold => memoryUnitMergeThresholdValue;

  @override
  int get preferredStateItems => preferredStateItemsValue;

  @override
  double get stateConfidenceThreshold => stateConfidenceThresholdValue;
}
