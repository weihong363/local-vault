import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/core/constants/app_storage.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/core/memory_runtime/repositories/memory_sidecar_repository.dart';

/// 带索引优化的 StateRepository，支持快速查询
class IndexedStateRepository implements MemorySidecarRepository {
  Box? _stateBox;
  Box? _unitBox;
  Box? _archiveBox;

  // 内存索引（启动时构建）
  final Map<String, Set<String>> _namespaceIndex = {};
  final Map<String, Set<String>> _topicIndex = {};
  bool _indexesBuilt = false;

  @override
  Future<void> init() async {
    _stateBox ??= await _openBox(AppStorage.memoryStateBoxName);
    _unitBox ??= await _openBox(AppStorage.memoryUnitBoxName);
    _archiveBox ??= await _openBox(AppStorage.memoryArchiveBoxName);

    // 构建索引
    await _buildIndexes();
  }

  Future<Box> _openBox(String name) async {
    try {
      debugPrint('🔄 [IndexedStateRepository] Opening Hive box: $name');
      return await Hive.openBox(name);
    } catch (error) {
      debugPrint(
        '⚠️ [IndexedStateRepository] Failed to open $name, recreating: $error',
      );
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox(name);
    }
  }

  /// 构建内存索引
  Future<void> _buildIndexes() async {
    if (_indexesBuilt) return;

    debugPrint('🔨 [IndexedStateRepository] Building indexes...');
    _namespaceIndex.clear();
    _topicIndex.clear();

    final stateBox = _stateBox;
    if (stateBox == null) return;

    for (final key in stateBox.keys) {
      final data = stateBox.get(key);
      if (data == null) continue;

      StateRecord record;
      try {
        record = _parseRecord(data);
      } catch (e) {
        debugPrint('⚠️ Failed to parse record $key: $e');
        continue;
      }

      // 构建 namespace 索引
      _namespaceIndex
          .putIfAbsent(record.namespace, () => {})
          .add(key as String);

      // 构建 topic 索引
      if (record.topic.isNotEmpty) {
        _topicIndex.putIfAbsent(record.topic, () => {}).add(key);
      }
    }

    _indexesBuilt = true;
    debugPrint(
      '✅ [IndexedStateRepository] Indexes built: ${_namespaceIndex.length} namespaces, ${_topicIndex.length} topics',
    );
  }

  StateRecord _parseRecord(dynamic data) {
    if (data is List<int>) {
      return StateRecord.fromBinary(data);
    }
    final map = _safeCastMap(data);
    return StateRecord.fromJson(map);
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

  Map<String, dynamic> _safeCastMap(dynamic map) {
    if (map is Map<String, dynamic>) {
      return map;
    }
    if (map is Map) {
      return Map<String, dynamic>.from(map);
    }
    throw ArgumentError('Cannot convert to Map<String, dynamic>: $map');
  }

  /// 按 namespace 快速查询
  List<StateRecord> getByNamespace(String namespace) {
    if (!_indexesBuilt) {
      debugPrint('⚠️ Indexes not built, falling back to full scan');
      return getAllStateRecords()
          .where((r) => r.namespace == namespace)
          .toList();
    }

    final keys = _namespaceIndex[namespace] ?? const {};
    return keys
        .map((key) {
          final data = _states.get(key);
          if (data == null) return null;
          return _parseRecord(data);
        })
        .whereType<StateRecord>()
        .toList();
  }

  /// 按 topic 快速查询
  List<StateRecord> getByTopic(String topic) {
    if (!_indexesBuilt) {
      return getAllStateRecords().where((r) => r.topic == topic).toList();
    }

    final keys = _topicIndex[topic] ?? const {};
    return keys
        .map((key) {
          final data = _states.get(key);
          if (data == null) return null;
          return _parseRecord(data);
        })
        .whereType<StateRecord>()
        .toList();
  }

  /// 组合查询（支持 AND/OR）
  List<StateRecord> query({
    String? namespace,
    String? topic,
    List<String>? keywords,
    QueryLogic logic = QueryLogic.and,
    int? limit,
  }) {
    var results = <StateRecord>[];

    // 优先使用索引
    if (namespace != null && _indexesBuilt) {
      results = getByNamespace(namespace);
    } else if (topic != null && _indexesBuilt) {
      results = getByTopic(topic);
    } else {
      results = getAllStateRecords();
    }

    // 过滤
    if (namespace != null && !_indexesBuilt) {
      results = results.where((r) => r.namespace == namespace).toList();
    }
    if (topic != null && !_indexesBuilt) {
      results = results.where((r) => r.topic == topic).toList();
    }

    if (keywords != null && keywords.isNotEmpty) {
      results = results.where((r) {
        final matches = keywords
            .every((kw) => r.keywords.contains(kw) || r.topic.contains(kw));
        return logic == QueryLogic.and ? matches : !matches;
      }).toList();
    }

    // 限制结果数量
    if (limit != null && results.length > limit) {
      results = results.sublist(0, limit);
    }

    return results;
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
    // 重建索引
    _indexesBuilt = false;
    await _buildIndexes();
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
    _namespaceIndex.clear();
    _topicIndex.clear();
    _indexesBuilt = false;
  }
}

enum QueryLogic { and, or }
