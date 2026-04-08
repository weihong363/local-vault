import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/memory_runtime/facade/memory_facade.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';
import 'package:local_vault/core/memory_runtime/services/write_memory_pipeline.dart';

import '../entities/memory_runtime_models.dart';

/// Default MemoryFacade implementation
///
/// Delegates unified API calls to the underlying RuleBasedMemoryCapability
/// Implements methods such as readMemory/writeMemory/compressMemory
class DefaultMemoryFacade implements MemoryFacade {
  final MemoryCapability _memoryCapability;
  final MemoryWritePipeline _writePipeline;

  DefaultMemoryFacade(
    this._memoryCapability, {
    MemoryWritePipeline? writePipeline,
  }) : _writePipeline = writePipeline ?? MemoryWritePipeline();

  @override
  Future<MemoryRetrievalResult> readMemory(
    MemoryRetrievalRequest request,
  ) {
    return _memoryCapability.retrieve(request);
  }

  @override
  Future<WriteMemoryResult> writeMemory(WriteMemoryInput input) async {
    final result = _writePipeline.run(input);

    if (input.forwardToLegacyIngest && input.legacySummary != null) {
      await _memoryCapability.ingestSession(input.legacySummary!);
    }

    return result;
  }

  @override
  Future<WriteMemoryResult> writeSummaryMemory(SummaryEntity summary) {
    return writeMemory(WriteMemoryInput.fromSummaryEntity(summary));
  }

  @override
  Future<int> compressMemory() {
    return _memoryCapability.compact();
  }
}
