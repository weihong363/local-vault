import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/core/constants/app_storage.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/core/memory_runtime/repositories/memory_sidecar_repository.dart';

/// 变更记录
class StateChangeLog {
  const StateChangeLog({
    required this.storageKey,
    required this.field,
    required this.oldValue,
    required this.newValue,
    required this.changedAt,
    required this.reason,
  });

  final String storageKey;
  final String field;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime changedAt;
  final String reason; // merge/promote/compress/manual

  Map<String, dynamic> toJson() {
    return {
      'k': storageKey,
      'f': field,
      'old': oldValue,
      'new': newValue,
      't': changedAt.millisecondsSinceEpoch,
      'r': reason,
    };
  }

  factory StateChangeLog.fromJson(Map<String, dynamic> json) {
    return StateChangeLog(
      storageKey: json['k'] as String,
      field: json['f'] as String,
      oldValue: json['old'],
      newValue: json['new'],
      changedAt: DateTime.fromMillisecondsSinceEpoch(json['t'] as int),
      reason: json['r'] as String,
    );
  }

  @override
  String toString() {
    return 'StateChangeLog($storageKey.$field: $oldValue -> $newValue at $changedAt [$reason])';
  }
}

/// 带状态变更追踪的 Repository
class TrackedStateRepository implements MemorySidecarRepository {
  Box? _stateBox;
  Box? _unitBox;
  Box? _archiveBox;
  Box? _changeLogBox;

  final List<StateChangeLog> _pendingChanges = [];
  Timer? _flushTimer;

  static const Duration _flushDelay = Duration(seconds: 2);
  static const int _maxHistoryPerRecord = 10;

  @override
  Future<void> init() async {
    _stateBox ??= await _openBox(AppStorage.memoryStateBoxName);
    _unitBox ??= await _openBox(AppStorage.memoryUnitBoxName);
    _archiveBox ??= await _openBox(AppStorage.memoryArchiveBoxName);
    _changeLogBox ??= await _openBox('${AppStorage.memoryStateBoxName}_logs');
  }

  Future<Box> _openBox(String name) async {
    try {
      debugPrint('🔄 [TrackedStateRepository] Opening Hive box: $name');
      return await Hive.openBox(name);
    } catch (error) {
      debugPrint(
        '⚠️ [TrackedStateRepository] Failed to open $name, recreating: $error',
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

  Box get _changeLogs {
    assert(_changeLogBox != null, 'Repository not initialized.');
    return _changeLogBox!;
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

  /// 带追踪的单条记录更新
  Future<void> updateWithTracking(
    String storageKey,
    StateRecord newRecord, {
    required String reason,
  }) async {
    final oldData = _states.get(storageKey);
    final oldRecord = oldData != null ? _parseRecord(oldData) : null;

    // 检测字段变更并记录
    if (oldRecord != null) {
      _trackFieldChange(
          storageKey, 'summary', oldRecord.summary, newRecord.summary, reason);
      _trackFieldChange(
          storageKey, 'topic', oldRecord.topic, newRecord.topic, reason);
      _trackFieldChange(storageKey, 'importance', oldRecord.importance,
          newRecord.importance, reason);
      _trackFieldChange(storageKey, 'keywords', oldRecord.keywords,
          newRecord.keywords, reason);

      if (oldRecord.version != newRecord.version) {
        _trackFieldChange(storageKey, 'version', oldRecord.version,
            newRecord.version, reason);
      }
    }

    // 写入新记录
    await _states.put(storageKey, newRecord.toBinary());

    // 异步刷新变更日志
    _scheduleFlush();
  }

  void _trackFieldChange(
    String storageKey,
    String field,
    dynamic oldValue,
    dynamic newValue,
    String reason,
  ) {
    if (oldValue != newValue) {
      _pendingChanges.add(StateChangeLog(
        storageKey: storageKey,
        field: field,
        oldValue: oldValue,
        newValue: newValue,
        changedAt: DateTime.now(),
        reason: reason,
      ));
      debugPrint(
          '📝 [TrackedStateRepository] Field changed: $field ($oldValue -> $newValue)');
    }
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(_flushDelay, _flushChanges);
  }

  Future<void> _flushChanges() async {
    if (_pendingChanges.isEmpty) return;

    debugPrint(
        '💾 [TrackedStateRepository] Flushing ${_pendingChanges.length} changes...');

    for (final change in _pendingChanges) {
      final logKey =
          '${change.storageKey}_${change.changedAt.millisecondsSinceEpoch}';
      await _changeLogs.put(logKey, change.toJson());
    }

    // 清理过期的历史记录（每个 key 只保留最近的 N 条）
    await _trimHistory();

    _pendingChanges.clear();
    debugPrint('✅ [TrackedStateRepository] Changes flushed successfully');
  }

  Future<void> _trimHistory() async {
    final logsByRecord = <String, List<MapEntry<String, dynamic>>>{};

    // 按 storageKey 分组
    for (final key in _changeLogs.keys) {
      final data = _changeLogs.get(key);
      if (data == null) continue;

      final map = _safeCastMap(data);
      final storageKey = map['k'] as String;
      logsByRecord
          .putIfAbsent(storageKey, () => [])
          .add(MapEntry(key as String, data));
    }

    // 每个 record 只保留最近的 N 条
    for (final entry in logsByRecord.entries) {
      if (entry.value.length <= _maxHistoryPerRecord) continue;

      // 按时间戳排序，删除旧的
      entry.value.sort((a, b) {
        final aData = _safeCastMap(a.value);
        final bData = _safeCastMap(b.value);
        final aTime = aData['t'] as int;
        final bTime = bData['t'] as int;
        return bTime.compareTo(aTime);
      });

      // 删除超出限制的旧记录
      for (final logEntry in entry.value.skip(_maxHistoryPerRecord)) {
        await _changeLogs.delete(logEntry.key);
      }
    }
  }

  /// 查询变更历史
  List<StateChangeLog> getChangeHistory(String storageKey, {int? limit}) {
    final logs = <StateChangeLog>[];
    final prefix = '${storageKey}_';

    for (final key in _changeLogs.keys) {
      if (!key.startsWith(prefix)) continue;

      final data = _changeLogs.get(key);
      if (data == null) continue;

      try {
        final map = _safeCastMap(data);
        if (map['k'] == storageKey) {
          logs.add(StateChangeLog.fromJson(map));
        }
      } catch (e) {
        debugPrint('⚠️ Failed to parse change log $key: $e');
      }
    }

    // 按时间倒序排列
    logs.sort((a, b) => b.changedAt.compareTo(a.changedAt));

    if (limit != null && logs.length > limit) {
      return logs.sublist(0, limit);
    }

    return logs;
  }

  /// 获取所有待处理的变更
  List<StateChangeLog> getPendingChanges() {
    return List.unmodifiable(_pendingChanges);
  }

  /// 手动刷新变更日志
  Future<void> flushChanges() async {
    await _flushChanges();
  }

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

  Future<void> replaceStateRecords(List<StateRecord> records) async {
    // 批量替换时不追踪单个变更，记录一次 bulk 操作
    final now = DateTime.now();
    _pendingChanges.add(StateChangeLog(
      storageKey: 'BULK_OPERATION',
      field: 'records',
      oldValue: _states.length,
      newValue: records.length,
      changedAt: now,
      reason: 'bulk_replace',
    ));

    await _states.clear();
    for (final record in records) {
      await _states.put(record.storageKey, record.toBinary());
    }

    _scheduleFlush();
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
    await _changeLogs.clear();
    _pendingChanges.clear();
    _flushTimer?.cancel();
  }

  /// 获取追踪统计信息
  TrackingStats getTrackingStats() {
    return TrackingStats(
      pendingChanges: _pendingChanges.length,
      totalLogs: _changeLogs.length,
      maxHistoryPerRecord: _maxHistoryPerRecord,
    );
  }
}

class TrackingStats {
  const TrackingStats({
    required this.pendingChanges,
    required this.totalLogs,
    required this.maxHistoryPerRecord,
  });

  final int pendingChanges;
  final int totalLogs;
  final int maxHistoryPerRecord;

  @override
  String toString() {
    return 'TrackingStats(pending: $pendingChanges, logs: $totalLogs, maxPerRecord: $maxHistoryPerRecord)';
  }
}
