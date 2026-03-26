/// Memory State Enum
///
/// Used to track memory state during promotion/demotion workflow
enum MemoryState {
  /// Session memory (temporary)
  session,

  /// Fact memory (persistent)
  fact,

  /// Core memory (long-term stable)
  core,

  /// Observing (waiting for promotion to core)
  observing,

  /// Archived (no longer active)
  archived,
}

extension MemoryStateX on MemoryState {
  bool get isTemporary => this == MemoryState.session;

  bool get isPersistent => this == MemoryState.fact || this == MemoryState.core;

  bool get isCore => this == MemoryState.core;

  bool get isObserving => this == MemoryState.observing;
}
