import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/core/constants/app_storage.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/core/memory_runtime/repositories/memory_sidecar_repository.dart';

/// 带 LRU 缓存的 StateRepository，优化读取性能
class CachedStateRepository implements MemorySidecarRepository {
  Box? _stateBox;
  Box? _unitBox;
  Box? _archiveBox;

  // LRU 缓存
  final Map<String, StateRecord> _stateCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Set<String> _dirtyKeys = {};

  static const int _maxCacheSize = 100;
  static const Duration _cacheTTL = Duration(minutes: 5);

  Timer? _flushTimer;

  @override
  Future<void> init() async {
    _stateBox ??= await _openBox(AppStorage.memoryStateBoxName);
    _unitBox ??= await _openBox(AppStorage.memoryUnitBoxName);
    _archiveBox ??= await _openBox(AppStorage.memoryArchiveBoxName);
  }

  Future<Box> _openBox(String name) async {
    try {
      debugPrint('🔄 [CachedStateRepository] Opening Hive box: $name');
      return await Hive.openBox(name);
    } catch (error) {
      debugPrint(
        '⚠️ [CachedStateRepository] Failed to open $name, recreating: $error',
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

  /// 带缓存的单条记录读取
  StateRecord? get(String storageKey) {
    // 1. 检查缓存
    if (_stateCache.containsKey(storageKey)) {
      // 2. 检查 TTL
      final timestamp = _cacheTimestamps[storageKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) > _cacheTTL) {
        _stateCache.remove(storageKey);
        _cacheTimestamps.remove(storageKey);
      } else {
        debugPrint('💾 [CachedStateRepository] Cache hit: $storageKey');
        return _stateCache[storageKey];
      }
    }

    // 3. 从 Hive 读取
    final data = _states.get(storageKey);
    if (data == null) return null;

    StateRecord record;
    try {
      record = _parseRecord(data);
    } catch (e) {
      debugPrint('❌ Failed to parse record $storageKey: $e');
      return null;
    }

    // 4. 写入缓存（LRU 淘汰）
    if (_stateCache.length >= _maxCacheSize) {
      _evictOldest();
    }

    _stateCache[storageKey] = record;
    _cacheTimestamps[storageKey] = DateTime.now();
    debugPrint('📥 [CachedStateRepository] Cache miss, loaded: $storageKey');

    return record;
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

  void _evictOldest() {
    if (_stateCache.isEmpty) return;

    final oldestKey = _cacheTimestamps.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;

    _stateCache.remove(oldestKey);
    _cacheTimestamps.remove(oldestKey);
    debugPrint('🗑️ [CachedStateRepository] Evicted oldest: $oldestKey');
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
    await _states.clear();
    _stateCache.clear();
    _cacheTimestamps.clear();
    _dirtyKeys.clear();

    for (final record in records) {
      await _states.put(record.storageKey, record.toBinary());
      _stateCache[record.storageKey] = record;
      _cacheTimestamps[record.storageKey] = DateTime.now();
    }

    debugPrint(
        '✅ [CachedStateRepository] Replaced ${records.length} state records');
  }

  @override
  Future<void> replaceMemoryUnits(List<MemoryUnit> units) async {
    await _units.clear();
    for (final unit in units) {
      await _units.put(unit.id, unit.toBinary());
    }
    debugPrint(
        '✅ [CachedStateRepository] Replaced ${units.length} memory units');
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
    _stateCache.clear();
    _cacheTimestamps.clear();
    _dirtyKeys.clear();
    _flushTimer?.cancel();
  }

  /// 获取缓存统计信息
  CacheStats getCacheStats() {
    return CacheStats(
      cachedCount: _stateCache.length,
      dirtyCount: _dirtyKeys.length,
      maxSize: _maxCacheSize,
    );
  }

  /// 手动清理过期缓存
  void cleanupExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheTTL) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _stateCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint(
          '🧹 [CachedStateRepository] Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }
}

class CacheStats {
  const CacheStats({
    required this.cachedCount,
    required this.dirtyCount,
    required this.maxSize,
  });

  final int cachedCount;
  final int dirtyCount;
  final int maxSize;

  double get hitRate =>
      cachedCount > 0 ? (cachedCount - dirtyCount) / cachedCount : 0.0;

  @override
  String toString() {
    return 'CacheStats(cached: $cachedCount, dirty: $dirtyCount, max: $maxSize, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}
