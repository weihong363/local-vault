import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_vault/l10n/app_localizations.dart';

class AppPermissionManager {
  AppPermissionManager._();

  static const MethodChannel _overlayChannel =
      MethodChannel('local_vault/floating_window');

  /// Check overlay permission
  static Future<bool> checkOverlayPermission() async {
    try {
      final result =
          await _overlayChannel.invokeMethod<bool>('checkOverlayPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request overlay permission
  static Future<void> requestOverlayPermission() async {
    try {
      await _overlayChannel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      rethrow;
    }
  }

  /// Check usage stats permission
  static Future<bool> checkUsageStatsPermission() async {
    try {
      // Call native code via MethodChannel to check
      const MethodChannel channel = MethodChannel('local_vault/permissions');
      final result =
          await channel.invokeMethod<bool>('checkUsageStatsPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request usage stats permission
  static Future<bool> requestUsageStatsPermission() async {
    try {
      // Call native code via MethodChannel to open settings
      const MethodChannel channel = MethodChannel('local_vault/permissions');
      await channel.invokeMethod('requestUsageStatsPermission');
      // Wait and check again after user returns
      await Future.delayed(const Duration(seconds: 2));
      return await checkUsageStatsPermission();
    } catch (e) {
      return false;
    }
  }

  /// Check all required permissions
  static Future<Map<String, bool>> checkAllPermissions() async {
    final overlayGranted = await checkOverlayPermission();
    final usageStatsGranted = await checkUsageStatsPermission();

    return {
      'overlay': overlayGranted,
      'usage_stats': usageStatsGranted,
      'all': overlayGranted && usageStatsGranted,
    };
  }

  /// Request all required permissions
  static Future<bool> requestAllPermissions() async {
    // Request overlay permission
    await requestOverlayPermission();
    await Future.delayed(const Duration(milliseconds: 500));

    // Check usage stats permission, request if not granted
    final usageStatsGranted = await checkUsageStatsPermission();
    if (!usageStatsGranted) {
      // User may have already authorized in settings page, wait a bit and check again
      await Future.delayed(const Duration(seconds: 1));
      final grantedAfterDelay = await checkUsageStatsPermission();
      if (!grantedAfterDelay) {
        // Still no permission, user needs to manually go to settings page
        return false;
      }
    }

    final overlayGranted = await checkOverlayPermission();

    return overlayGranted && usageStatsGranted;
  }

  /// Show permission explanation dialog
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
