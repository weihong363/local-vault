import 'package:local_vault/core/domain/entities/summary_entity.dart';

import '../entities/memory_runtime_models.dart';

/// 统一的内存操作门面
///
/// 提供简化的API表面，封装底层复杂的记忆运行时逻辑
/// 作为系统其他部分与记忆系统交互的唯一官方接口
abstract class MemoryFacade {
  /// 读取记忆数据
  Future<MemoryRetrievalResult> readMemory(MemoryRetrievalRequest request);

  /// 写入会话记忆
  Future<void> writeMemory(SummaryEntity summary);

  /// 压缩和整理记忆
  Future<int> compressMemory();
}
