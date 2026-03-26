import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';
import 'package:local_vault/core/memory_runtime/router/memory_router.dart';

import '../entities/memory_runtime_models.dart';

/// Default MemoryRouter implementation
///
/// Delegates routing requests to the underlying memory capability implementation
/// Can select different processing paths based on runtime conditions and strategies
class DefaultMemoryRouter implements MemoryRouter {
  final MemoryCapability _memoryCapability;

  DefaultMemoryRouter(this._memoryCapability);

  @override
  Future<MemoryRetrievalResult> routeRead(
    MemoryRetrievalRequest request,
  ) async {
    return _memoryCapability.retrieve(request);
  }

  @override
  Future<void> routeWrite(SummaryEntity summary) async {
    await _memoryCapability.ingestSession(summary);
  }

  @override
  Future<int> routeCompact() async {
    return _memoryCapability.compact();
  }
}
