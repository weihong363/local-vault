import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class MemoryImportanceTheme {
  const MemoryImportanceTheme({
    required this.highThreshold,
    required this.mediumThreshold,
    required this.alpha,
    required this.highColor,
    required this.mediumColor,
    required this.lowColor,
  });

  final double highThreshold;
  final double mediumThreshold;
  final double alpha;
  final Color highColor;
  final Color mediumColor;
  final Color lowColor;

  factory MemoryImportanceTheme.fromJson(
    Map<String, dynamic> json, {
    required MemoryImportanceTheme fallback,
  }) {
    return MemoryImportanceTheme(
      highThreshold:
          (json['highThreshold'] as num?)?.toDouble() ?? fallback.highThreshold,
      mediumThreshold: (json['mediumThreshold'] as num?)?.toDouble() ??
          fallback.mediumThreshold,
      alpha: (json['alpha'] as num?)?.toDouble() ?? fallback.alpha,
      highColor: MemoryThemeConfig.colorFromJson(
        json['highColor'],
        defaultValue: fallback.highColor,
      ),
      mediumColor: MemoryThemeConfig.colorFromJson(
        json['mediumColor'],
        defaultValue: fallback.mediumColor,
      ),
      lowColor: MemoryThemeConfig.colorFromJson(
        json['lowColor'],
        defaultValue: fallback.lowColor,
      ),
    );
  }
}

class MemoryThemeConfig {
  const MemoryThemeConfig({
    this.lightImportance = const MemoryImportanceTheme(
      highThreshold: 0.8,
      mediumThreshold: 0.5,
      alpha: 0.18,
      highColor: Color(0xFF43A047),
      mediumColor: Color(0xFFF9A825),
      lowColor: Color(0xFFB00020),
    ),
    this.darkImportance = const MemoryImportanceTheme(
      highThreshold: 0.8,
      mediumThreshold: 0.5,
      alpha: 0.26,
      highColor: Color(0xFF81C784),
      mediumColor: Color(0xFFFFD54F),
      lowColor: Color(0xFFEF9A9A),
    ),
  });

  static const String bundledConfigAssetPath =
      'assets/config/memory_theme_config.json';
  static const String overrideDirectoryName = 'memory_theme';
  static const String overrideFileName = 'memory_theme_config.override.json';
  static const MemoryThemeConfig defaults = MemoryThemeConfig();

  final MemoryImportanceTheme lightImportance;
  final MemoryImportanceTheme darkImportance;

  factory MemoryThemeConfig.fromJson(Map<String, dynamic> json) {
    return MemoryThemeConfig(
      lightImportance: MemoryImportanceTheme.fromJson(
        _asMap(json['lightImportance']),
        fallback: defaults.lightImportance,
      ),
      darkImportance: MemoryImportanceTheme.fromJson(
        _asMap(json['darkImportance']),
        fallback: defaults.darkImportance,
      ),
    );
  }

  static Future<MemoryThemeConfig> load({
    Future<File> Function()? overrideFileResolver,
  }) async {
    Map<String, dynamic> merged = <String, dynamic>{};

    try {
      final bundledRaw = await rootBundle.loadString(bundledConfigAssetPath);
      merged = _asMap(jsonDecode(bundledRaw));
    } catch (error, stackTrace) {
      debugPrint('⚠️ [MemoryThemeConfig] 读取内置配置失败，回退到默认配置: $error');
      debugPrintStack(stackTrace: stackTrace);
      return defaults;
    }

    try {
      final resolveFile = overrideFileResolver ?? resolveOverrideFile;
      final overrideFile = await resolveFile();
      if (await overrideFile.exists()) {
        final overrideRaw = await overrideFile.readAsString();
        final overrideJson = _asMap(jsonDecode(overrideRaw));
        merged = _deepMerge(merged, overrideJson);
      }
    } catch (error, stackTrace) {
      debugPrint(
        '⚠️ [MemoryThemeConfig] 读取覆盖配置失败，将继续使用内置配置: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }

    return MemoryThemeConfig.fromJson(merged);
  }

  static Future<File> resolveOverrideFile() async {
    final appSupportDirectory = await getApplicationSupportDirectory();
    final configDirectory = Directory(
      '${appSupportDirectory.path}/$overrideDirectoryName',
    );
    if (!await configDirectory.exists()) {
      await configDirectory.create(recursive: true);
    }
    return File('${configDirectory.path}/$overrideFileName');
  }

  static Color colorFromJson(
    Object? raw, {
    required Color defaultValue,
  }) {
    if (raw is int) {
      return Color(raw);
    }
    if (raw is! String) {
      return defaultValue;
    }

    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return defaultValue;
    }

    final sanitized = normalized.startsWith('#')
        ? normalized.substring(1)
        : normalized.startsWith('0x')
            ? normalized.substring(2)
            : normalized;
    final withAlpha = sanitized.length == 6 ? 'FF$sanitized' : sanitized;
    final value = int.tryParse(withAlpha, radix: 16);
    return value == null ? defaultValue : Color(value);
  }

  static Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) {
        return MapEntry(key.toString(), value);
      });
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> override,
  ) {
    final merged = Map<String, dynamic>.from(base);
    override.forEach((key, value) {
      final current = merged[key];
      if (current is Map && value is Map) {
        merged[key] = _deepMerge(
          _asMap(current),
          _asMap(value),
        );
      } else {
        merged[key] = value;
      }
    });
    return merged;
  }
}
