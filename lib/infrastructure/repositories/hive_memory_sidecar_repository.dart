import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/core/constants/app_storage.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/core/memory_runtime/repositories/memory_sidecar_repository.dart';

class HiveMemorySidecarRepository implements MemorySidecarRepository {
  static final String _stateBoxName = AppStorage.memoryStateBoxName;
  static final String _unitBoxName = AppStorage.memoryUnitBoxName;
  static final String _archiveBoxName = AppStorage.memoryArchiveBoxName;

  Box? _stateBox;
  Box? _unitBox;
  Box? _archiveBox;

  @override
  Future<void> init() async {
    _stateBox ??= await _openBox(_stateBoxName);
    _unitBox ??= await _openBox(_unitBoxName);
    _archiveBox ??= await _openBox(_archiveBoxName);
  }

  Future<Box> _openBox(String name) async {
    try {
      debugPrint('🔄 [HiveMemorySidecarRepository] Opening Hive box: $name');
      return await Hive.openBox(name);
    } catch (error) {
      debugPrint(
        '⚠️ [HiveMemorySidecarRepository] Failed to open $name, recreating: $error',
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

  Map<String, dynamic> _safeCastMap(dynamic map) {
    if (map is Map<String, dynamic>) {
      return map;
    }
    if (map is Map) {
      return Map<String, dynamic>.from(map);
    }
    throw ArgumentError('Cannot convert to Map<String, dynamic>: $map');
  }

  @override
  Future<void> addArchiveRecords(List<ArchiveRecord> records) async {
    for (final record in records) {
      await _archives.put(record.id, record.toJson());
    }
  }

  @override
  Future<void> clearAll() async {
    await _states.clear();
    await _units.clear();
    await _archives.clear();
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
  List<MemoryUnit> getAllMemoryUnits() {
    final units = _units.values
        .map((json) => MemoryUnit.fromJson(_safeCastMap(json)))
        .toList();
    units.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return units;
  }

  @override
  List<StateRecord> getAllStateRecords() {
    final records = _states.values
        .map((json) => StateRecord.fromJson(_safeCastMap(json)))
        .toList();
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return records;
  }

  @override
  Future<void> replaceMemoryUnits(List<MemoryUnit> units) async {
    await _units.clear();
    for (final unit in units) {
      await _units.put(unit.id, unit.toJson());
    }
  }

  @override
  Future<void> replaceStateRecords(List<StateRecord> records) async {
    await _states.clear();
    for (final record in records) {
      await _states.put(record.storageKey, record.toJson());
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
}
