import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';

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

  Future<MemoryUnit> mergeUnits(MemoryUnit left, MemoryUnit right);
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
