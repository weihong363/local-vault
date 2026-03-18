import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/features/app_whitelist/models/app_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appWhitelistProvider =
    StateNotifierProvider<AppWhitelistNotifier, AsyncValue<List<AppInfo>>>(
        (ref) {
  return AppWhitelistNotifier();
});

final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  const channel = MethodChannel('local_vault/apps');
  try {
    final result = await channel.invokeMethod<List>('getInstalledApps');
    if (result != null) {
      return result.map((item) {
        final map = item as Map<dynamic, dynamic>;
        return AppInfo(
          packageName: map['packageName'] as String,
          appName: map['appName'] as String,
        );
      }).toList();
    }
    return [];
  } catch (e) {
    return [];
  }
});

class AppWhitelistNotifier extends StateNotifier<AsyncValue<List<AppInfo>>> {
  static const String _prefsKey = 'app_whitelist';

  AppWhitelistNotifier() : super(const AsyncLoading()) {
    _loadWhitelist();
  }

  Future<void> _loadWhitelist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final whitelistJson = prefs.getStringList(_prefsKey);

      if (whitelistJson == null || whitelistJson.isEmpty) {
        state = const AsyncData([]);
        await _syncToNative(const []);
      } else {
        final whitelist = whitelistJson.map((json) {
          return AppInfo.fromJson(jsonDecode(json) as Map<String, dynamic>);
        }).toList();
        state = AsyncData(whitelist);
        await _syncToNative(whitelist);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> toggleApp(AppInfo app) async {
    final currentState = state;
    if (currentState is! AsyncData<List<AppInfo>>) return;

    final currentList = currentState.value;
    final newList = currentList.contains(app)
        ? currentList.where((a) => a != app).toList()
        : [...currentList, app];

    state = AsyncData(newList);
    await _saveWhitelist(newList);
  }

  Future<void> _saveWhitelist(List<AppInfo> whitelist) async {
    final prefs = await SharedPreferences.getInstance();
    final whitelistJson =
        whitelist.map((app) => jsonEncode(app.toJson())).toList();
    await prefs.setStringList(_prefsKey, whitelistJson);
    await _syncToNative(whitelist);
  }

  Future<void> _syncToNative(List<AppInfo> whitelist) async {
    try {
      const channel = MethodChannel('local_vault/apps');
      final packageNames = whitelist.map((app) => app.packageName).toList();
      await channel.invokeMethod('setWhitelist', {'packages': packageNames});
    } catch (e) {
      debugPrint('同步白名单到原生端失败: $e');
    }
  }

  Future<void> clearWhitelist() async {
    state = const AsyncData([]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await _syncToNative([]);
  }
}
