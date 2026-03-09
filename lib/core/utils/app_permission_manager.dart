import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissionManager {
  AppPermissionManager._();

  static const MethodChannel _overlayChannel = MethodChannel('local_vault/floating_window');

  /// 检查悬浮窗权限
  static Future<bool> checkOverlayPermission() async {
    try {
      final result = await _overlayChannel.invokeMethod<bool>('checkOverlayPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 请求悬浮窗权限
  static Future<void> requestOverlayPermission() async {
    try {
      await _overlayChannel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      rethrow;
    }
  }

  /// 检查使用情况统计权限
  static Future<bool> checkUsageStatsPermission() async {
    try {
      // 通过 MethodChannel 调用原生代码检查
      const MethodChannel channel = MethodChannel('local_vault/permissions');
      final result = await channel.invokeMethod<bool>('checkUsageStatsPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 请求使用情况统计权限
  static Future<bool> requestUsageStatsPermission() async {
    try {
      // 通过 MethodChannel 调用原生代码打开设置
      const MethodChannel channel = MethodChannel('local_vault/permissions');
      await channel.invokeMethod('requestUsageStatsPermission');
      // 等待用户返回后再次检查
      await Future.delayed(const Duration(seconds: 2));
      return await checkUsageStatsPermission();
    } catch (e) {
      return false;
    }
  }

  /// 检查所有必需的权限
  static Future<Map<String, bool>> checkAllPermissions() async {
    final overlayGranted = await checkOverlayPermission();
    final usageStatsGranted = await checkUsageStatsPermission();
    
    return {
      'overlay': overlayGranted,
      'usage_stats': usageStatsGranted,
      'all': overlayGranted && usageStatsGranted,
    };
  }

  /// 请求所有必需的权限
  static Future<bool> requestAllPermissions() async {
    // 请求悬浮窗权限
    await requestOverlayPermission();
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 请求使用统计权限
    final usageStatsGranted = await requestUsageStatsPermission();
    
    final overlayGranted = await checkOverlayPermission();
    
    return overlayGranted && usageStatsGranted;
  }

  /// 显示权限说明对话框
  static void showPermissionExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要权限'),
        content: const Text(
          '为了让手势唤醒功能正常工作，需要以下权限：\n\n'
          '1. **悬浮窗权限**: 用于在其他应用上层显示手势检测区域\n'
          '2. **使用情况统计权限**: 用于检测当前正在使用的应用，以便在白名单应用中显示手势区域\n\n'
          '请在接下来的界面中授予这些权限。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              requestAllPermissions();
            },
            child: const Text('去授权'),
          ),
        ],
      ),
    );
  }
}
