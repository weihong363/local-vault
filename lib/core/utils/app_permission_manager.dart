import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_vault/l10n/app_localizations.dart';

class AppPermissionManager {
  AppPermissionManager._();

  static const MethodChannel _overlayChannel =
      MethodChannel('local_vault/floating_window');

  /// 检查悬浮窗权限
  static Future<bool> checkOverlayPermission() async {
    try {
      final result =
          await _overlayChannel.invokeMethod<bool>('checkOverlayPermission');
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
      final result =
          await channel.invokeMethod<bool>('checkUsageStatsPermission');
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

    // 检查使用情况统计权限，如果没有则请求
    final usageStatsGranted = await checkUsageStatsPermission();
    if (!usageStatsGranted) {
      // 用户可能已经在设置页面授权了，等待一下再检查
      await Future.delayed(const Duration(seconds: 1));
      final grantedAfterDelay = await checkUsageStatsPermission();
      if (!grantedAfterDelay) {
        // 仍然没有权限，需要用户手动去设置页面
        return false;
      }
    }

    final overlayGranted = await checkOverlayPermission();

    return overlayGranted && usageStatsGranted;
  }

  /// 显示权限说明对话框
  static void showPermissionExplanation(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.permissionsRequiredTitle),
        content: Text(loc.permissionsRequiredMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancelLabel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              requestAllPermissions();
            },
            child: Text(loc.grantAccessLabel),
          ),
        ],
      ),
    );
  }
}
