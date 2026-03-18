import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/features/gesture_config/models/gesture_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

final gestureConfigProvider = StateNotifierProvider<GestureConfigNotifier,
    AsyncValue<List<GestureConfig>>>((ref) {
  return GestureConfigNotifier();
});

class GestureConfigNotifier
    extends StateNotifier<AsyncValue<List<GestureConfig>>> {
  static const String _prefsKey = 'gesture_configs';

  GestureConfigNotifier() : super(const AsyncLoading()) {
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configsJson = prefs.getStringList(_prefsKey);

      if (configsJson == null || configsJson.isEmpty) {
        final defaultConfigs = GestureConfig.getDefaultConfigs();
        await _saveConfigs(defaultConfigs);
        state = AsyncData(defaultConfigs);
        await _syncToNative();
      } else {
        final loadedConfigs = configsJson.map((json) {
          return GestureConfig.fromJson(
              jsonDecode(json) as Map<String, dynamic>);
        }).toList();
        final normalizedConfigs = _normalizeConfigs(loadedConfigs);
        state = AsyncData(normalizedConfigs);
        if (!_areConfigsEqual(loadedConfigs, normalizedConfigs)) {
          await _saveConfigs(normalizedConfigs);
        }
        await _syncToNative();
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> _saveConfigs(List<GestureConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson =
        configs.map((config) => jsonEncode(config.toJson())).toList();
    await prefs.setStringList(_prefsKey, configsJson);
  }

  Future<void> updateConfig(GestureConfig config) async {
    final currentState = state;
    if (currentState is! AsyncData<List<GestureConfig>>) return;

    final configs =
        currentState.value.map((c) => c.id == config.id ? config : c).toList();
    state = AsyncData(configs);
    await _saveConfigs(configs);
    await _syncToNative();
  }

  Future<void> resetToDefaults() async {
    final defaultConfigs = GestureConfig.getDefaultConfigs();
    state = AsyncData(defaultConfigs);
    await _saveConfigs(defaultConfigs);
    await _syncToNative();
  }

  List<GestureConfig> _normalizeConfigs(List<GestureConfig> configs) {
    final defaults = GestureConfig.getDefaultConfigs();
    final normalized = <GestureType, GestureConfig>{
      for (final config in defaults) config.gestureType: config,
    };

    for (final config in configs) {
      if (config.readOnly) continue;
      if (!normalized.containsKey(config.gestureType)) continue;

      normalized[config.gestureType] = normalized[config.gestureType]!.copyWith(
        action: config.action,
        readOnly: false,
      );
    }

    return defaults
        .map((config) => normalized[config.gestureType] ?? config)
        .toList(growable: false);
  }

  bool _areConfigsEqual(
    List<GestureConfig> left,
    List<GestureConfig> right,
  ) {
    if (left.length != right.length) return false;

    for (var i = 0; i < left.length; i++) {
      final a = left[i];
      final b = right[i];
      if (a.id != b.id ||
          a.name != b.name ||
          a.gestureType != b.gestureType ||
          a.fingerCount != b.fingerCount ||
          a.action != b.action ||
          a.readOnly != b.readOnly) {
        return false;
      }
    }

    return true;
  }

  Future<void> _syncToNative() async {
    final currentState = state;
    if (currentState is! AsyncData<List<GestureConfig>>) return;

    try {
      const MethodChannel channel = MethodChannel('local_vault/gesture_config');
      final configs = currentState.value;

      for (final config in configs) {
        if (config.readOnly) continue;
        final actionIndex = _getActionIndex(config.action);

        if (config.gestureType == GestureType.tap2 ||
            config.gestureType == GestureType.tap3) {
          final tapCount = config.gestureType == GestureType.tap2 ? 2 : 3;
          await channel.invokeMethod('setTapGestureConfig', {
            'tapCount': tapCount,
            'actionIndex': actionIndex,
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to sync gesture config to the native layer: $e');
    }
  }

  int _getActionIndex(GestureAction action) {
    switch (action) {
      case GestureAction.openTemplates:
        return 0;
      case GestureAction.saveSummary:
        return 1;
      case GestureAction.openSummaries:
        return 2;
    }
  }
}
