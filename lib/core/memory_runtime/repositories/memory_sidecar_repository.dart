import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';

abstract class MemorySidecarRepository {
  Future<void> init();

  List<MemoryUnit> getAllMemoryUnits();

  Future<void> replaceMemoryUnits(List<MemoryUnit> units);

  List<ArchiveRecord> getAllArchiveRecords();

  Future<void> addArchiveRecords(List<ArchiveRecord> records);

  Future<void> trimArchiveRecords(int maxEntries);

  Future<void> clearAll();
}
