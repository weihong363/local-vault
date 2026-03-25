import 'package:local_vault/core/domain/entities/summary_entity.dart';

import '../entities/memory_runtime_models.dart';

/// 记忆路由控制器
///
/// 负责根据上下文和策略将记忆操作路由到适当的处理路径
/// 支持基于规则、模型可用性和性能的智能路由决策
abstract class MemoryRouter {
  /// 路由读取请求
  Future<MemoryRetrievalResult> routeRead(MemoryRetrievalRequest request);

  /// 路由写入操作
  Future<void> routeWrite(SummaryEntity summary);

  /// 路由压缩操作
  Future<int> routeCompact();
}
