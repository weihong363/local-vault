import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:local_vault/core/services/gesture_diagnostics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const floatingChannel = MethodChannel('local_vault/floating_window');
  const permissionsChannel = MethodChannel('local_vault/permissions');
  const gestureChannel = MethodChannel('local_vault/gesture_config');
  const appsChannel = MethodChannel('local_vault/apps');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(floatingChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(gestureChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appsChannel, null);
  });

  test('collectSnapshot returns gesture diagnostics from settings and channels',
      () async {
    SharedPreferences.setMockInitialValues({
      'floating_window_enabled': true,
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(floatingChannel, (call) async {
      switch (call.method) {
        case 'checkOverlayPermission':
          return true;
        case 'isFloatingServiceRunning':
          return true;
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionsChannel, (call) async {
      if (call.method == 'checkUsageStatsPermission') {
        return true;
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(gestureChannel, (call) async {
      if (call.method == 'getTapGestureConfig') {
        final tapCount = (call.arguments as Map)['tapCount'] as int;
        return tapCount == 2 ? 0 : 2;
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appsChannel, (call) async {
      if (call.method == 'getWhitelistPackages') {
        return <String>['com.android.chrome', 'com.tencent.mm'];
      }
      return null;
    });

    final service = GestureDiagnosticsService(
      settingsService: AppSettingsService(),
    );

    final snapshot = await service.collectSnapshot();

    expect(snapshot.floatingWindowEnabled, isTrue);
    expect(snapshot.overlayPermissionGranted, isTrue);
    expect(snapshot.usageStatsPermissionGranted, isTrue);
    expect(snapshot.floatingServiceRunning, isTrue);
    expect(snapshot.nativeTap2ActionIndex, 0);
    expect(snapshot.nativeTap3ActionIndex, 2);
    expect(snapshot.nativeWhitelistPackages, [
      'com.android.chrome',
      'com.tencent.mm',
    ]);
  });

  test(
      'collectSnapshot degrades gracefully when native queries are unavailable',
      () async {
    SharedPreferences.setMockInitialValues({
      'floating_window_enabled': false,
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(floatingChannel, (call) async {
      if (call.method == 'checkOverlayPermission') {
        throw PlatformException(code: 'UNAVAILABLE');
      }
      throw MissingPluginException();
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionsChannel, (call) async {
      throw MissingPluginException();
    });

    final service = GestureDiagnosticsService(
      settingsService: AppSettingsService(),
    );

    final snapshot = await service.collectSnapshot();

    expect(snapshot.floatingWindowEnabled, isFalse);
    expect(snapshot.overlayPermissionGranted, isFalse);
    expect(snapshot.usageStatsPermissionGranted, isFalse);
    expect(snapshot.floatingServiceRunning, isNull);
    expect(snapshot.nativeTap2ActionIndex, isNull);
    expect(snapshot.nativeTap3ActionIndex, isNull);
    expect(snapshot.nativeWhitelistPackages, isNull);
  });
}
