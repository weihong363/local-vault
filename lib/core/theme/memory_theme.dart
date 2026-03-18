import 'package:flutter/material.dart';
import 'package:local_vault/core/theme/memory_theme_config.dart';

class MemoryTheme {
  MemoryTheme._();

  static MemoryImportanceTheme importanceTheme(
    BuildContext context, {
    MemoryThemeConfig config = MemoryThemeConfig.defaults,
  }) {
    return importanceThemeForBrightness(
      Theme.of(context).brightness,
      config: config,
    );
  }

  static MemoryImportanceTheme importanceThemeForBrightness(
    Brightness brightness, {
    MemoryThemeConfig config = MemoryThemeConfig.defaults,
  }) {
    return brightness == Brightness.dark
        ? config.darkImportance
        : config.lightImportance;
  }

  static Color importanceColor(
    BuildContext context,
    double importance, {
    MemoryThemeConfig config = MemoryThemeConfig.defaults,
  }) {
    return importanceColorForBrightness(
      Theme.of(context).brightness,
      importance,
      config: config,
    );
  }

  static Color importanceColorForBrightness(
    Brightness brightness,
    double importance, {
    MemoryThemeConfig config = MemoryThemeConfig.defaults,
  }) {
    final theme = importanceThemeForBrightness(
      brightness,
      config: config,
    );
    if (importance >= theme.highThreshold) {
      return theme.highColor.withValues(alpha: theme.alpha);
    }
    if (importance >= theme.mediumThreshold) {
      return theme.mediumColor.withValues(alpha: theme.alpha);
    }
    return theme.lowColor.withValues(alpha: theme.alpha);
  }
}
