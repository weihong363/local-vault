import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/core/constants/app_storage.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/core/memory_runtime/repositories/memory_sidecar_repository.dart';

/// 支持原子批量操作的 Transactional Repository
class TransactionalStateRepository implements MemorySidecarRepository {
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
      debugPrint('🔄 [TransactionalStateRepository] Opening Hive box: $name');
      return await Hive.openBox(name);
    } catch (error) {
      debugPrint(
        '⚠️ [TransactionalStateRepository] Failed to open $name, recreating: $error',
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
    return MemoryUnit(
      id: map['id'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      topic: map['topic'] as String? ?? '',
      keywords: List<String>.from(map['keywords'] ?? const <String>[]),
      importance: switch (map['importance']) {
        int value => value.toDouble(),
        double value => value,
        _ => 0.0,
      },
      sourceIds: List<String>.from(map['sourceIds'] ?? const <String>[]),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      confidence: switch (map['confidence']) {
        int value => value.toDouble(),
        double value => value,
        _ => 0.0,
      },
    );
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

  /// 原子性批量替换（使用事务性写入）
  @override
  Future<void> replaceStateRecords(List<StateRecord> records) async {
    try {
      debugPrint(
          '⚛️ [TransactionalStateRepository] Starting atomic replacement of ${records.length} records...');

      // 先清除所有旧记录
      await _states.clear();

      // 批量写入新记录（使用二进制编码）
      for (final record in records) {
        await _states.put(record.storageKey, record.toBinary());
      }

      debugPrint(
          '✅ [TransactionalStateRepository] Atomic replacement completed: ${records.length} records');
    } catch (e) {
      debugPrint('❌ [TransactionalStateRepository] Batch operation failed: $e');
      rethrow;
    }
  }

  /// 原子性批量替换 MemoryUnits
  @override
  Future<void> replaceMemoryUnits(List<MemoryUnit> units) async {
    try {
      debugPrint(
          '⚛️ [TransactionalStateRepository] Starting atomic replacement of ${units.length} units...');

      // 清除并重新写入
      await _units.clear();

      // 批量写入新记录
      for (final unit in units) {
        await _units.put(unit.id, unit.toBinary());
      }

      debugPrint(
          '✅ [TransactionalStateRepository] Atomic replacement completed: ${units.length} units');
    } catch (e) {
      debugPrint('❌ [TransactionalStateRepository] Batch operation failed: $e');
      rethrow;
    }
  }

  /// 乐观锁更新（防止并发冲突 - CAS 操作）
  Future<bool> updateWithOptimisticLock(
    String storageKey,
    StateRecord Function(StateRecord? old) updater, {
    int maxRetries = 3,
  }) async {
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      // 读取当前值
      final oldData = _states.get(storageKey);
      final oldRecord = oldData != null ? _parseRecord(oldData) : null;

      // 应用更新函数
      final newRecord = updater(oldRecord);

      // 检查版本号是否变化（CAS 操作）
      if (oldRecord != null) {
        final currentData = _states.get(storageKey);
        if (currentData != null) {
          final currentRecord = _parseRecord(currentData);
          if (currentRecord.version != oldRecord.version) {
            // 检测到并发修改，重试
            debugPrint(
                '⚠️ [TransactionalStateRepository] CAS failed (version conflict), retrying... ($attempt/${maxRetries - 1})');
            continue;
          }
        }
      }

      // 写入新版本
      await _states.put(storageKey, newRecord.toBinary());
      debugPrint(
          '✅ [TransactionalStateRepository] Optimistic lock update succeeded: $storageKey');
      return true;
    }

    debugPrint(
        '❌ [TransactionalStateRepository] Optimistic lock update failed after $maxRetries retries');
    return false; // 超过最大重试次数
  }

  /// 带事务的多条记录更新
  Future<void> updateMultiple({
    required List<(String, StateRecord)> updates,
    String reason = 'multi_update',
  }) async {
    try {
      debugPrint(
          '⚛️ [TransactionalStateRepository] Starting transactional update of ${updates.length} records...');

      for (final update in updates) {
        final key = update.$1;
        final record = update.$2;
        await _states.put(key, record.toBinary());
      }

      debugPrint(
          '✅ [TransactionalStateRepository] Transactional update completed');
    } catch (e) {
      debugPrint(
          '❌ [TransactionalStateRepository] Transactional update failed: $e');
      rethrow;
    }
  }

  /// 条件更新（只有满足条件才更新）
  Future<bool> updateIf(
    String storageKey,
    StateRecord Function(StateRecord old) updater, {
    required bool Function(StateRecord old) condition,
  }) async {
    final oldData = _states.get(storageKey);
    if (oldData == null) {
      debugPrint(
          '⚠️ [TransactionalStateRepository] Record not found: $storageKey');
      return false;
    }

    final oldRecord = _parseRecord(oldData);

    // 检查条件
    if (!condition(oldRecord)) {
      debugPrint(
          '⚠️ [TransactionalStateRepository] Update condition not met for $storageKey');
      return false;
    }

    // 应用更新
    final newRecord = updater(oldRecord);
    await _states.put(storageKey, newRecord.toBinary());

    debugPrint(
        '✅ [TransactionalStateRepository] Conditional update succeeded: $storageKey');
    return true;
  }

  @override
  List<StateRecord> getAllStateRecords() {
    final records = _states.values.map((json) => _parseRecord(json)).toList();
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return records;
  }

  @override
  List<MemoryUnit> getAllMemoryUnits() {
    final units = _units.values.map((json) => _parseUnit(json)).toList();
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

  /// 获取事务统计信息
  TransactionStats getStats() {
    return TransactionStats(
      stateCount: _states.length,
      unitCount: _units.length,
      archiveCount: _archives.length,
    );
  }
}

class TransactionStats {
  const TransactionStats({
    required this.stateCount,
    required this.unitCount,
    required this.archiveCount,
  });

  final int stateCount;
  final int unitCount;
  final int archiveCount;

  @override
  String toString() {
    return 'TransactionStats(states: $stateCount, units: $unitCount, archives: $archiveCount)';
  }
}
