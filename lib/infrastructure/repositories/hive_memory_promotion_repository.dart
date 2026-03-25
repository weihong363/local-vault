import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/core/constants/app_storage.dart';
import 'package:local_vault/core/domain/entities/memory_promotion_metadata.dart';
import 'package:local_vault/core/domain/repositories/memory_promotion_repository_interface.dart';

/// Hive-backed implementation of MemoryPromotionRepositoryInterface
///
/// 💡 **存储策略**：
/// - 使用独立的 Hive Box (`memory_promotion_v1`)
/// - key: summaryId (String)
/// - value: MemoryPromotionMetadata (JSON Map)
class HiveMemoryPromotionRepository
    implements MemoryPromotionRepositoryInterface {
  static final String _boxName = AppStorage.memoryPromotionBoxName;
  Box? _box;

  @override
  Future<void> init() async {
    try {
      debugPrint(
          '🔄 [HiveMemoryPromotionRepository] Opening Hive box: $_boxName');
      if (_box == null) {
        _box = await Hive.openBox(_boxName);
        debugPrint(
          '✅ [HiveMemoryPromotionRepository] Hive box opened successfully with ${_box!.length} record(s)',
        );
      }
    } catch (e) {
      debugPrint(
          '❌ [HiveMemoryPromotionRepository] Failed to open Hive box: $e');
      debugPrint(
          '⚠️ [HiveMemoryPromotionRepository] Recreating the box from disk...');
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox(_boxName);
      debugPrint(
          '✅ [HiveMemoryPromotionRepository] Hive box recreated successfully');
    }
  }

  Box get _promotionBox {
    assert(_box != null, 'Repository not initialized. Call init() first.');
    return _box!;
  }

  @override
  List<MemoryPromotionMetadata> getAllMetadata() {
    try {
      return _promotionBox.keys
          .map((key) {
            final data = _promotionBox.get(key);
            if (data is Map<String, dynamic>) {
              return MemoryPromotionMetadata.fromJson(data);
            }
            return null;
          })
          .whereType<MemoryPromotionMetadata>()
          .toList();
    } catch (e) {
      debugPrint(
          '❌ [HiveMemoryPromotionRepository] Failed to get all metadata: $e');
      return [];
    }
  }

  @override
  MemoryPromotionMetadata? getMetadata(String summaryId) {
    try {
      final data = _promotionBox.get(summaryId);
      if (data is Map<String, dynamic>) {
        return MemoryPromotionMetadata.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint(
          '❌ [HiveMemoryPromotionRepository] Failed to get metadata for $summaryId: $e');
      return null;
    }
  }

  @override
  Future<void> saveMetadata(MemoryPromotionMetadata metadata) async {
    try {
      await _promotionBox.put(metadata.summaryId, metadata.toJson());
      debugPrint(
        '💾 [HiveMemoryPromotionRepository] Saved promotion metadata: ${metadata.summaryId}',
      );
    } catch (e) {
      debugPrint(
          '❌ [HiveMemoryPromotionRepository] Failed to save metadata: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveAllMetadata(
      List<MemoryPromotionMetadata> metadataList) async {
    try {
      final batch = <String, Map<String, dynamic>>{};
      for (final metadata in metadataList) {
        batch[metadata.summaryId] = metadata.toJson();
      }
      await _promotionBox.putAll(batch);
      debugPrint(
        '💾 [HiveMemoryPromotionRepository] Batch saved ${metadataList.length} promotion metadata records',
      );
    } catch (e) {
      debugPrint(
          '❌ [HiveMemoryPromotionRepository] Failed to batch save metadata: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMetadata(String summaryId) async {
    try {
      await _promotionBox.delete(summaryId);
      debugPrint(
        '🗑️ [HiveMemoryPromotionRepository] Deleted promotion metadata: $summaryId',
      );
    } catch (e) {
      debugPrint(
          '❌ [HiveMemoryPromotionRepository] Failed to delete metadata: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _promotionBox.clear();
      debugPrint(
        '🧹 [HiveMemoryPromotionRepository] Cleared all promotion metadata',
      );
    } catch (e) {
      debugPrint('❌ [HiveMemoryPromotionRepository] Failed to clear all: $e');
      rethrow;
    }
  }

  @override
  int get totalCount => _promotionBox.length;
}
