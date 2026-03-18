import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/theme/memory_theme.dart';
import 'package:local_vault/core/theme/memory_theme_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MemoryThemeConfig', () {
    test('parses thresholds and colors from json', () {
      final config = MemoryThemeConfig.fromJson(const <String, dynamic>{
        'lightImportance': <String, dynamic>{
          'highThreshold': 0.9,
          'mediumThreshold': 0.4,
          'alpha': 0.12,
          'highColor': '#112233',
          'mediumColor': '#445566',
          'lowColor': '#778899',
        },
        'darkImportance': <String, dynamic>{
          'highThreshold': 0.85,
          'mediumThreshold': 0.35,
          'alpha': 0.3,
          'highColor': '#AABBCC',
          'mediumColor': '#DDEEFF',
          'lowColor': '#123456',
        },
      });

      expect(config.lightImportance.highThreshold, 0.9);
      expect(config.lightImportance.mediumThreshold, 0.4);
      expect(config.lightImportance.alpha, 0.12);
      expect(config.lightImportance.highColor, const Color(0xFF112233));
      expect(config.darkImportance.mediumColor, const Color(0xFFDDEEFF));
      expect(config.darkImportance.lowColor, const Color(0xFF123456));
    });

    test('load merges bundled config with override file', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'memory_theme_config_test',
      );
      final overrideFile = File('${tempDirectory.path}/override.json');
      await overrideFile.writeAsString(
        '''
{
  "lightImportance": {
    "highThreshold": 0.65,
    "highColor": "#0055AA"
  }
}
''',
      );

      try {
        final config = await MemoryThemeConfig.load(
          overrideFileResolver: () async => overrideFile,
        );

        expect(config.lightImportance.highThreshold, 0.65);
        expect(config.lightImportance.highColor, const Color(0xFF0055AA));
        expect(config.lightImportance.mediumThreshold, 0.5);
        expect(config.darkImportance.highThreshold, 0.8);
      } finally {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      }
    });
  });

  group('MemoryTheme', () {
    test('importance color mapping follows configured thresholds', () {
      final config = MemoryThemeConfig.fromJson(const <String, dynamic>{
        'lightImportance': <String, dynamic>{
          'highThreshold': 0.9,
          'mediumThreshold': 0.6,
          'alpha': 0.2,
          'highColor': '#00695C',
          'mediumColor': '#F57F17',
          'lowColor': '#C62828',
        },
      });

      expect(
        MemoryTheme.importanceColorForBrightness(
          Brightness.light,
          0.95,
          config: config,
        ),
        const Color(0x3300695C),
      );
      expect(
        MemoryTheme.importanceColorForBrightness(
          Brightness.light,
          0.7,
          config: config,
        ),
        const Color(0x33F57F17),
      );
      expect(
        MemoryTheme.importanceColorForBrightness(
          Brightness.light,
          0.3,
          config: config,
        ),
        const Color(0x33C62828),
      );
    });
  });
}
