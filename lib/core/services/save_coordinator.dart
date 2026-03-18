import 'package:flutter/foundation.dart';
import 'package:local_vault/core/services/summary_save_service.dart';

/// Summary save coordinator that routes requests from multiple trigger sources.
///
/// This class acts as a Facade to simplify client-side save calls.
class SaveCoordinator {
  static final SaveCoordinator _instance = SaveCoordinator._internal();
  static const String clipboardShortcutActionId = 'quick_save_from_clipboard';
  static const String shareStreamShortcutActionId =
      'quick_save_from_share_stream';
  static const String tileShortcutActionId = 'silent_save_from_tile';

  factory SaveCoordinator() => _instance;

  SaveCoordinator._internal();

  final SummarySaveService _saveService = SummarySaveService();

  /// Handle a save triggered from a share action.
  ///
  /// [text] Shared text content.
  /// [metadata] Additional metadata such as source app information.
  Future<bool> handleShare({
    required String text,
    Map<String, dynamic>? metadata,
  }) async {
    debugPrint('📤 [SaveCoordinator] Handling share-triggered save');

    final payload = SavePayload.fromShare(text);
    final context = SaveContext.share(metadata: metadata);

    return await _saveService.save(
      payload: payload,
      context: context,
      showUI: true,
    );
  }

  /// Handle a save triggered by a gesture.
  ///
  /// [content] Content to save, usually from clipboard or OCR.
  /// [tapCount] Number of taps detected.
  /// [packageName] Package name of the triggering app.
  Future<bool> handleGesture({
    required String content,
    int? tapCount,
    String? packageName,
  }) async {
    debugPrint('👆 [SaveCoordinator] Handling gesture-triggered save');

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

  /// Handle a save triggered by a quick action.
  ///
  /// [content] Content to save.
  /// [actionId] Quick action identifier.
  Future<bool> handleQuickAction({
    required String content,
    String? actionId,
  }) async {
    debugPrint('⚡ [SaveCoordinator] Handling quick-action save');
    debugPrint(
      '🧠 [SaveCoordinator] Silent shortcut saves will optimize titles and tags automatically',
    );

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

  /// Handle a silent save triggered from a shortcut.
  ///
  /// Uses the same quick-action silent-save path so titles and tags
  /// are completed consistently.
  Future<bool> handleSilentShortcutSave({
    required String content,
    required String actionId,
  }) async {
    debugPrint('🤫 [SaveCoordinator] Handling silent shortcut save');
    return handleQuickAction(
      content: content,
      actionId: actionId,
    );
  }

  /// Handle a save triggered by voice input.
  ///
  /// [content] Content to save from voice recognition.
  /// [voiceCommand] Original voice command text.
  Future<bool> handleVoice({
    required String content,
    String? voiceCommand,
  }) async {
    debugPrint('🎤 [SaveCoordinator] Handling voice-triggered save');

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

  /// Handle a manual save triggered inside the app UI.
  ///
  /// [title] Title.
  /// [content] Content.
  /// [tags] List of tags.
  /// [remark] Optional remark.
  Future<bool> handleManual({
    required String title,
    required String content,
    List<String> tags = const [],
    String? remark,
  }) async {
    debugPrint('✋ [SaveCoordinator] Handling manual save');

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

  /// Register a before-save hook.
  void registerBeforeSave(
      Future<bool> Function(SavePayload payload, SaveContext context)
          callback) {
    _saveService.registerBeforeSave(callback);
  }

  /// Register an after-save hook.
  void registerAfterSave(
      void Function(SavePayload payload, SaveContext context, bool success)
          callback) {
    _saveService.registerAfterSave(callback);
  }
}
