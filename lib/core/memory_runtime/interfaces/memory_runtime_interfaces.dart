import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';

/// 记忆合并策略
enum MemoryMergeStrategy {
  /// 保留旧版本（左边的内容）
  keepOld,

  /// 保留新版本（右边的内容）
  keepNew,

  /// 智能合并（压缩两边内容）
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

  /// 压缩两条记忆的内容（用于预览）
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
