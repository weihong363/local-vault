import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';
import 'package:local_vault/core/memory_runtime/router/memory_router.dart';
import 'package:local_vault/core/memory_runtime/services/write_memory_pipeline.dart';

import '../entities/memory_runtime_models.dart';

/// Default MemoryRouter implementation
///
/// Delegates routing requests to the underlying memory capability implementation
/// Can select different processing paths based on runtime conditions and strategies
class DefaultMemoryRouter implements MemoryRouter {
  final MemoryCapability _memoryCapability;
  final MemoryWritePipeline _writePipeline;

  DefaultMemoryRouter(
    this._memoryCapability, {
    MemoryWritePipeline? writePipeline,
  }) : _writePipeline = writePipeline ?? MemoryWritePipeline();

  @override
  Future<MemoryRetrievalResult> routeRead(
    MemoryRetrievalRequest request,
  ) async {
    return _memoryCapability.retrieve(request);
  }

  @override
  Future<WriteMemoryResult> routeWrite(WriteMemoryInput input) async {
    final result = _writePipeline.run(input);
    if (input.forwardToLegacyIngest && input.legacySummary != null) {
      await _memoryCapability.ingestSession(input.legacySummary!);
    }
    return result;
  }

  @override
  Future<WriteMemoryResult> routeWriteSummary(SummaryEntity summary) {
    return routeWrite(WriteMemoryInput.fromSummaryEntity(summary));
  }

  @override
  Future<int> routeCompact() async {
    return _memoryCapability.compact();
  }
}
