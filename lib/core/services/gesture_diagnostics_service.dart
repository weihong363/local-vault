import 'package:flutter/services.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:local_vault/core/utils/app_permission_manager.dart';

class GestureDiagnosticsSnapshot {
  const GestureDiagnosticsSnapshot({
    required this.floatingWindowEnabled,
    required this.overlayPermissionGranted,
    required this.usageStatsPermissionGranted,
    required this.floatingServiceRunning,
    required this.nativeTap2ActionIndex,
    required this.nativeTap3ActionIndex,
    required this.nativeWhitelistPackages,
  });

  final bool floatingWindowEnabled;
  final bool overlayPermissionGranted;
  final bool usageStatsPermissionGranted;
  final bool? floatingServiceRunning;
  final int? nativeTap2ActionIndex;
  final int? nativeTap3ActionIndex;
  final List<String>? nativeWhitelistPackages;
}

class GestureDiagnosticsService {
  GestureDiagnosticsService({
    required AppSettingsService settingsService,
    MethodChannel? floatingChannel,
    MethodChannel? gestureChannel,
    MethodChannel? appsChannel,
  })  : _settingsService = settingsService,
        _floatingChannel = floatingChannel ??
            const MethodChannel('local_vault/floating_window'),
        _gestureChannel =
            gestureChannel ?? const MethodChannel('local_vault/gesture_config'),
        _appsChannel = appsChannel ?? const MethodChannel('local_vault/apps');

  final AppSettingsService _settingsService;
  final MethodChannel _floatingChannel;
  final MethodChannel _gestureChannel;
  final MethodChannel _appsChannel;

  Future<GestureDiagnosticsSnapshot> collectSnapshot() async {
    final floatingWindowEnabled =
        await _settingsService.isFloatingWindowEnabled();
    final overlayPermissionGranted =
        await AppPermissionManager.checkOverlayPermission();
    final usageStatsPermissionGranted =
        await AppPermissionManager.checkUsageStatsPermission();
    final floatingServiceRunning = await _invokeBool(
      _floatingChannel,
      'isFloatingServiceRunning',
    );
    final nativeTap2ActionIndex = await _invokeInt(
      _gestureChannel,
      'getTapGestureConfig',
      const {'tapCount': 2},
    );
    final nativeTap3ActionIndex = await _invokeInt(
      _gestureChannel,
      'getTapGestureConfig',
      const {'tapCount': 3},
    );
    final nativeWhitelistPackages = await _invokeStringList(
      _appsChannel,
      'getWhitelistPackages',
    );

    return GestureDiagnosticsSnapshot(
      floatingWindowEnabled: floatingWindowEnabled,
      overlayPermissionGranted: overlayPermissionGranted,
      usageStatsPermissionGranted: usageStatsPermissionGranted,
      floatingServiceRunning: floatingServiceRunning,
      nativeTap2ActionIndex: nativeTap2ActionIndex,
      nativeTap3ActionIndex: nativeTap3ActionIndex,
      nativeWhitelistPackages: nativeWhitelistPackages,
    );
  }

  Future<bool?> _invokeBool(
    MethodChannel channel,
    String method, [
    Object? arguments,
  ]) async {
    try {
      return await channel.invokeMethod<bool>(method, arguments);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<int?> _invokeInt(
    MethodChannel channel,
    String method, [
    Object? arguments,
  ]) async {
    try {
      return await channel.invokeMethod<int>(method, arguments);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<List<String>?> _invokeStringList(
    MethodChannel channel,
    String method, [
    Object? arguments,
  ]) async {
    try {
      final result =
          await channel.invokeMethod<List<dynamic>>(method, arguments);
      if (result == null) {
        return null;
      }
      return result.whereType<String>().toList(growable: false);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
