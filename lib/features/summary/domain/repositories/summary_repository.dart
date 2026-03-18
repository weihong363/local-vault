import 'package:flutter/foundation.dart' hide Summary;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/features/summary/models/summary.dart';

class SummaryRepository {
  static const String _boxName = 'summaries';
  Box<Summary>? _box;

  Future<void> init() async {
    try {
      debugPrint('🔄 [SummaryRepository] Opening Hive box: $_boxName');
      if (_box == null) {
        _box = await Hive.openBox<Summary>(_boxName);
        debugPrint(
            '✅ [SummaryRepository] Hive box opened successfully with ${_box!.length} records');
      }
    } catch (e) {
      debugPrint('❌ [SummaryRepository] Failed to open Hive box: $e');
      debugPrint('⚠️  [SummaryRepository] Recreating the box from disk...');
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<Summary>(_boxName);
      debugPrint('✅ [SummaryRepository] Hive box recreated successfully');
    }
  }

  Box<Summary> get _summaryBox {
    assert(_box != null, 'Repository not initialized. Call init() first.');
    return _box!;
  }

  Future<void> addSummary(Summary summary) async {
    await _summaryBox.put(summary.id, summary);
  }

  Future<void> updateSummary(Summary summary) async {
    await _summaryBox.put(summary.id, summary);
  }

  Future<void> deleteSummary(String id) async {
    await _summaryBox.delete(id);
  }

  Summary? getSummary(String id) {
    return _summaryBox.get(id);
  }

  List<Summary> getAllSummaries() {
    final summaries = _summaryBox.values.toList();
    summaries.sort((a, b) {
      if (a.sortOrder != b.sortOrder) {
        return a.sortOrder.compareTo(b.sortOrder);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return summaries;
  }

  List<Summary> searchSummaries(String query) {
    final lowerQuery = query.toLowerCase();
    final summaries = _summaryBox.values.where((summary) {
      return summary.title.toLowerCase().contains(lowerQuery) ||
          summary.content.toLowerCase().contains(lowerQuery) ||
          summary.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
    summaries.sort((a, b) {
      if (a.sortOrder != b.sortOrder) {
        return a.sortOrder.compareTo(b.sortOrder);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return summaries;
  }

  Future<void> updateSortOrders(List<Summary> summaries) async {
    for (int i = 0; i < summaries.length; i++) {
      final summary = summaries[i];
      if (summary.sortOrder != i) {
        final updatedSummary = summary.copyWith(sortOrder: i);
        await _summaryBox.put(updatedSummary.id, updatedSummary);
      }
    }
  }

  List<Summary> getSummariesByTag(String tag) {
    return _summaryBox.values.where((summary) {
      return summary.tags.contains(tag);
    }).toList();
  }

  List<Summary> getSummariesBySource(String source) {
    return _summaryBox.values.where((summary) {
      return summary.source == source;
    }).toList();
  }

  int get totalCount {
    return _summaryBox.length;
  }

  Future<void> clearAll() async {
    await _summaryBox.clear();
  }
}
