import 'package:flutter/foundation.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';
import 'package:local_vault/core/services/summary_metadata_service.dart';

/// 摘要保存触发方式枚举
enum SaveTriggerType {
  share, // 分享触发（系统分享菜单）
  gesture, // 手势触发（背部敲击等）
  quickAction, // 快捷操作（控制中心悬浮球）
  voice, // 语音唤醒
  manual, // 手动触发（应用内按钮）
}

/// 摘要保存上下文信息
class SaveContext {
  /// 触发方式
  final SaveTriggerType triggerType;

  /// 触发来源的详细信息
  final Map<String, dynamic>? metadata;

  /// 时间戳
  final DateTime timestamp;

  SaveContext({
    required this.triggerType,
    this.metadata,
  }) : timestamp = DateTime.now();

  /// 创建分享触发的上下文
  factory SaveContext.share({Map<String, dynamic>? metadata}) {
    return SaveContext(
      triggerType: SaveTriggerType.share,
      metadata: metadata,
    );
  }

  /// 创建手势触发的上下文
  factory SaveContext.gesture({int? tapCount, String? packageName}) {
    return SaveContext(
      triggerType: SaveTriggerType.gesture,
      metadata: {
        if (tapCount != null) 'tapCount': tapCount,
        if (packageName != null) 'packageName': packageName,
      },
    );
  }

  /// 创建快捷操作触发的上下文
  factory SaveContext.quickAction({String? actionId}) {
    return SaveContext(
      triggerType: SaveTriggerType.quickAction,
      metadata: {
        if (actionId != null) 'actionId': actionId,
      },
    );
  }

  /// 创建语音触发的上下文
  factory SaveContext.voice({String? voiceCommand}) {
    return SaveContext(
      triggerType: SaveTriggerType.voice,
      metadata: {
        if (voiceCommand != null) 'voiceCommand': voiceCommand,
      },
    );
  }

  /// 创建手动触发的上下文
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

/// 待保存的摘要数据
class SavePayload {
  /// 标题
  final String title;

  /// 内容
  final String content;

  /// 标签列表
  final List<String> tags;

  /// 备注（可选）
  final String? remark;

  /// 来源类型（用于区分不同的数据来源）
  final String sourceType;

  const SavePayload({
    required this.title,
    required this.content,
    this.tags = const [],
    this.remark,
    this.sourceType = 'manual',
  });

  /// 从分享文本创建 Payload
  factory SavePayload.fromShare(String text) {
    return SavePayload(
      title: '',
      content: text,
      sourceType: 'share',
    );
  }

  /// 从 OCR 识别结果创建 Payload
  factory SavePayload.fromOCR(String recognizedText) {
    return SavePayload(
      title: '',
      content: recognizedText,
      sourceType: 'ocr',
    );
  }

  /// 添加备注到内容中
  SavePayload withRemark(String? remark) {
    if (remark == null || remark.isEmpty) {
      return this;
    }
    return copyWith(
      content: '$content\n\n---备注---\n$remark',
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

/// 保存回调函数类型
typedef SaveCallback = Future<bool> Function(
    SavePayload payload, SaveContext context);

/// 摘要保存服务 - 统一管理不同触发方式的保存逻辑
class SummarySaveService {
  static final SummarySaveService _instance = SummarySaveService._internal();
  static const Duration _rapidDuplicateWindow = Duration(seconds: 30);
  factory SummarySaveService() => _instance;
  SummarySaveService._internal();

  /// 保存前的预处理函数列表
  final List<SaveCallback> _beforeSaveHooks = [];

  /// 保存后的处理函数列表
  final List<
          void Function(SavePayload payload, SaveContext context, bool success)>
      _afterSaveHooks = [];
  final Map<String, DateTime> _recentSaveFingerprints = <String, DateTime>{};

  /// 注册保存前钩子
  void registerBeforeSave(SaveCallback callback) {
    _beforeSaveHooks.add(callback);
    debugPrint('🔗 [SummarySaveService] 注册保存前钩子');
  }

  /// 注册保存后钩子
  void registerAfterSave(
      void Function(SavePayload payload, SaveContext context, bool success)
          callback) {
    _afterSaveHooks.add(callback);
    debugPrint('🔗 [SummarySaveService] 注册保存后钩子');
  }

  /// 执行保存
  ///
  /// [payload] 要保存的数据
  /// [context] 保存上下文
  /// [showUI] 是否显示保存页面（默认 true，如果为 false 则静默保存）
  ///
  /// 返回 true 表示保存成功
  Future<bool> save({
    required SavePayload payload,
    required SaveContext context,
    bool showUI = true,
  }) async {
    debugPrint('💾 [SummarySaveService] 开始保存摘要');
    debugPrint('  触发方式：${context.triggerType}');
    debugPrint('  数据来源：${payload.sourceType}');
    debugPrint('  显示 UI: $showUI');

    bool saveSuccess = false;

    try {
      // 执行保存前钩子
      for (final hook in _beforeSaveHooks) {
        final shouldContinue = await hook(payload, context);
        if (!shouldContinue) {
          debugPrint('⚠️ [SummarySaveService] 保存被钩子中断');
          return false;
        }
      }

      if (showUI) {
        // 需要显示 UI，由上层调用者处理路由
        debugPrint('📱 [SummarySaveService] 需要显示 UI，返回到调用者处理路由');
        saveSuccess = true;
      } else {
        // 静默保存 - 直接保存到数据库（使用新 DDD 架构）
        debugPrint('🤫 [SummarySaveService] 执行静默保存（新 DDD 架构）');

        // 将 Payload 转换为 SummaryEntity
        final summary = await _payloadToSummaryEntity(payload, context);
        if (_isRapidDuplicate(summary)) {
          debugPrint('♻️ [SummarySaveService] 检测到短时间重复保存，跳过落库');
          saveSuccess = true;
          return true;
        }

        // 使用新架构的 UseCases 保存
        final useCases = sl<SummaryUseCases>();
        if (summary.type == MemoryType.session) {
          await useCases.addSessionMemory(summary);
        } else {
          await useCases.addFactSummary(summary);
        }
        _rememberSaveFingerprint(summary);

        debugPrint('✅ [SummarySaveService] 静默保存成功：${summary.id}');
        saveSuccess = true;
      }

      debugPrint('✅ [SummarySaveService] 保存流程完成');
    } catch (e) {
      debugPrint('❌ [SummarySaveService] 保存失败：$e');
      saveSuccess = false;
    } finally {
      // 执行保存后钩子（无论成功与否）
      for (final hook in _afterSaveHooks) {
        try {
          hook(payload, context, saveSuccess);
        } catch (e) {
          debugPrint('⚠️ [SummarySaveService] 保存后钩子执行失败：$e');
        }
      }
    }

    return saveSuccess;
  }

  /// 清除所有钩子（用于测试或重置）
  void clearHooks() {
    _beforeSaveHooks.clear();
    _afterSaveHooks.clear();
    _recentSaveFingerprints.clear();
    debugPrint('🧹 [SummarySaveService] 已清除所有钩子');
  }

  /// 将 SavePayload 转换为 SummaryEntity
  Future<SummaryEntity> _payloadToSummaryEntity(
    SavePayload payload,
    SaveContext context,
  ) async {
    final prepared = await sl<SummaryMetadataService>().prepareForSave(
      title: payload.title,
      content: payload.content,
      tags: payload.tags,
      remark: payload.remark,
    );

    final memoryType = switch (context.triggerType) {
      SaveTriggerType.quickAction => MemoryType.session,
      SaveTriggerType.gesture => MemoryType.session,
      SaveTriggerType.voice => MemoryType.session,
      _ => MemoryType.fact,
    };

    return SummaryEntity.create(
      title: prepared.title,
      content: prepared.content,
      tags: prepared.tags,
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
