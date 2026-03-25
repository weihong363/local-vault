import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocale {
  system,
  en,
  zh,
  ja,
  ko,
  es,
  fr,
  de,
}

final appLocaleProvider = StateProvider<AppLocale>((ref) {
  return AppLocale.system;
});

class LocaleManager {
  static const String _localeKey = 'app_locale';

  static Future<void> saveLocale(AppLocale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_localeKey, locale.index);
  }

  static Future<AppLocale> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_localeKey);
    if (index == null || index >= AppLocale.values.length) {
      return AppLocale.system;
    }
    return AppLocale.values[index];
  }

  static Locale? getLocale(AppLocale appLocale) {
    switch (appLocale) {
      case AppLocale.system:
        return null;
      case AppLocale.en:
        return const Locale('en');
      case AppLocale.zh:
        return const Locale('zh');
      case AppLocale.ja:
        return const Locale('ja');
      case AppLocale.ko:
        return const Locale('ko');
      case AppLocale.es:
        return const Locale('es');
      case AppLocale.fr:
        return const Locale('fr');
      case AppLocale.de:
        return const Locale('de');
    }
  }
}
