import 'package:local_vault/core/domain/entities/summary_entity.dart';

import '../entities/memory_runtime_models.dart';

/// A unified facade for memory operations
///
/// Provides a simplified API surface, encapsulating the complex underlying memory runtime logic
/// Serves as the sole official interface for interaction between other parts of the system and the memory system
abstract class MemoryFacade {
  Future<MemoryRetrievalResult> readMemory(MemoryRetrievalRequest request);

  Future<void> writeMemory(SummaryEntity summary);

  Future<int> compressMemory();
}
