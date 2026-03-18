import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/features/app_whitelist/domain/providers/app_whitelist_provider.dart';
import 'package:local_vault/features/app_whitelist/models/app_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('local_vault/apps');
  final calls = <MethodCall>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getInstalledApps') {
        return <Object?>[];
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loads empty whitelist and syncs empty packages to native', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final whitelist = await _waitForWhitelist(container);

    expect(whitelist, isEmpty);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'setWhitelist');
    expect((calls.single.arguments as Map)['packages'], isEmpty);
  });

  test('loads saved whitelist and forwards package names to native', () async {
    SharedPreferences.setMockInitialValues({
      'app_whitelist': [
        jsonEncode({
          'packageName': 'com.android.chrome',
          'appName': 'Chrome',
          'icon': null,
        }),
        jsonEncode({
          'packageName': 'com.tencent.mm',
          'appName': 'WeChat',
          'icon': null,
        }),
      ],
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final whitelist = await _waitForWhitelist(container);

    expect(
      whitelist.map((app) => app.packageName),
      ['com.android.chrome', 'com.tencent.mm'],
    );
    expect(calls, hasLength(1));
    expect(calls.single.method, 'setWhitelist');
    expect((calls.single.arguments as Map)['packages'], [
      'com.android.chrome',
      'com.tencent.mm',
    ]);
  });

  test('toggleApp persists whitelist and re-syncs native packages', () async {
    final existingApp = AppInfo(
      packageName: 'com.android.chrome',
      appName: 'Chrome',
    );
    final newApp = AppInfo(
      packageName: 'com.tencent.mm',
      appName: 'WeChat',
    );

    SharedPreferences.setMockInitialValues({
      'app_whitelist': [
        jsonEncode(existingApp.toJson()),
      ],
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _waitForWhitelist(container);
    calls.clear();

    await container.read(appWhitelistProvider.notifier).toggleApp(newApp);

    final whitelist = container.read(appWhitelistProvider);
    expect(whitelist.hasValue, isTrue);
    expect(
      whitelist.requireValue.map((app) => app.packageName),
      ['com.android.chrome', 'com.tencent.mm'],
    );

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('app_whitelist');
    expect(stored, isNotNull);
    expect(stored, hasLength(2));

    expect(calls, hasLength(1));
    expect(calls.single.method, 'setWhitelist');
    expect((calls.single.arguments as Map)['packages'], [
      'com.android.chrome',
      'com.tencent.mm',
    ]);
  });

  test('clearWhitelist removes stored values and syncs empty native list',
      () async {
    SharedPreferences.setMockInitialValues({
      'app_whitelist': [
        jsonEncode({
          'packageName': 'com.android.chrome',
          'appName': 'Chrome',
          'icon': null,
        }),
      ],
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _waitForWhitelist(container);
    calls.clear();

    await container.read(appWhitelistProvider.notifier).clearWhitelist();

    final whitelist = container.read(appWhitelistProvider);
    expect(whitelist.hasValue, isTrue);
    expect(whitelist.requireValue, isEmpty);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('app_whitelist'), isNull);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'setWhitelist');
    expect((calls.single.arguments as Map)['packages'], isEmpty);
  });
}

Future<List<AppInfo>> _waitForWhitelist(ProviderContainer container) async {
  for (var i = 0; i < 20; i++) {
    final state = container.read(appWhitelistProvider);
    if (state.hasValue) {
      return state.requireValue;
    }
    await Future<void>.delayed(Duration.zero);
  }

  fail('appWhitelistProvider did not resolve to AsyncData');
}
