import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';

/// memory merging strategy
enum MemoryMergeStrategy {
  /// Keep the old version (the content on the left).
  keepOld,

  /// Keep the new version (the content on the right).
  keepNew,

  /// Intelligent merging (compressing content from both sides)
  smartMerge,
}

abstract class MemoryCapability {
  Future<void> ingestSession(SummaryEntity summary);

  Future<MemoryRetrievalResult> retrieve(MemoryRetrievalRequest request);

  Future<MemoryContextBundle> buildContext(MemoryRetrievalRequest request);

  Future<int> compact();

  Future<MemoryRuntimeDiagnostics> diagnose();
}

abstract class MemoryIngestor {
  Future<void> ingestSession(SummaryEntity summary);
}

abstract class MemoryCompressor {
  Future<SessionCompactionResult> compressSessions(
      List<SummaryEntity> sessions);
}

abstract class MemoryMerger {
  bool shouldMerge(MemoryUnit left, MemoryUnit right);

  Future<MemoryUnit> mergeUnits(
    MemoryUnit left,
    MemoryUnit right, {
    MemoryMergeStrategy strategy = MemoryMergeStrategy.smartMerge,
  });

  /// Compress the contents of the two memories (for preview).
  String compressSummaryForMerge(String content1, String content2);
}

abstract class MemoryRetriever {
  Future<MemoryRetrievalResult> retrieve(MemoryRetrievalRequest request);
}

abstract class ContextAssembler {
  MemoryContextBundle assemble(MemoryRetrievalResult result);
}

abstract class MemoryWorker {
  Future<void> enqueue(MemoryCompressionJob job);

  List<MemoryCompressionJob> takePendingJobs();

  void beginProcessing();

  void completeProcessing({String? errorMessage});

  MemoryRuntimeDiagnostics snapshot({
    int stateRecordCount = 0,
    int memoryUnitCount = 0,
    int archiveRecordCount = 0,
  });
}

abstract class MemoryPolicy {
  int get maxContextItems;

  int get preferredStateItems;

  int get maxKeywordsPerRecord;

  int get maxCompressedSummaryChars;

  int get maxCompressedClauses;

  int get archiveRetentionLimit;

  double get memoryUnitMergeThreshold;

  double get stateConfidenceThreshold;
}

abstract class ModelRuntimeProvider {
  Future<bool> isAvailable();

  Future<String> resolveVersion();
}
