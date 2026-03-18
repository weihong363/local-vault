import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/summary_merge_models.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';

/// Summary UseCase Provider - 使用新架构
final summaryUseCasesProvider = Provider<SummaryUseCases>((ref) {
  return sl<SummaryUseCases>();
});

/// Summary List Provider - 新架构
class SummaryEntityNotifier
    extends StateNotifier<AsyncValue<List<SummaryEntity>>> {
  final SummaryUseCases useCases;

  SummaryEntityNotifier(this.useCases) : super(const AsyncLoading()) {
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    try {
      final summaries = useCases.getAllSummaries();
      state = AsyncData(summaries);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addSummary(SummaryEntity summary) async {
    state = const AsyncLoading();
    try {
      if (summary.type == MemoryType.session) {
        await useCases.addSessionMemory(summary);
      } else {
        await useCases.addFactSummary(summary);
      }
      final summaries = useCases.getAllSummaries();
      state = AsyncData(summaries);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addWithDeduplication(SummaryEntity summary) async {
    state = const AsyncLoading();
    try {
      if (summary.type == MemoryType.session) {
        await useCases.addSessionMemory(summary);
      } else {
        await useCases.addFactSummary(summary);
      }
      final summaries = useCases.getAllSummaries();
      state = AsyncData(summaries);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<FactSummarySaveResult> addFactSummary(SummaryEntity summary) async {
    state = const AsyncLoading();
    try {
      final result = await useCases.addFactSummary(summary);
      final summaries = useCases.getAllSummaries();
      state = AsyncData(summaries);
      return result;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> addSessionMemory(SummaryEntity summary) async {
    state = const AsyncLoading();
    try {
      await useCases.addSessionMemory(summary);
      final summaries = useCases.getAllSummaries();
      state = AsyncData(summaries);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateSummary(SummaryEntity summary) async {
    state = const AsyncLoading();
    try {
      await useCases.updateSummary(summary);
      final summaries = useCases.getAllSummaries();
      state = AsyncData(summaries);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> deleteSummary(String id) async {
    state = const AsyncLoading();
    try {
      await useCases.deleteSummary(id);
      final summaries = useCases.getAllSummaries();
      state = AsyncData(summaries);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> searchSummaries(String query) async {
    if (query.isEmpty) {
      await _loadSummaries();
      return;
    }
    try {
      final summaries = useCases.searchSummaries(query);
      state = AsyncData(summaries);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    await _loadSummaries();
  }

  Future<void> updateSortOrders(List<SummaryEntity> summaries) async {
    try {
      await useCases.updateSortOrders(summaries);
      state = AsyncData(List.from(summaries));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> recordAccess(String id) async {
    try {
      await useCases.recordAccess(id);
      await _loadSummaries();
    } catch (e) {
      debugPrint('Failed to record access: $e');
    }
  }

  Future<void> updateImportance(String id, double importance) async {
    try {
      await useCases.updateImportance(id, importance);
      await _loadSummaries();
    } catch (e) {
      debugPrint('Failed to update importance: $e');
    }
  }

  Future<String?> getFactUpgradeReason(String id) async {
    try {
      return await useCases.getFactUpgradeReason(id);
    } catch (e) {
      debugPrint('Failed to get upgrade reason: $e');
      return null;
    }
  }

  Future<void> upgradeFactToCore(String id) async {
    try {
      await useCases.upgradeFactToCore(id);
      await _loadSummaries();
    } catch (e) {
      debugPrint('Failed to manually upgrade core memory: $e');
      rethrow;
    }
  }

  void filterByType(MemoryType type) {
    try {
      final summaries = useCases.getSummariesByType(type);
      state = AsyncData(summaries);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> applyForgettingCurve() async {
    try {
      await useCases.applyForgettingCurve();
      await _loadSummaries();
    } catch (e) {
      debugPrint('Failed to apply the forgetting curve: $e');
    }
  }

  Future<void> cleanupSessionMemories() async {
    try {
      await useCases.cleanupSessionMemories();
      await _loadSummaries();
    } catch (e) {
      debugPrint('Failed to clean up session memories: $e');
    }
  }

  Future<void> checkAndMergeSessionBatches() async {
    try {
      await useCases.checkAndMergeSessionBatches();
      await _loadSummaries();
    } catch (e) {
      debugPrint('Failed to check and merge session batches: $e');
    }
  }

  List<SummaryEntity> findSimilarMemories(SummaryEntity target) {
    try {
      return useCases.findSimilarMemories(target);
    } catch (e) {
      debugPrint('Failed to find similar memories: $e');
      return [];
    }
  }

  List<SummaryMergeCandidate> findMergeCandidates(SummaryEntity target) {
    try {
      return useCases.findMergeCandidates(target);
    } catch (e) {
      debugPrint('Failed to find merge candidates: $e');
      return [];
    }
  }

  Future<void> mergeMemories(String id1, String id2) async {
    state = const AsyncLoading();
    try {
      await useCases.mergeMemories(id1, id2);
      await _loadSummaries();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> mergeFactMemories({
    required String primaryId,
    required String secondaryId,
    SummaryMergeResolution resolution = const SummaryMergeResolution(),
  }) async {
    state = const AsyncLoading();
    try {
      await useCases.mergeMemoriesWithResolution(
        primaryId: primaryId,
        secondaryId: secondaryId,
        resolution: resolution,
      );
      await _loadSummaries();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final summaryEntityNotifierProvider = StateNotifierProvider<
    SummaryEntityNotifier, AsyncValue<List<SummaryEntity>>>((ref) {
  final useCases = ref.watch(summaryUseCasesProvider);
  return SummaryEntityNotifier(useCases);
});
