import 'package:local_vault/core/domain/entities/summary_entity.dart';

import '../entities/memory_runtime_models.dart';

/// Memory Routing Controller
///
/// Responsible for routing memory operations to the appropriate processing path based on context and policy
/// Supports intelligent routing decisions based on rules, model availability, and performance
abstract class MemoryRouter {
  Future<MemoryRetrievalResult> routeRead(MemoryRetrievalRequest request);

  Future<void> routeWrite(SummaryEntity summary);

  Future<int> routeCompact();
}
