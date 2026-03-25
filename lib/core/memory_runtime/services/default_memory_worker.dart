import 'dart:collection';

import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';

class DefaultMemoryWorker implements MemoryWorker {
  final Queue<MemoryCompressionJob> _pendingJobs =
      Queue<MemoryCompressionJob>();
  bool _isProcessing = false;
  DateTime? _lastProcessedAt;
  String? _lastError;

  @override
  void beginProcessing() {
    _isProcessing = true;
    _lastError = null;
  }

  @override
  void completeProcessing({String? errorMessage}) {
    _isProcessing = false;
    _lastProcessedAt = DateTime.now();
    _lastError = errorMessage;
  }

  @override
  Future<void> enqueue(MemoryCompressionJob job) async {
    _pendingJobs.add(job);
  }

  @override
  MemoryRuntimeDiagnostics snapshot({
    int stateRecordCount = 0,
    int memoryUnitCount = 0,
    int archiveRecordCount = 0,
  }) {
    return MemoryRuntimeDiagnostics(
      queueDepth: _pendingJobs.length,
      isProcessing: _isProcessing,
      lastProcessedAt: _lastProcessedAt,
      lastError: _lastError,
      stateRecordCount: stateRecordCount,
      memoryUnitCount: memoryUnitCount,
      archiveRecordCount: archiveRecordCount,
    );
  }

  @override
  List<MemoryCompressionJob> takePendingJobs() {
    final jobs = _pendingJobs.toList(growable: false);
    _pendingJobs.clear();
    return jobs;
  }
}
