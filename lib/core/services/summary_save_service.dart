import 'package:flutter/foundation.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';
import 'package:local_vault/core/utils/summary_text_utils.dart';

/// Save trigger categories for summary persistence.
enum SaveTriggerType {
  share, // Triggered from the system share sheet.
  gesture, // Triggered by a gesture such as back taps.
  quickAction, // Triggered by quick actions such as tiles or floating controls.
  voice, // Triggered by voice wake-up.
  manual, // Triggered manually inside the app.
}

/// Context information that accompanies a save action.
class SaveContext {
  /// Trigger type.
  final SaveTriggerType triggerType;

  /// Detailed metadata about the save source.
  final Map<String, dynamic>? metadata;

  /// Timestamp captured when the context is created.
  final DateTime timestamp;

  SaveContext({
    required this.triggerType,
    this.metadata,
  }) : timestamp = DateTime.now();

  /// Create share-trigger context.
  factory SaveContext.share({Map<String, dynamic>? metadata}) {
    return SaveContext(
      triggerType: SaveTriggerType.share,
      metadata: metadata,
    );
  }

  /// Create gesture-trigger context.
  factory SaveContext.gesture({int? tapCount, String? packageName}) {
    return SaveContext(
      triggerType: SaveTriggerType.gesture,
      metadata: {
        if (tapCount != null) 'tapCount': tapCount,
        if (packageName != null) 'packageName': packageName,
      },
    );
  }

  /// Create quick-action context.
  factory SaveContext.quickAction({String? actionId}) {
    return SaveContext(
      triggerType: SaveTriggerType.quickAction,
      metadata: {
        if (actionId != null) 'actionId': actionId,
      },
    );
  }

  /// Create voice-trigger context.
  factory SaveContext.voice({String? voiceCommand}) {
    return SaveContext(
      triggerType: SaveTriggerType.voice,
      metadata: {
        if (voiceCommand != null) 'voiceCommand': voiceCommand,
      },
    );
  }

  /// Create manual-trigger context.
  factory SaveContext.manual({String? source}) {
    return SaveContext(
      triggerType: SaveTriggerType.manual,
      metadata: {
        if (source != null) 'source': source,
      },
    );
  }

  @override
  String toString() {
    return 'SaveContext(trigger: $triggerType, metadata: $metadata, time: $timestamp)';
  }
}

/// Summary data prepared for saving.
class SavePayload {
  /// Title.
  final String title;

  /// Content.
  final String content;

  /// Tag list.
  final List<String> tags;

  /// Optional remark.
  final String? remark;

  /// Source type used to distinguish different data origins.
  final String sourceType;

  const SavePayload({
    required this.title,
    required this.content,
    this.tags = const [],
    this.remark,
    this.sourceType = 'manual',
  });

  /// Create a payload from shared text.
  factory SavePayload.fromShare(String text) {
    return SavePayload(
      title: '',
      content: text,
      sourceType: 'share',
    );
  }

  /// Create a payload from OCR output.
  factory SavePayload.fromOCR(String recognizedText) {
    return SavePayload(
      title: '',
      content: recognizedText,
      sourceType: 'ocr',
    );
  }

  /// Append the remark to the content if present.
  SavePayload withRemark(String? remark) {
    if (remark == null || remark.isEmpty) {
      return this;
    }
    return copyWith(
      content: '$content\n\n---Remark---\n$remark',
      remark: remark,
    );
  }

  SavePayload copyWith({
    String? title,
    String? content,
    List<String>? tags,
    String? remark,
    String? sourceType,
  }) {
    return SavePayload(
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      remark: remark ?? this.remark,
      sourceType: sourceType ?? this.sourceType,
    );
  }

  @override
  String toString() {
    return 'SavePayload(title: "$title", contentLength: ${content.length}, '
        'tags: ${tags.length}, sourceType: $sourceType)';
  }
}

/// Save callback signature.
typedef SaveCallback = Future<bool> Function(
    SavePayload payload, SaveContext context);

/// Save service that centralizes persistence logic for all trigger types.
class SummarySaveService {
  static final SummarySaveService _instance = SummarySaveService._internal();
  static const Duration _rapidDuplicateWindow = Duration(seconds: 30);
  factory SummarySaveService() => _instance;
  SummarySaveService._internal();

  /// Pre-save hooks.
  final List<SaveCallback> _beforeSaveHooks = [];

  /// Post-save hooks.
  final List<
          void Function(SavePayload payload, SaveContext context, bool success)>
      _afterSaveHooks = [];
  final Map<String, DateTime> _recentSaveFingerprints = <String, DateTime>{};

  /// Register a before-save hook.
  void registerBeforeSave(SaveCallback callback) {
    _beforeSaveHooks.add(callback);
    debugPrint('🔗 [SummarySaveService] Registered before-save hook');
  }

  /// Register an after-save hook.
  void registerAfterSave(
      void Function(SavePayload payload, SaveContext context, bool success)
          callback) {
    _afterSaveHooks.add(callback);
    debugPrint('🔗 [SummarySaveService] Registered after-save hook');
  }

  /// Execute the save flow.
  ///
  /// [payload] Data to persist.
  /// [context] Save context.
  /// [showUI] Whether the caller should show the save page.
  ///
  /// Returns true when the save flow completes successfully.
  Future<bool> save({
    required SavePayload payload,
    required SaveContext context,
    bool showUI = true,
  }) async {
    debugPrint('💾 [SummarySaveService] Starting summary save');
    debugPrint('  Trigger type: ${context.triggerType}');
    debugPrint('  Source type: ${payload.sourceType}');
    debugPrint('  Show UI: $showUI');

    bool saveSuccess = false;

    try {
      // Run before-save hooks.
      for (final hook in _beforeSaveHooks) {
        final shouldContinue = await hook(payload, context);
        if (!shouldContinue) {
          debugPrint('⚠️ [SummarySaveService] Save was interrupted by a hook');
          return false;
        }
      }

      if (showUI) {
        // Route handling stays with the caller when UI is required.
        debugPrint(
          '📱 [SummarySaveService] UI is required, returning control to the caller for routing',
        );
        saveSuccess = true;
      } else {
        // Silent save writes directly through the DDD use cases.
        debugPrint('🤫 [SummarySaveService] Running silent save');

        // Convert the payload into a SummaryEntity.
        final summary = await _payloadToSummaryEntity(payload, context);
        if (_isRapidDuplicate(summary)) {
          debugPrint(
            '♻️ [SummarySaveService] Detected a rapid duplicate save and skipped persistence',
          );
          saveSuccess = true;
          return true;
        }

        // Persist through the use-case layer.
        final useCases = sl<SummaryUseCases>();
        if (summary.type == MemoryType.session) {
          await useCases.addSessionMemory(summary);
        } else {
          await useCases.addFactSummary(summary);
        }
        _rememberSaveFingerprint(summary);

        debugPrint(
            '✅ [SummarySaveService] Silent save succeeded: ${summary.id}, topic: "${summary.topic}"');
        saveSuccess = true;
      }

      debugPrint('✅ [SummarySaveService] Save flow completed');
    } catch (e) {
      debugPrint('❌ [SummarySaveService] Save failed: $e');
      saveSuccess = false;
    } finally {
      // Run post-save hooks regardless of outcome.
      for (final hook in _afterSaveHooks) {
        try {
          hook(payload, context, saveSuccess);
        } catch (e) {
          debugPrint('⚠️ [SummarySaveService] Post-save hook failed: $e');
        }
      }
    }

    return saveSuccess;
  }

  /// Clear all hooks, mainly for tests or resets.
  void clearHooks() {
    _beforeSaveHooks.clear();
    _afterSaveHooks.clear();
    _recentSaveFingerprints.clear();
    debugPrint('🧹 [SummarySaveService] Cleared all hooks');
  }

  /// Convert a SavePayload into a SummaryEntity.
  Future<SummaryEntity> _payloadToSummaryEntity(
    SavePayload payload,
    SaveContext context,
  ) async {
    final memoryType = switch (context.triggerType) {
      SaveTriggerType.quickAction => MemoryType.session,
      SaveTriggerType.gesture => MemoryType.session,
      SaveTriggerType.voice => MemoryType.session,
      _ => MemoryType.fact,
    };

    // ✅ 关键优化：当 title 为空时，从内容生成临时标题，避免使用 "Untitled" 占位符
    final String effectiveTitle;
    if (payload.title.isNotEmpty) {
      effectiveTitle = payload.title;
    } else {
      // 从内容生成临时标题（后续会被 _enhanceWithStructuredTitle 优化）
      effectiveTitle = SummaryTextUtils.generateTitle(payload.content);
    }

    return SummaryEntity.create(
      title: effectiveTitle,
      content: payload.content,
      tags: payload.tags,
      source: '${payload.sourceType}_${context.triggerType.name}',
      type: memoryType,
    );
  }

  bool _isRapidDuplicate(SummaryEntity summary) {
    _pruneRecentFingerprints();
    final fingerprint = _buildFingerprint(summary);
    final lastSavedAt = _recentSaveFingerprints[fingerprint];
    if (lastSavedAt == null) {
      return false;
    }
    return DateTime.now().difference(lastSavedAt) <= _rapidDuplicateWindow;
  }

  void _rememberSaveFingerprint(SummaryEntity summary) {
    _pruneRecentFingerprints();
    _recentSaveFingerprints[_buildFingerprint(summary)] = DateTime.now();
  }

  void _pruneRecentFingerprints() {
    final now = DateTime.now();
    _recentSaveFingerprints.removeWhere(
      (_, savedAt) => now.difference(savedAt) > _rapidDuplicateWindow,
    );
  }

  String _buildFingerprint(SummaryEntity summary) {
    final normalizedTitle =
        summary.title.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalizedContent =
        summary.content.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    return '$normalizedTitle::$normalizedContent::${summary.type.name}';
  }
}
