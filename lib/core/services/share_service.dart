import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_vault/core/services/save_coordinator.dart';

/// Shared text model.
class SharedText {
  final String text;
  final DateTime timestamp;
  final String source;

  SharedText({
    required this.text,
    required this.timestamp,
    this.source = 'unknown',
  });

  @override
  String toString() =>
      'SharedText(text: ${text.substring(0, text.length.clamp(0, 50))}..., timestamp: $timestamp, source: $source)';
}

/// Shared image model.
class SharedImage {
  final List<String> uris;
  final DateTime timestamp;
  final String type; // 'single' or 'multiple'

  SharedImage({
    required this.uris,
    required this.timestamp,
    required this.type,
  });

  @override
  String toString() =>
      'SharedImage(uris: ${uris.length} images, type: $type, timestamp: $timestamp)';
}

/// Share service implemented as a singleton.
class ShareService {
  static final ShareService _instance = ShareService._internal();

  factory ShareService() => _instance;

  ShareService._internal();

  static const MethodChannel _channel = MethodChannel('local_vault/share');

  final StreamController<SharedText> _shareStreamController =
      StreamController<SharedText>.broadcast();

  final StreamController<SharedImage> _imageStreamController =
      StreamController<SharedImage>.broadcast();

  /// Stream of shared text events.
  Stream<SharedText> get shareStream => _shareStreamController.stream;

  /// Stream of shared image events.
  Stream<SharedImage> get imageStream => _imageStreamController.stream;

  bool _isInitialized = false;

  /// Initialize the share service.
  void initialize() {
    if (_isInitialized) {
      debugPrint('⚠️ [ShareService] Already initialized. Skipping');
      return;
    }

    debugPrint('🔧 [ShareService] Initializing...');
    _isInitialized = true;

    // Register the MethodChannel listener.
    _channel.setMethodCallHandler(_handleMethodCall);

    debugPrint('✅ [ShareService] Initialization complete');
  }

  /// Handle method calls from the native layer.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onShareReceived':
        final text = call.arguments as String?;
        if (text != null && text.isNotEmpty) {
          debugPrint(
            '📥 [ShareService] Received shared text: '
            '${text.substring(0, text.length.clamp(0, 50))}...',
          );
          _shareStreamController.add(SharedText(
            text: text,
            timestamp: DateTime.now(),
            source: 'native_push',
          ));
        }
        break;

      case 'onImageReceived':
        final args = call.arguments as Map<dynamic, dynamic>?;
        if (args != null) {
          final type = args['type'] as String? ?? 'single';
          final uris = <String>[];

          if (type == 'single') {
            final uri = args['uri'] as String?;
            if (uri != null) uris.add(uri);
          } else {
            final uriList = args['uris'] as List<dynamic>?;
            if (uriList != null) {
              uris.addAll(uriList.map((u) => u as String));
            }
          }

          if (uris.isNotEmpty) {
            debugPrint(
              '🖼️ [ShareService] Received ${type == 'single' ? 'single' : 'multiple'} image share: ${uris.length} image(s)',
            );
            _imageStreamController.add(SharedImage(
              uris: uris,
              timestamp: DateTime.now(),
              type: type,
            ));
          }
        }
        break;

      case 'onQuickSaveRequested':
        // Handle quick-save requests from tiles or gestures.
        final clipboardText = call.arguments as String?;
        debugPrint('⚡ [ShareService] Received quick-save request');
        if (clipboardText != null && clipboardText.isNotEmpty) {
          debugPrint(
            '📋 [ShareService] Clipboard content length: ${clipboardText.length}',
          );
          debugPrint(
            '📋 [ShareService] Preview: '
            '${clipboardText.substring(0, clipboardText.length.clamp(0, 100))}${clipboardText.length > 100 ? '...' : ''}',
          );
          // Push directly to the stream listeners.
          debugPrint('📤 [ShareService] Pushing event to the stream...');
          _shareStreamController.add(SharedText(
            text: clipboardText,
            timestamp: DateTime.now(),
            source: 'quick_save',
          ));
          debugPrint('✅ [ShareService] Event pushed to the stream');
        } else {
          debugPrint('⚠️ [ShareService] Clipboard is empty');
        }
        break;

      case 'saveFromClipboard':
        // Handle silent saves invoked directly by QuickSaveActivity.
        final clipboardText = call.arguments as String?;
        debugPrint(
          '🔇 [ShareService] Received silent save request. Will save directly to the database',
        );
        if (clipboardText != null && clipboardText.isNotEmpty) {
          debugPrint(
            '📋 [ShareService] Clipboard content length: ${clipboardText.length}',
          );
          debugPrint(
            '📋 [ShareService] Preview: '
            '${clipboardText.substring(0, clipboardText.length.clamp(0, 100))}${clipboardText.length > 100 ? '...' : ''}',
          );
          _silentSave(clipboardText);
        } else {
          debugPrint('⚠️ [ShareService] Clipboard is empty');
        }
        break;

      default:
        debugPrint('⚠️ [ShareService] Unknown method call: ${call.method}');
    }
  }

  /// Pull pending shared text from the native side if available.
  Future<String?> getPendingShareText() async {
    try {
      debugPrint('🔍 [ShareService] Fetching pending shared text...');
      final text = await _channel.invokeMethod<String>('getPendingShareText');
      if (text != null && text.isNotEmpty) {
        debugPrint(
          '📥 [ShareService] Pulled shared text: '
          '${text.substring(0, text.length.clamp(0, 50))}...',
        );

        // Mirror the pulled text into the stream as well.
        _shareStreamController.add(SharedText(
          text: text,
          timestamp: DateTime.now(),
          source: 'flutter_pull',
        ));
      }
      return text;
    } on MissingPluginException catch (e) {
      debugPrint(
        '⚠️ [ShareService] Native getPendingShareText is not implemented. Skipping: $e',
      );
      return null;
    } on PlatformException catch (e) {
      debugPrint('❌ [ShareService] Failed to get shared text: ${e.message}');
      return null;
    } catch (e) {
      debugPrint(
        '⚠️ [ShareService] Unexpected error while fetching shared text: $e',
      );
      return null;
    }
  }

  /// Reset share state and clear any cached native state.
  Future<void> reset() async {
    try {
      await _channel.invokeMethod('reset');
      debugPrint('✅ [ShareService] Share state reset');
    } on MissingPluginException catch (e) {
      debugPrint(
          '⚠️ [ShareService] Native reset is not implemented. Skipping: $e');
    } on PlatformException catch (e) {
      debugPrint('❌ [ShareService] Reset failed: ${e.message}');
    } catch (e) {
      debugPrint('⚠️ [ShareService] Unexpected error during reset: $e');
    }
  }

  /// Release resources owned by this service.
  void dispose() {
    _shareStreamController.close();
    _imageStreamController.close();
    _isInitialized = false;
    debugPrint('🗑️ [ShareService] Resources released');
  }

  /// Perform a silent save without opening UI.
  Future<void> _silentSave(String content) async {
    try {
      debugPrint('💾 [ShareService] Starting silent database save...');
      debugPrint(
        '🧠 [ShareService] Using the shortcut save path to optimize titles and tags automatically',
      );

      final success = await SaveCoordinator().handleSilentShortcutSave(
        content: content,
        actionId: SaveCoordinator.tileShortcutActionId,
      );

      if (success) {
        debugPrint('✅ [ShareService] Silent save succeeded');
      } else {
        debugPrint('❌ [ShareService] Silent save failed');
      }
    } catch (e) {
      debugPrint('❌ [ShareService] Silent save threw an error: $e');
    }
  }
}
