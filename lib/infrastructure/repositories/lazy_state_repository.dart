import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/core/constants/app_storage.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/core/memory_runtime/repositories/memory_sidecar_repository.dart';

/// 惰性加载的 Repository，优化内存占用
class LazyStateRepository implements MemorySidecarRepository {
  Box? _stateBox;
  Box? _unitBox;
  Box? _archiveBox;

  @override
  Future<void> init() async {
    _stateBox ??= await _openBox(AppStorage.memoryStateBoxName);
    _unitBox ??= await _openBox(AppStorage.memoryUnitBoxName);
    _archiveBox ??= await _openBox(AppStorage.memoryArchiveBoxName);
  }

  Future<Box> _openBox(String name) async {
    try {
      debugPrint('🔄 [LazyStateRepository] Opening Hive box: $name');
      return await Hive.openBox(name);
    } catch (error) {
      debugPrint(
        '⚠️ [LazyStateRepository] Failed to open $name, recreating: $error',
      );
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox(name);
    }
  }

  Box get _states {
    assert(_stateBox != null, 'Repository not initialized. Call init() first.');
    return _stateBox!;
  }

  Box get _units {
    assert(_unitBox != null, 'Repository not initialized. Call init() first.');
    return _unitBox!;
  }

  Box get _archives {
    assert(
      _archiveBox != null,
      'Repository not initialized. Call init() first.',
    );
    return _archiveBox!;
  }

  StateRecord _parseRecord(dynamic data) {
    if (data is List<int>) {
      return StateRecord.fromBinary(data);
    }
    final map = _safeCastMap(data);
    return StateRecord.fromJson(map);
  }

  MemoryUnit _parseUnit(dynamic data) {
    if (data is List<int>) {
      return MemoryUnit.fromBinary(data);
    }
    final map = _safeCastMap(data);
    return MemoryUnit.fromJson(map);
  }

  Map<String, dynamic> _safeCastMap(dynamic map) {
    if (map is Map<String, dynamic>) {
      return map;
    }
    if (map is Map) {
      return Map<String, dynamic>.from(map);
    }
    throw ArgumentError('Cannot convert to Map<String, dynamic>: $map');
  }

  /// 流式读取所有记录（惰性加载）
  Stream<StateRecord> streamAllStates() async* {
    for (final key in _states.keys) {
      final data = _states.get(key);
      if (data != null) {
        yield _parseRecord(data);
      }
    }
  }

  /// 流式读取所有 MemoryUnits
  Stream<MemoryUnit> streamAllUnits() async* {
    for (final key in _units.keys) {
      final data = _units.get(key);
      if (data != null) {
        yield _parseUnit(data);
      }
    }
  }

  /// 分页读取 StateRecords
  Future<List<StateRecord>> getStatePage({
    int page = 0,
    int pageSize = 20,
    String? namespace,
    String? topic,
    Comparator<StateRecord>? comparator,
  }) async {
    var records = <StateRecord>[];
    final skipCount = page * pageSize;
    var takenCount = 0;
    var skippedCount = 0;

    for (final key in _states.keys) {
      final data = _states.get(key);
      if (data == null) continue;

      final record = _parseRecord(data);

      // 过滤
      if (namespace != null && record.namespace != namespace) {
        continue;
      }
      if (topic != null && record.topic != topic) {
        continue;
      }

      // 跳过前面的记录
      if (skippedCount < skipCount) {
        skippedCount++;
        continue;
      }

      records.add(record);
      takenCount++;

      if (takenCount >= pageSize) {
        break;
      }
    }

    // 排序
    if (comparator != null) {
      records.sort(comparator);
    } else {
      records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    return records;
  }

  /// 分页读取 MemoryUnits
  Future<List<MemoryUnit>> getUnitsPage({
    int page = 0,
    int pageSize = 20,
    String? topic,
    Comparator<MemoryUnit>? comparator,
  }) async {
    var units = <MemoryUnit>[];
    final skipCount = page * pageSize;
    var takenCount = 0;
    var skippedCount = 0;

    for (final key in _units.keys) {
      final data = _units.get(key);
      if (data == null) continue;

      final unit = _parseUnit(data);

      // 过滤
      if (topic != null && unit.topic != topic) {
        continue;
      }

      // 跳过前面的记录
      if (skippedCount < skipCount) {
        skippedCount++;
        continue;
      }

      units.add(unit);
      takenCount++;

      if (takenCount >= pageSize) {
        break;
      }
    }

    // 排序
    if (comparator != null) {
      units.sort(comparator);
    } else {
      units.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    return units;
  }

  /// 惰性过滤查询（返回匹配的第一个结果）
  Future<StateRecord?> findFirst({
    String? namespace,
    String? topic,
    bool Function(StateRecord)? predicate,
  }) async {
    for (final key in _states.keys) {
      final data = _states.get(key);
      if (data == null) continue;

      final record = _parseRecord(data);

      // 基础过滤
      if (namespace != null && record.namespace != namespace) {
        continue;
      }
      if (topic != null && record.topic != topic) {
        continue;
      }

      // 自定义谓词过滤
      if (predicate != null && !predicate(record)) {
        continue;
      }

      return record;
    }

    return null;
  }

  /// 惰性计数（不加载所有数据）
  Future<int> countStates({
    String? namespace,
    String? topic,
  }) async {
    var count = 0;

    for (final key in _states.keys) {
      final data = _states.get(key);
      if (data == null) continue;

      final record = _parseRecord(data);

      if (namespace != null && record.namespace != namespace) {
        continue;
      }
      if (topic != null && record.topic != topic) {
        continue;
      }

      count++;
    }

    return count;
  }

  /// 惰性聚合（例如计算总 importance）
  Future<T?> aggregateStates<T>({
    required T Function(T accumulator, StateRecord record) aggregator,
    required T initialValue,
    String? namespace,
    String? topic,
  }) async {
    var accumulator = initialValue;

    for (final key in _states.keys) {
      final data = _states.get(key);
      if (data == null) continue;

      final record = _parseRecord(data);

      if (namespace != null && record.namespace != namespace) {
        continue;
      }
      if (topic != null && record.topic != topic) {
        continue;
      }

      accumulator = aggregator(accumulator, record);
    }

    return accumulator;
  }

  List<StateRecord> getAllStateRecords() {
    final records = <StateRecord>[];
    for (final key in _states.keys) {
      final data = _states.get(key);
      if (data != null) {
        records.add(_parseRecord(data));
      }
    }
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return records;
  }

  @override
  List<MemoryUnit> getAllMemoryUnits() {
    final units = <MemoryUnit>[];
    for (final key in _units.keys) {
      final data = _units.get(key);
      if (data != null) {
        units.add(_parseUnit(data));
      }
    }
    units.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return units;
  }

  @override
  List<ArchiveRecord> getAllArchiveRecords() {
    final records = _archives.values
        .map((json) => ArchiveRecord.fromJson(_safeCastMap(json)))
        .toList();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  Future<void> replaceStateRecords(List<StateRecord> records) async {
    await _states.clear();
    for (final record in records) {
      await _states.put(record.storageKey, record.toBinary());
    }
  }

  @override
  Future<void> replaceMemoryUnits(List<MemoryUnit> units) async {
    await _units.clear();
    for (final unit in units) {
      await _units.put(unit.id, unit.toBinary());
    }
  }

  @override
  Future<void> addArchiveRecords(List<ArchiveRecord> records) async {
    for (final record in records) {
      await _archives.put(record.id, record.toJson());
    }
  }

  @override
  Future<void> trimArchiveRecords(int maxEntries) async {
    final records = getAllArchiveRecords();
    if (records.length <= maxEntries) {
      return;
    }

    for (final record in records.skip(maxEntries)) {
      await _archives.delete(record.id);
    }
  }

  @override
  Future<void> clearAll() async {
    await _states.clear();
    await _units.clear();
    await _archives.clear();
  }

  /// 获取惰性加载统计信息
  LazyStats getStats() {
    return LazyStats(
      stateCount: _states.length,
      unitCount: _units.length,
      archiveCount: _archives.length,
    );
  }
}

class LazyStats {
  const LazyStats({
    required this.stateCount,
    required this.unitCount,
    required this.archiveCount,
  });

  final int stateCount;
  final int unitCount;
  final int archiveCount;

  @override
  String toString() {
    return 'LazyStats(states: $stateCount, units: $unitCount, archives: $archiveCount)';
  }
}
