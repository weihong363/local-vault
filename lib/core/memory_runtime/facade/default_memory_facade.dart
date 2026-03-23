import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/memory_runtime/facade/memory_facade.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';

import '../entities/memory_runtime_models.dart';

/// 默认的MemoryFacade实现
///
/// 将统一API调用委托给底层的RuleBasedMemoryCapability
/// 实现了readMemory/writeMemory/compressMemory等方法
class DefaultMemoryFacade implements MemoryFacade {
  final MemoryCapability _memoryCapability;

  DefaultMemoryFacade(this._memoryCapability);

  @override
  Future<MemoryRetrievalResult> readMemory(
    MemoryRetrievalRequest request,
  ) {
    return _memoryCapability.retrieve(request);
  }

  @override
  Future<void> writeMemory(SummaryEntity summary) {
    return _memoryCapability.ingestSession(summary);
  }

  @override
  Future<int> compressMemory() {
    return _memoryCapability.compact();
  }
}
