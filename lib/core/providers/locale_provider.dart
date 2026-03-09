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
    if (index == null) return AppLocale.system;
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

class AppLocalizations {
  final AppLocale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  String get appTitle {
    switch (locale) {
      case AppLocale.zh:
        return '本地记忆库';
      case AppLocale.ja:
        return 'ローカル記憶庫';
      case AppLocale.ko:
        return '로컬 메모리 라이브러리';
      case AppLocale.es:
        return 'Biblioteca de Memoria Local';
      case AppLocale.fr:
        return 'Bibliothèque de Mémoire Locale';
      case AppLocale.de:
        return 'Lokales Speicherarchiv';
      default:
        return 'Local Vault';
    }
  }

  String get home {
    switch (locale) {
      case AppLocale.zh:
        return '列表';
      case AppLocale.ja:
        return 'リスト';
      case AppLocale.ko:
        return '목록';
      case AppLocale.es:
        return 'Lista';
      case AppLocale.fr:
        return 'Liste';
      case AppLocale.de:
        return 'Liste';
      default:
        return 'Home';
    }
  }

  String get search {
    switch (locale) {
      case AppLocale.zh:
        return '搜索';
      case AppLocale.ja:
        return '検索';
      case AppLocale.ko:
        return '검색';
      case AppLocale.es:
        return 'Buscar';
      case AppLocale.fr:
        return 'Rechercher';
      case AppLocale.de:
        return 'Suchen';
      default:
        return 'Search';
    }
  }

  String get settings {
    switch (locale) {
      case AppLocale.zh:
        return '设置';
      case AppLocale.ja:
        return '設定';
      case AppLocale.ko:
        return '설정';
      case AppLocale.es:
        return 'Configuración';
      case AppLocale.fr:
        return 'Paramètres';
      case AppLocale.de:
        return 'Einstellungen';
      default:
        return 'Settings';
    }
  }

  String get save {
    switch (locale) {
      case AppLocale.zh:
        return '保存';
      case AppLocale.ja:
        return '保存';
      case AppLocale.ko:
        return '저장';
      case AppLocale.es:
        return 'Guardar';
      case AppLocale.fr:
        return 'Enregistrer';
      case AppLocale.de:
        return 'Speichern';
      default:
        return 'Save';
    }
  }

  String get inject {
    switch (locale) {
      case AppLocale.zh:
        return '注入';
      case AppLocale.ja:
        return '注入';
      case AppLocale.ko:
        return '주입';
      case AppLocale.es:
        return 'Inyectar';
      case AppLocale.fr:
        return 'Injecter';
      case AppLocale.de:
        return 'Einfügen';
      default:
        return 'Inject';
    }
  }

  String get generalSettings {
    switch (locale) {
      case AppLocale.zh:
        return '通用设置';
      case AppLocale.ja:
        return '一般設定';
      case AppLocale.ko:
        return '일반 설정';
      case AppLocale.es:
        return 'Configuración general';
      case AppLocale.fr:
        return 'Paramètres généraux';
      case AppLocale.de:
        return 'Allgemeine Einstellungen';
      default:
        return 'General Settings';
    }
  }

  String get themeSettings {
    switch (locale) {
      case AppLocale.zh:
        return '主题设置';
      case AppLocale.ja:
        return 'テーマ設定';
      case AppLocale.ko:
        return '테마 설정';
      case AppLocale.es:
        return 'Configuración de tema';
      case AppLocale.fr:
        return 'Paramètres de thème';
      case AppLocale.de:
        return 'Thema-Einstellungen';
      default:
        return 'Theme Settings';
    }
  }

  String get darkMode {
    switch (locale) {
      case AppLocale.zh:
        return '暗色模式';
      case AppLocale.ja:
        return 'ダークモード';
      case AppLocale.ko:
        return '다크 모드';
      case AppLocale.es:
        return 'Modo oscuro';
      case AppLocale.fr:
        return 'Mode sombre';
      case AppLocale.de:
        return 'Dunkelmodus';
      default:
        return 'Dark Mode';
    }
  }

  String get lightMode {
    switch (locale) {
      case AppLocale.zh:
        return '亮色模式';
      case AppLocale.ja:
        return 'ライトモード';
      case AppLocale.ko:
        return '라이트 모드';
      case AppLocale.es:
        return 'Modo claro';
      case AppLocale.fr:
        return 'Mode clair';
      case AppLocale.de:
        return 'Hellmodus';
      default:
        return 'Light Mode';
    }
  }

  String get systemMode {
    switch (locale) {
      case AppLocale.zh:
        return '跟随系统';
      case AppLocale.ja:
        return 'システムに従う';
      case AppLocale.ko:
        return '시스템 따름';
      case AppLocale.es:
        return 'Seguir sistema';
      case AppLocale.fr:
        return 'Suivre le système';
      case AppLocale.de:
        return 'System folgen';
      default:
        return 'System';
    }
  }

  String get language {
    switch (locale) {
      case AppLocale.zh:
        return '语言';
      case AppLocale.ja:
        return '言語';
      case AppLocale.ko:
        return '언어';
      case AppLocale.es:
        return 'Idioma';
      case AppLocale.fr:
        return 'Langue';
      case AppLocale.de:
        return 'Sprache';
      default:
        return 'Language';
    }
  }

  String get storageSettings {
    switch (locale) {
      case AppLocale.zh:
        return '存储设置';
      case AppLocale.ja:
        return 'ストレージ設定';
      case AppLocale.ko:
        return '스토리지 설정';
      case AppLocale.es:
        return 'Configuración de almacenamiento';
      case AppLocale.fr:
        return 'Paramètres de stockage';
      case AppLocale.de:
        return 'Speicher-Einstellungen';
      default:
        return 'Storage Settings';
    }
  }

  String get storageSpace {
    switch (locale) {
      case AppLocale.zh:
        return '存储空间';
      case AppLocale.ja:
        return 'ストレージ容量';
      case AppLocale.ko:
        return '저장 공간';
      case AppLocale.es:
        return 'Espacio de almacenamiento';
      case AppLocale.fr:
        return 'Espace de stockage';
      case AppLocale.de:
        return 'Speicherplatz';
      default:
        return 'Storage Space';
    }
  }

  String get backupData {
    switch (locale) {
      case AppLocale.zh:
        return '备份数据';
      case AppLocale.ja:
        return 'データバックアップ';
      case AppLocale.ko:
        return '데이터 백업';
      case AppLocale.es:
        return 'Respaldar datos';
      case AppLocale.fr:
        return 'Sauvegarder les données';
      case AppLocale.de:
        return 'Daten sichern';
      default:
        return 'Backup Data';
    }
  }

  String get about {
    switch (locale) {
      case AppLocale.zh:
        return '关于';
      case AppLocale.ja:
        return 'について';
      case AppLocale.ko:
        return '정보';
      case AppLocale.es:
        return 'Acerca de';
      case AppLocale.fr:
        return 'À propos';
      case AppLocale.de:
        return 'Über';
      default:
        return 'About';
    }
  }

  String get versionInfo {
    switch (locale) {
      case AppLocale.zh:
        return '版本信息';
      case AppLocale.ja:
        return 'バージョン情報';
      case AppLocale.ko:
        return '버전 정보';
      case AppLocale.es:
        return 'Información de versión';
      case AppLocale.fr:
        return 'Informations de version';
      case AppLocale.de:
        return 'Versionsinformationen';
      default:
        return 'Version Info';
    }
  }

  String get feedback {
    switch (locale) {
      case AppLocale.zh:
        return '反馈建议';
      case AppLocale.ja:
        return 'フィードバック';
      case AppLocale.ko:
        return '피드백';
      case AppLocale.es:
        return 'Comentarios';
      case AppLocale.fr:
        return 'Commentaires';
      case AppLocale.de:
        return 'Feedback';
      default:
        return 'Feedback';
    }
  }

  String get inDevelopment {
    switch (locale) {
      case AppLocale.zh:
        return '开发中';
      case AppLocale.ja:
        return '開発中';
      case AppLocale.ko:
        return '개발 중';
      case AppLocale.es:
        return 'En desarrollo';
      case AppLocale.fr:
        return 'En développement';
      case AppLocale.de:
        return 'In Entwicklung';
      default:
        return 'In Development';
    }
  }

  String get comingSoon {
    switch (locale) {
      case AppLocale.zh:
        return '即将推出';
      case AppLocale.ja:
        return '近日公開';
      case AppLocale.ko:
        return '곧 출시';
      case AppLocale.es:
        return 'Próximamente';
      case AppLocale.fr:
        return 'Bientôt disponible';
      case AppLocale.de:
        return 'Bald verfügbar';
      default:
        return 'Coming Soon';
    }
  }

  String get title {
    switch (locale) {
      case AppLocale.zh:
        return '标题';
      case AppLocale.ja:
        return 'タイトル';
      case AppLocale.ko:
        return '제목';
      case AppLocale.es:
        return 'Título';
      case AppLocale.fr:
        return 'Titre';
      case AppLocale.de:
        return 'Titel';
      default:
        return 'Title';
    }
  }

  String get content {
    switch (locale) {
      case AppLocale.zh:
        return '内容';
      case AppLocale.ja:
        return '内容';
      case AppLocale.ko:
        return '내용';
      case AppLocale.es:
        return 'Contenido';
      case AppLocale.fr:
        return 'Contenu';
      case AppLocale.de:
        return 'Inhalt';
      default:
        return 'Content';
    }
  }

  String get tags {
    switch (locale) {
      case AppLocale.zh:
        return '标签';
      case AppLocale.ja:
        return 'タグ';
      case AppLocale.ko:
        return '태그';
      case AppLocale.es:
        return 'Etiquetas';
      case AppLocale.fr:
        return 'Étiquettes';
      case AppLocale.de:
        return 'Tags';
      default:
        return 'Tags';
    }
  }

  String get saveToVault {
    switch (locale) {
      case AppLocale.zh:
        return '保存到本地记忆库';
      case AppLocale.ja:
        return 'ローカル記憶庫に保存';
      case AppLocale.ko:
        return '로컬 메모리에 저장';
      case AppLocale.es:
        return 'Guardar en la bóveda';
      case AppLocale.fr:
        return 'Enregistrer dans le coffre';
      case AppLocale.de:
        return 'Im Tresor speichern';
      default:
        return 'Save to Vault';
    }
  }

  String get copiedToClipboard {
    switch (locale) {
      case AppLocale.zh:
        return '已复制到剪贴板';
      case AppLocale.ja:
        return 'クリップボードにコピーしました';
      case AppLocale.ko:
        return '클립보드에 복사됨';
      case AppLocale.es:
        return 'Copiado al portapapeles';
      case AppLocale.fr:
        return 'Copié dans le presse-papiers';
      case AppLocale.de:
        return 'In Zwischenablage kopiert';
      default:
        return 'Copied to Clipboard';
    }
  }

  String get savedToVault {
    switch (locale) {
      case AppLocale.zh:
        return '已保存到本地记忆库';
      case AppLocale.ja:
        return 'ローカル記憶庫に保存しました';
      case AppLocale.ko:
        return '로컬 메모리에 저장됨';
      case AppLocale.es:
        return 'Guardado en la bóveda';
      case AppLocale.fr:
        return 'Enregistré dans le coffre';
      case AppLocale.de:
        return 'Im Tresor gespeichert';
      default:
        return 'Saved to Vault';
    }
  }

  String get titleAndContentRequired {
    switch (locale) {
      case AppLocale.zh:
        return '标题和内容不能为空';
      case AppLocale.ja:
        return 'タイトルと内容は必須です';
      case AppLocale.ko:
        return '제목과 내용은 필수입니다';
      case AppLocale.es:
        return 'Título y contenido son obligatorios';
      case AppLocale.fr:
        return 'Le titre et le contenu sont obligatoires';
      case AppLocale.de:
        return 'Titel und Inhalt sind erforderlich';
      default:
        return 'Title and content are required';
    }
  }

  String get searchHint {
    switch (locale) {
      case AppLocale.zh:
        return '搜索标题、内容或标签...';
      case AppLocale.ja:
        return 'タイトル、内容、タグで検索...';
      case AppLocale.ko:
        return '제목, 내용 또는 태그 검색...';
      case AppLocale.es:
        return 'Buscar título, contenido o etiquetas...';
      case AppLocale.fr:
        return 'Rechercher titre, contenu ou étiquettes...';
      case AppLocale.de:
        return 'Titel, Inhalt oder Tags suchen...';
      default:
        return 'Search title, content or tags...';
    }
  }

  String get noSearchResults {
    switch (locale) {
      case AppLocale.zh:
        return '暂无搜索结果';
      case AppLocale.ja:
        return '検索結果がありません';
      case AppLocale.ko:
        return '검색 결과가 없습니다';
      case AppLocale.es:
        return 'No hay resultados de búsqueda';
      case AppLocale.fr:
        return 'Aucun résultat de recherche';
      case AppLocale.de:
        return 'Keine Suchergebnisse';
      default:
        return 'No search results';
    }
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh', 'ja', 'ko', 'es', 'fr', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocale appLocale = _getAppLocale(locale);
    return AppLocalizations(appLocale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocale _getAppLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'zh':
      return AppLocale.zh;
    case 'ja':
      return AppLocale.ja;
    case 'ko':
      return AppLocale.ko;
    case 'es':
      return AppLocale.es;
    case 'fr':
      return AppLocale.fr;
    case 'de':
      return AppLocale.de;
    default:
      return AppLocale.en;
  }
}
