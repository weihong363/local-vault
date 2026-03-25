import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/features/gesture_config/domain/providers/gesture_config_provider.dart';
import 'package:local_vault/features/gesture_config/models/gesture_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('local_vault/gesture_config');
  final calls = <MethodCall>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loads default gesture configs and syncs them to native', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final configs = await _waitForConfigs(container);

    expect(configs, hasLength(2));
    expect(configs[0].gestureType, GestureType.tap2);
    expect(configs[0].action, GestureAction.openTemplates);
    expect(configs[0].name, 'tap_2');
    expect(configs[1].gestureType, GestureType.tap3);
    expect(configs[1].action, GestureAction.openSummaries);
    expect(configs[1].name, 'tap_3');

    expect(calls.map((call) => call.method), [
      'setTapGestureConfig',
      'setTapGestureConfig',
    ]);
    expect((calls[0].arguments as Map)['tapCount'], 2);
    expect((calls[0].arguments as Map)['actionIndex'], 0);
    expect((calls[1].arguments as Map)['tapCount'], 3);
    expect((calls[1].arguments as Map)['actionIndex'], 2);
  });

  test('normalizes legacy gesture configs and rewrites stored data', () async {
    SharedPreferences.setMockInitialValues({
      'gesture_configs': [
        jsonEncode({
          'id': 1,
          'name': '轻点 2 下',
          'gestureType': 0,
          'fingerCount': 2,
          'action': 2,
          'readOnly': false,
        }),
        jsonEncode({
          'id': 2,
          'name': '轻点 3 下',
          'gestureType': 1,
          'fingerCount': 3,
          'action': 0,
          'readOnly': false,
        }),
        jsonEncode({
          'id': 3,
          'name': '保存摘要',
          'gestureType': 2,
          'fingerCount': 1,
          'action': 1,
          'readOnly': true,
        }),
      ],
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final configs = await _waitForConfigs(container);

    expect(configs, hasLength(2));
    expect(configs[0].action, GestureAction.openSummaries);
    expect(configs[1].action, GestureAction.openTemplates);

    final prefs = await SharedPreferences.getInstance();
    final storedConfigs = prefs.getStringList('gesture_configs');
    expect(storedConfigs, isNotNull);
    expect(storedConfigs, hasLength(2));

    final decodedConfigs = storedConfigs!
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList(growable: false);
    expect(decodedConfigs[0]['name'], 'tap_2');
    expect(decodedConfigs[1]['name'], 'tap_3');

    expect((calls[0].arguments as Map)['tapCount'], 2);
    expect((calls[0].arguments as Map)['actionIndex'], 2);
    expect((calls[1].arguments as Map)['tapCount'], 3);
    expect((calls[1].arguments as Map)['actionIndex'], 0);
  });

  test('updateConfig re-syncs the full tap mapping to native', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final configs = await _waitForConfigs(container);
    calls.clear();

    await container.read(gestureConfigProvider.notifier).updateConfig(
          configs.first.copyWith(action: GestureAction.saveSummary),
        );

    final updated = container.read(gestureConfigProvider);
    expect(updated.hasValue, isTrue);
    expect(updated.requireValue.first.action, GestureAction.saveSummary);

    expect(calls, hasLength(2));
    expect((calls[0].arguments as Map)['tapCount'], 2);
    expect((calls[0].arguments as Map)['actionIndex'], 1);
    expect((calls[1].arguments as Map)['tapCount'], 3);
    expect((calls[1].arguments as Map)['actionIndex'], 2);
  });
}

Future<List<GestureConfig>> _waitForConfigs(ProviderContainer container) async {
  for (var i = 0; i < 20; i++) {
    final state = container.read(gestureConfigProvider);
    if (state.hasValue) {
      return state.requireValue;
    }
    await Future<void>.delayed(Duration.zero);
  }

  fail('gestureConfigProvider did not resolve to AsyncData');
}
