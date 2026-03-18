import 'package:flutter/foundation.dart';
import 'package:local_vault/core/services/summary_save_service.dart';

/// 摘要保存协调器 - 统一处理来自不同触发源的保存请求
///
/// 这个类充当门面模式（Facade Pattern），简化客户端调用
class SaveCoordinator {
  static final SaveCoordinator _instance = SaveCoordinator._internal();
  static const String clipboardShortcutActionId = 'quick_save_from_clipboard';
  static const String shareStreamShortcutActionId =
      'quick_save_from_share_stream';
  static const String tileShortcutActionId = 'silent_save_from_tile';

  factory SaveCoordinator() => _instance;

  SaveCoordinator._internal();

  final SummarySaveService _saveService = SummarySaveService();

  /// 处理分享触发的保存
  ///
  /// [text] 分享的文本内容
  /// [metadata] 额外的元数据（如分享来源应用等）
  Future<bool> handleShare({
    required String text,
    Map<String, dynamic>? metadata,
  }) async {
    debugPrint('📤 [SaveCoordinator] 处理分享触发保存');

    final payload = SavePayload.fromShare(text);
    final context = SaveContext.share(metadata: metadata);

    return await _saveService.save(
      payload: payload,
      context: context,
      showUI: true,
    );
  }

  /// 处理手势触发的保存
  ///
  /// [content] 要保存的内容（通常来自剪贴板或 OCR）
  /// [tapCount] 手势敲击次数
  /// [packageName] 触发手势的应用包名
  Future<bool> handleGesture({
    required String content,
    int? tapCount,
    String? packageName,
  }) async {
    debugPrint('👆 [SaveCoordinator] 处理手势触发保存');

    final payload = SavePayload(
      title: '',
      content: content,
      sourceType: 'gesture',
    );

    final context = SaveContext.gesture(
      tapCount: tapCount,
      packageName: packageName,
    );

    return await _saveService.save(
      payload: payload,
      context: context,
      showUI: true,
    );
  }

  /// 处理快捷操作触发的保存
  ///
  /// [content] 要保存的内容
  /// [actionId] 快捷操作的 ID
  Future<bool> handleQuickAction({
    required String content,
    String? actionId,
  }) async {
    debugPrint('⚡ [SaveCoordinator] 处理快捷操作触发保存');
    debugPrint('🧠 [SaveCoordinator] 快捷静默保存将自动优化标题和标签');

    final payload = SavePayload(
      title: '',
      content: content,
      sourceType: 'quick_action',
    );

    final context = SaveContext.quickAction(actionId: actionId);

    return await _saveService.save(
      payload: payload,
      context: context,
      showUI: false,
    );
  }

  /// 处理快捷方式触发的静默保存
  ///
  /// 统一走快捷操作的静默保存链路，确保自动补全标题和标签。
  Future<bool> handleSilentShortcutSave({
    required String content,
    required String actionId,
  }) async {
    debugPrint('🤫 [SaveCoordinator] 处理快捷方式静默保存');
    return handleQuickAction(
      content: content,
      actionId: actionId,
    );
  }

  /// 处理语音触发的保存
  ///
  /// [content] 要保存的内容（来自语音识别）
  /// [voiceCommand] 语音指令原文
  Future<bool> handleVoice({
    required String content,
    String? voiceCommand,
  }) async {
    debugPrint('🎤 [SaveCoordinator] 处理语音触发保存');

    final payload = SavePayload(
      title: '',
      content: content,
      sourceType: 'voice',
    );

    final context = SaveContext.voice(voiceCommand: voiceCommand);

    return await _saveService.save(
      payload: payload,
      context: context,
      showUI: true,
    );
  }

  /// 处理手动触发的保存（应用内按钮）
  ///
  /// [title] 标题
  /// [content] 内容
  /// [tags] 标签列表
  /// [remark] 备注
  Future<bool> handleManual({
    required String title,
    required String content,
    List<String> tags = const [],
    String? remark,
  }) async {
    debugPrint('✋ [SaveCoordinator] 处理手动触发保存');

    final payload = SavePayload(
      title: title,
      content: content,
      tags: tags,
      remark: remark,
      sourceType: 'manual',
    );

    final context = SaveContext.manual(source: 'app_button');

    return await _saveService.save(
      payload: payload,
      context: context,
      showUI: false,
    );
  }

  /// 注册保存前钩子
  void registerBeforeSave(
      Future<bool> Function(SavePayload payload, SaveContext context)
          callback) {
    _saveService.registerBeforeSave(callback);
  }

  /// 注册保存后钩子
  void registerAfterSave(
      void Function(SavePayload payload, SaveContext context, bool success)
          callback) {
    _saveService.registerAfterSave(callback);
  }
}
