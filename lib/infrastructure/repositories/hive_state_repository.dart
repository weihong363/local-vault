import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/core/constants/app_storage.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/core/memory_runtime/repositories/state_repository.dart';

class HiveStateRepository implements StateRepository {
  Box? _box;
  final StateRecordStorageAdapter _adapter;

  HiveStateRepository({StateRecordStorageAdapter? adapter})
      : _adapter = adapter ?? const StateRecordStorageAdapter();

  @override
  Future<void> init() async {
    _box ??= await _openBox(AppStorage.memoryStateBoxName);
  }

  Future<Box> _openBox(String name) async {
    try {
      debugPrint('🔄 [HiveStateRepository] Opening Hive box: $name');
      return await Hive.openBox(name);
    } catch (error) {
      debugPrint('⚠️ [HiveStateRepository] Failed to open $name, recreating: $error');
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox(name);
    }
  }

  Box get _states {
    assert(_box != null, 'Repository not initialized. Call init() first.');
    return _box!;
  }

  @override
  StateValue? get(String key) {
    final data = _states.get(key);
    if (data == null) {
      return null;
    }
    return _adapter.decodeToValue(data);
  }

  @override
  Future<void> set(String key, StateValue value) {
    return _states.put(key, value);
  }

  @override
  Future<void> update(String key, StatePartial partial) async {
    final current = get(key);
    if (current == null) {
      return;
    }
    final merged = <String, dynamic>{...current, ...partial};
    await _states.put(key, merged);
  }

  @override
  Future<void> delete(String key) {
    return _states.delete(key);
  }

  List<StateRecord> getAllStateRecords() {
    final records = _states.values.map(_adapter.decodeToRecord).toList();
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return records;
  }

  @override
  Future<void> applyUpdates(List<StateUpdate> updates) async {
    for (final update in updates) {
      switch (update.kind) {
        case StateUpdateKind.append:
        case StateUpdateKind.overwrite:
          final value = update.value;
          if (value == null) {
            continue;
          }
          await set(update.key, value);
          break;
        case StateUpdateKind.dedup:
          final partial = update.partial;
          if (partial == null || partial.isEmpty) {
            continue;
          }
          await updateIfChanged(update.key, partial);
          break;
        case StateUpdateKind.defer:
          break;
      }
    }
  }

  Future<void> updateIfChanged(String key, StatePartial partial) async {
    final current = get(key);
    if (current == null) {
      return;
    }

    var changed = false;
    for (final entry in partial.entries) {
      if (current[entry.key] != entry.value) {
        changed = true;
        break;
      }
    }

    if (!changed) {
      return;
    }

    await update(key, partial);
  }

  @override
  Future<void> clear() async {
    await _states.clear();
  }
}

class StateRecordStorageAdapter {
  const StateRecordStorageAdapter();

  StateRecord decodeToRecord(dynamic data) =>
      StateRecord.fromJson(decodeToValue(data));

  StateValue decodeToValue(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is List<int>) {
      return StateRecord.fromBinary(data).toJson();
    }
    throw ArgumentError('Cannot convert to StateValue: $data');
  }
}
