import 'package:flutter/services.dart';

class FloatingWindowService {
  static const MethodChannel _channel = MethodChannel('local_vault/floating_window');

  static Future<bool> checkOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkOverlayPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> startFloatingService() async {
    try {
      await _channel.invokeMethod('startFloatingService');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> stopFloatingService() async {
    try {
      await _channel.invokeMethod('stopFloatingService');
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getPendingAction() async {
    try {
      return await _channel.invokeMethod<String>('getPendingAction');
    } catch (e) {
      return null;
    }
  }
}
