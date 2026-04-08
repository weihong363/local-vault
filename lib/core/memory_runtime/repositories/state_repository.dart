import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';

typedef StateValue = Map<String, dynamic>;
typedef StatePartial = Map<String, dynamic>;

enum StateUpdateKind {
  append,
  overwrite,
  dedup,
  defer,
}

class StateUpdate {
  const StateUpdate._({
    required this.kind,
    required this.key,
    this.value,
    this.partial,
  });

  factory StateUpdate.append(String key, StateValue value) =>
      StateUpdate._(kind: StateUpdateKind.append, key: key, value: value);

  factory StateUpdate.overwrite(String key, StateValue value) =>
      StateUpdate._(kind: StateUpdateKind.overwrite, key: key, value: value);

  factory StateUpdate.dedup(String key, StatePartial partial) =>
      StateUpdate._(kind: StateUpdateKind.dedup, key: key, partial: partial);

  factory StateUpdate.defer(String key) =>
      StateUpdate._(kind: StateUpdateKind.defer, key: key);

  final StateUpdateKind kind;
  final String key;
  final StateValue? value;
  final StatePartial? partial;
}

abstract class StateRepository {
  Future<void> init();

  StateValue? get(String key);

  Future<void> set(String key, StateValue value);

  Future<void> update(String key, StatePartial partial);

  Future<void> delete(String key);

  List<StateRecord> getAllStateRecords();

  Future<void> applyUpdates(List<StateUpdate> updates);

  Future<void> clear();
}
