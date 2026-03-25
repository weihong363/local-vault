import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';
import 'package:local_vault/core/memory_runtime/router/memory_router.dart';

import '../entities/memory_runtime_models.dart';

/// 默认的MemoryRouter实现
///
/// 将路由请求委托给底层的记忆能力实现
/// 可以根据运行时条件和策略选择不同的处理路径
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
