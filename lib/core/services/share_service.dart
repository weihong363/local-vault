import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 分享文本数据模型
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
  String toString() => 'SharedText(text: ${text.substring(0, text.length.clamp(0, 50))}..., timestamp: $timestamp, source: $source)';
}

/// 分享图片数据模型
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
  String toString() => 'SharedImage(uris: ${uris.length} images, type: $type, timestamp: $timestamp)';
}

/// 分享服务 - 单例模式
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  static const MethodChannel _channel = MethodChannel('local_vault/share');
  
  final StreamController<SharedText> _shareStreamController = 
      StreamController<SharedText>.broadcast();
  
  final StreamController<SharedImage> _imageStreamController = 
      StreamController<SharedImage>.broadcast();
  
  /// 获取分享文本流
  Stream<SharedText> get shareStream => _shareStreamController.stream;
  
  /// 获取分享图片流
  Stream<SharedImage> get imageStream => _imageStreamController.stream;
  
  bool _isInitialized = false;

  /// 初始化分享服务
  void initialize() {
    if (_isInitialized) {
      debugPrint('⚠️ [ShareService] 已经初始化过，跳过');
      return;
    }

    debugPrint('🔧 [ShareService] 开始初始化...');
    _isInitialized = true;
    
    // 设置 MethodChannel 监听器
    _channel.setMethodCallHandler(_handleMethodCall);
    
    debugPrint('✅ [ShareService] 初始化完成');
  }

  /// 处理来自原生端的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onShareReceived':
        final text = call.arguments as String?;
        if (text != null && text.isNotEmpty) {
          debugPrint('📥 [ShareService] 收到分享文本：${text.substring(0, text.length.clamp(0, 50))}...');
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
            debugPrint('🖼️ [ShareService] 收到${type == 'single' ? '单张' : '多张'}图片分享：${uris.length} 张');
            _imageStreamController.add(SharedImage(
              uris: uris,
              timestamp: DateTime.now(),
              type: type,
            ));
          }
        }
        break;
      
      default:
        debugPrint('⚠️ [ShareService] 未知的方法调用：${call.method}');
    }
  }

  /// 获取待处理的分享文本（被动拉取模式）
  Future<String?> getPendingShareText() async {
    try {
      final text = await _channel.invokeMethod<String>('getPendingShareText');
      if (text != null && text.isNotEmpty) {
        debugPrint('📥 [ShareService] 被动拉取到分享文本：${text.substring(0, text.length.clamp(0, 50))}...');
        
        // 同时也推送到流中
        _shareStreamController.add(SharedText(
          text: text,
          timestamp: DateTime.now(),
          source: 'flutter_pull',
        ));
      }
      return text;
    } on PlatformException catch (e) {
      debugPrint('❌ [ShareService] 获取分享文本失败：${e.message}');
      return null;
    }
  }

  /// 重置分享状态（清除缓存）
  Future<void> reset() async {
    try {
      await _channel.invokeMethod('reset');
      debugPrint('✅ [ShareService] 已重置分享状态');
    } on PlatformException catch (e) {
      debugPrint('❌ [ShareService] 重置失败：${e.message}');
    }
  }

  /// 释放资源
  void dispose() {
    _shareStreamController.close();
    _imageStreamController.close();
    _isInitialized = false;
    debugPrint('🗑️ [ShareService] 已释放资源');
  }
}
