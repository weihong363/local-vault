/// 记忆状态枚举
///
/// 用于追踪记忆在晋升/降级流程中的状态
enum MemoryState {
  /// 会话记忆（临时）
  session,

  /// 事实记忆（持久化）
  fact,

  /// 核心记忆（长期稳定）
  core,

  /// 观察期（等待晋升为核心）
  observing,

  /// 已归档（不再活跃）
  archived,
}

extension MemoryStateX on MemoryState {
  bool get isTemporary => this == MemoryState.session;

  bool get isPersistent => this == MemoryState.fact || this == MemoryState.core;

  bool get isCore => this == MemoryState.core;

  bool get isObserving => this == MemoryState.observing;
}
