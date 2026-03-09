import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/features/summary/models/summary.dart';
import 'package:local_vault/features/summary/domain/repositories/summary_repository.dart';

final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  return SummaryRepository();
});

final summaryListProvider = FutureProvider<List<Summary>>((ref) async {
  final repository = ref.watch(summaryRepositoryProvider);
  await repository.init();
  return repository.getAllSummaries();
});

class SummaryNotifier extends StateNotifier<AsyncValue<List<Summary>>> {
  final SummaryRepository repository;

  SummaryNotifier(this.repository) : super(const AsyncLoading()) {
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    try {
      await repository.init();
      final summaries = repository.getAllSummaries();
      state = AsyncData(summaries);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addSummary(Summary summary) async {
    state = const AsyncLoading();
    try {
      await repository.addSummary(summary);
      final summaries = repository.getAllSummaries();
      state = AsyncData(summaries);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> deleteSummary(String id) async {
    state = const AsyncLoading();
    try {
      await repository.deleteSummary(id);
      final summaries = repository.getAllSummaries();
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
      final summaries = repository.searchSummaries(query);
      state = AsyncData(summaries);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    await _loadSummaries();
  }
}

final summaryNotifierProvider = StateNotifierProvider<SummaryNotifier, AsyncValue<List<Summary>>>((ref) {
  final repository = ref.watch(summaryRepositoryProvider);
  return SummaryNotifier(repository);
});
