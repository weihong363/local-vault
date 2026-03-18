// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Lokales Speicherarchiv';

  @override
  String get home => 'Startseite';

  @override
  String get templates => 'Vorlagen';

  @override
  String get chooseTemplate => 'Vorlage auswählen';

  @override
  String get addTemplate => 'Vorlage hinzufügen';

  @override
  String get editTemplate => 'Vorlage bearbeiten';

  @override
  String get memory => 'Speicher';

  @override
  String get myMemories => 'Meine Erinnerungen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get search => 'Suchen';

  @override
  String get save => 'Speichern';

  @override
  String get saveSummaryQuickActionTitle => 'Zusammenfassung speichern';

  @override
  String get inject => 'Einfügen';

  @override
  String get generalSettings => 'Allgemeine Einstellungen';

  @override
  String get themeSettings => 'Thema-Einstellungen';

  @override
  String get darkMode => 'Dunkelmodus';

  @override
  String get lightMode => 'Hellmodus';

  @override
  String get systemMode => 'System';

  @override
  String get language => 'Sprache';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get storageSettings => 'Speicher-Einstellungen';

  @override
  String get storageSpace => 'Speicherplatz';

  @override
  String get backupData => 'Daten sichern';

  @override
  String get about => 'Über';

  @override
  String get versionInfo => 'Versionsinformationen';

  @override
  String get feedback => 'Feedback';

  @override
  String get inDevelopment => 'In Entwicklung';

  @override
  String get comingSoon => 'Bald verfügbar';

  @override
  String get title => 'Titel';

  @override
  String get content => 'Inhalt';

  @override
  String get tags => 'Tags';

  @override
  String get saveToVault => 'Im Tresor speichern';

  @override
  String get copiedToClipboard => 'In Zwischenablage kopiert';

  @override
  String get savedToVault => 'Im Tresor gespeichert';

  @override
  String get titleAndContentRequired => 'Titel und Inhalt sind erforderlich';

  @override
  String get commaSeparatedTagsHint => 'Tags (durch Kommas getrennt)';

  @override
  String get searchHint => 'Titel, Inhalt oder Tags suchen...';

  @override
  String get noSearchResults => 'Keine Suchergebnisse';

  @override
  String get noData => 'Keine Daten';

  @override
  String get noTemplatesYet => 'Noch keine Vorlagen';

  @override
  String get noSummariesYet => 'Noch keine Erinnerungen';

  @override
  String get navHome => 'Startseite';

  @override
  String get navTemplates => 'Vorlagen';

  @override
  String get navMemory => 'Speicher';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get cancelLabel => 'Abbrechen';

  @override
  String get continueLabel => 'Fortfahren';

  @override
  String get deleteLabel => 'Löschen';

  @override
  String get deleteSummary => 'Zusammenfassung löschen';

  @override
  String get deleteTemplate => 'Vorlage löschen';

  @override
  String get shareLabel => 'Teilen';

  @override
  String get restoreLabel => 'Wiederherstellen';

  @override
  String get retryLabel => 'Erneut versuchen';

  @override
  String get closeLabel => 'Schließen';

  @override
  String get workingLabel => 'Wird verarbeitet...';

  @override
  String get okLabel => 'OK';

  @override
  String get quickSave => 'Schnellspeichern';

  @override
  String get manualInput => 'Manuelle Eingabe';

  @override
  String get quickSaveClipboardTip =>
      'Tipp: Beim Schnellspeichern wird der Text aus der Zwischenablage automatisch verwendet.\nWenn sie leer ist, können Sie den Inhalt manuell eingeben.';

  @override
  String get invalidActionType => 'Ungültiger Aktionstyp';

  @override
  String get quickActions => 'Schnellaktionen';

  @override
  String get enableFloatingGestureLauncher =>
      'Schwebenden Gestenstarter aktivieren';

  @override
  String get floatingGestureLauncherDescription =>
      'Die App aus anderen Apps per Geste schnell öffnen';

  @override
  String get gestureConfiguration => 'Gestenkonfiguration';

  @override
  String get gestureConfigurationDescription => 'Gestenverhalten anpassen';

  @override
  String get appAllowlist => 'Zulassungsliste für Apps';

  @override
  String get appAllowlistDescription =>
      'Gesten sind nur in ausgewählten Apps aktiv';

  @override
  String get diagnostics => 'Diagnose';

  @override
  String get diagnosticsDescription =>
      'Berechtigungen, Dienste und Synchronisationsstatus der Gesten prüfen';

  @override
  String get slmInferenceSettingTitle => 'Enable SLM inference';

  @override
  String get slmInferenceSettingDescription =>
      'Controls whether the app may enter the future SLM inference path. The current summary save flow still uses the local rule-based result until a compatible SLM provider is integrated.';

  @override
  String get slmInferenceEnabledMessage =>
      'SLM inference enabled. The current summary save flow still uses local rules until a compatible SLM provider is integrated.';

  @override
  String get slmInferenceDisabledMessage =>
      'SLM inference disabled. Summary save stays on the local rule path.';

  @override
  String get titleTagsUseBuiltInModel =>
      'Titel und Tags verwenden jetzt das integrierte Modell';

  @override
  String get titleTagsUseLocalRuleGenerator =>
      'Titel und Tags verwenden jetzt den lokalen regelbasierten Generator';

  @override
  String get storageSummaryTapToView => 'Tippen, um Speicherdetails anzuzeigen';

  @override
  String get createShareRestoreLocalBackups =>
      'Lokale Backups erstellen, teilen und wiederherstellen';

  @override
  String storageSummaryFormat(
      Object bytes, Object summaryCount, Object templateCount) {
    return '$bytes · $summaryCount Zusammenfassungen · $templateCount Vorlagen';
  }

  @override
  String get backupSummaryNone =>
      'Noch keine lokalen Backups. Tippen Sie zum Erstellen';

  @override
  String backupSummaryAvailable(Object backupCount) {
    return '$backupCount lokale Backups verfügbar';
  }

  @override
  String get architectureChecksDebugOnly => 'Architekturprüfungen - NUR DEBUG';

  @override
  String get runArchitectureVerification => 'Architekturprüfung ausführen';

  @override
  String get runArchitectureVerificationDescription =>
      'Prüfen, ob die neue Architektur korrekt funktioniert';

  @override
  String get runningArchitectureVerification =>
      'Architekturprüfung wird ausgeführt...';

  @override
  String get architectureVerificationFinished =>
      'Architekturprüfung abgeschlossen. Prüfen Sie die Konsolenausgabe.';

  @override
  String get inspectDatabase => 'Datenbank prüfen';

  @override
  String get inspectDatabaseDescription =>
      'Rohdatensätze aus Zusammenfassungs- und Vorlagenspeicher anzeigen';

  @override
  String get notAllPermissionsGranted =>
      'Nicht alle Berechtigungen wurden erteilt. Gestenfunktionen funktionieren möglicherweise nicht korrekt.';

  @override
  String get floatingWindowServiceStarted => 'Schwebefensterdienst gestartet';

  @override
  String get floatingWindowServiceStopped => 'Schwebefensterdienst gestoppt';

  @override
  String failedToStartMessage(Object error) {
    return 'Start fehlgeschlagen: $error';
  }

  @override
  String failedToStopMessage(Object error) {
    return 'Stoppen fehlgeschlagen: $error';
  }

  @override
  String get serviceStarted => 'Dienst gestartet';

  @override
  String get floatingWindowTips =>
      'Der schwebende Gestendienst wird jetzt ausgeführt.\n\nHinweise zur Nutzung:\n1. Suchen Sie nach den halbtransparenten Gestenzonen in der Nähe der Bildschirmränder.\n2. Wischen Sie innerhalb dieser Zonen, um die App schnell zu starten.\n3. Wenn die Überlagerung fehlt, prüfen Sie, ob alle erforderlichen Berechtigungen erteilt wurden.\n\nWichtig:\nWenn Gesten nach dem Wechseln von Apps nicht mehr funktionieren, prüfen Sie:\n- ob die App in der Zulassungsliste enthalten ist\n- ob die Berechtigung für Nutzungszugriff erteilt wurde';

  @override
  String get openAllowlist => 'Zulassungsliste öffnen';

  @override
  String get memoryManagement => 'Speicherverwaltung';

  @override
  String loadFailedMessage(Object error) {
    return 'Laden fehlgeschlagen: $error';
  }

  @override
  String get loadFailedLabel => 'Laden fehlgeschlagen';

  @override
  String errorWithDetails(Object error) {
    return 'Fehler: $error';
  }

  @override
  String deleteSummaryConfirm(Object title) {
    return 'Zusammenfassung \"$title\" löschen?';
  }

  @override
  String deleteTemplateConfirm(Object title) {
    return 'Vorlage \"$title\" löschen?';
  }

  @override
  String deleteFailedMessage(Object error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get templateDeleted => 'Vorlage gelöscht';

  @override
  String get currentView => 'Aktuelle Ansicht';

  @override
  String get allMemories => 'Alle Speicher';

  @override
  String get searchFilter => 'Suchfilter';

  @override
  String itemCountLabel(Object count) {
    return '$count Einträge';
  }

  @override
  String get notFiltered => 'Nicht gefiltert';

  @override
  String get filtered => 'Gefiltert';

  @override
  String get memoryType => 'Speichertyp';

  @override
  String metaImportanceLabel(Object percent) {
    return 'Wichtigkeit $percent';
  }

  @override
  String metaVisitsLabel(Object count) {
    return 'Aufrufe $count';
  }

  @override
  String metaUpdatedLabel(Object date) {
    return 'Aktualisiert $date';
  }

  @override
  String metaLastOpenedLabel(Object date) {
    return 'Zuletzt geöffnet $date';
  }

  @override
  String get editLabel => 'Bearbeiten';

  @override
  String get promoteToCore => 'Zu Kern hochstufen';

  @override
  String get setAsCore => 'Als Kern setzen';

  @override
  String get setAsCoreMemory => 'Als Kernspeicher festlegen';

  @override
  String get mergeSimilar => 'Ähnliche zusammenführen';

  @override
  String get importanceScore => 'Wichtigkeitswert';

  @override
  String get refreshAndCleanup => 'Aktualisieren und bereinigen';

  @override
  String get refreshCleanupCompleted =>
      'Aktualisierung und Bereinigung abgeschlossen';

  @override
  String get promoteToCoreMemory => 'Zu Kernspeicher hochstufen';

  @override
  String promotionDialogBody(Object title) {
    return '\"$title\" nimmt nicht mehr am regulären Vergessen teil und wird als priorisierter Langzeitspeicher behalten.';
  }

  @override
  String promotionStatsLine(Object accessCount, Object importancePercent) {
    return 'Aktuelle Aufrufe $accessCount · Wichtigkeit $importancePercent';
  }

  @override
  String get promotionThresholdMet =>
      'Dieser Speicher erfüllt bereits den Schwellenwert für automatische Hochstufung.';

  @override
  String get promotionThresholdNotMet =>
      'Dieser Speicher erreicht den automatischen Schwellenwert noch nicht, kann aber manuell als Kernspeicher festgelegt werden.';

  @override
  String promotionThresholdLine(
      Object accessCountThreshold, Object importanceThreshold) {
    return 'Aktueller automatischer Schwellenwert: Aufrufe >= $accessCountThreshold oder Wichtigkeit >= $importanceThreshold';
  }

  @override
  String get generatingPromotionReason =>
      'Grund für Hochstufung wird erstellt...';

  @override
  String get promotionReason => 'Grund für Hochstufung';

  @override
  String get defaultPromotionReason =>
      'Dieser Speicher hat bleibenden Wert und eignet sich als langfristiger Kernspeicher.';

  @override
  String get upgradeReasonHighAccess =>
      'Auf diesen Speicher wird häufig zugegriffen und er hat einen stabilen langfristigen Wert gezeigt, weshalb er sich gut für eine Hochstufung zum Kernspeicher eignet.';

  @override
  String get upgradeReasonHighImportance =>
      'Dieser Speicher hat einen hohen Wichtigkeitswert und sollte als langfristiger Kernspeicher erhalten bleiben.';

  @override
  String get confirmPromotion => 'Hochstufung bestätigen';

  @override
  String get confirmSetAsCore => 'Als Kern bestätigen';

  @override
  String get promotedToCoreMemory => 'Zu Kernspeicher hochgestuft';

  @override
  String get setAsCoreSuccess => 'Als Kernspeicher festgelegt';

  @override
  String get viewCore => 'Kern anzeigen';

  @override
  String get noSimilarMemoriesFound => 'Keine ähnlichen Speicher gefunden';

  @override
  String get currentFactMemory => 'Aktueller Faktenspeicher';

  @override
  String get candidateFactMemory => 'Faktenspeicher-Kandidat';

  @override
  String get mergeCompleted => 'Zusammenführung abgeschlossen';

  @override
  String get chooseMemoryToCompare => 'Speicher zum Vergleichen auswählen';

  @override
  String mergeCandidateCount(Object title, Object count) {
    return '\"$title\" hat $count Zusammenführungs-Kandidat(en)';
  }

  @override
  String similarityWithContent(Object similarity, Object content) {
    return 'Ähnlichkeit $similarity · $content';
  }

  @override
  String get deleteMemory => 'Speicher löschen';

  @override
  String deleteMemoryConfirm(Object title) {
    return '\"$title\" löschen?';
  }

  @override
  String get deletedLabel => 'Gelöscht';

  @override
  String get factMemories => 'Faktenspeicher';

  @override
  String get coreMemories => 'Kernspeicher';

  @override
  String get sessionMemories => 'Sitzungsspeicher';

  @override
  String get factMemoryLabel => 'Fakt';

  @override
  String get coreMemoryLabel => 'Kern';

  @override
  String get sessionMemoryLabel => 'Sitzung';

  @override
  String get factMemoryDescription =>
      'Gewöhnliche Fakten und stabile Informationen, die sich langfristig aufzubewahren lohnen.';

  @override
  String get coreMemoryDescription =>
      'Langzeitspeicher mit höchster Priorität, die nicht am regulären Vergessen teilnehmen.';

  @override
  String get sessionMemoryDescription =>
      'Temporärer Kontext aus jüngsten Interaktionen für die kurzfristige Organisation.';

  @override
  String relativeMinutesAgo(Object count) {
    return 'vor $count Min.';
  }

  @override
  String relativeHoursAgo(Object count) {
    return 'vor $count Std.';
  }

  @override
  String relativeDaysAgo(Object count) {
    return 'vor $count Tg.';
  }

  @override
  String get noMatchingMemories => 'Keine passenden Speicher';

  @override
  String get noFactMemoriesYet => 'Noch keine Faktenspeicher';

  @override
  String get noCoreMemoriesYet => 'Noch keine Kernspeicher';

  @override
  String get noSessionMemoriesYet => 'Noch keine Sitzungsspeicher';

  @override
  String get mergeFactMemories => 'Faktenspeicher zusammenführen';

  @override
  String get mergeFactMemoriesDescription =>
      'Vergleichen Sie beide Versionen und wählen Sie den endgültigen Titel, Inhalt und die Tags aus, die behalten werden sollen.';

  @override
  String similarityPercent(Object percent) {
    return 'Ähnlichkeit $percent';
  }

  @override
  String get mergedPreview => 'Zusammengeführte Vorschau';

  @override
  String get noTags => 'Keine Tags';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get mergingLabel => 'Wird zusammengeführt...';

  @override
  String get confirmMerge => 'Zusammenführung bestätigen';

  @override
  String get keepOriginal => 'Original behalten';

  @override
  String get keepNew => 'Neu behalten';

  @override
  String get smartMerge => 'Intelligentes Zusammenführen';

  @override
  String get emptyValue => 'Leer';

  @override
  String get candidateMemory => 'Kandidatenspeicher';

  @override
  String mergeFailedMessage(Object error) {
    return 'Zusammenführung fehlgeschlagen: $error';
  }

  @override
  String get clearModelCache => 'Modellcache leeren';

  @override
  String get clearModelCacheMessage =>
      'Dadurch werden lokale Dateien des Modell-Inferenzcaches entfernt, Zusammenfassungen, Vorlagen und die Modelldatei selbst bleiben jedoch erhalten.';

  @override
  String get noModelCacheFilesToClear =>
      'Keine Modellcache-Dateien zum Löschen';

  @override
  String clearedModelCacheResult(Object count, Object bytes) {
    return '$count Cache-Datei(en) gelöscht und $bytes freigegeben';
  }

  @override
  String get clearBackupFiles => 'Backup-Dateien löschen';

  @override
  String get clearBackupFilesMessage =>
      'Dadurch werden lokal erzeugte Backup-Dateien gelöscht, ohne die aktuellen Zusammenfassungen oder Vorlagen in der Datenbank zu ändern.';

  @override
  String get noBackupFilesToClear => 'Keine Backup-Dateien zum Löschen';

  @override
  String deletedBackupFilesResult(Object count, Object bytes) {
    return '$count Backup-Datei(en) gelöscht und $bytes freigegeben';
  }

  @override
  String failedToReadStorageUsage(Object error) {
    return 'Speichernutzung konnte nicht gelesen werden: $error';
  }

  @override
  String get totalStorageUsed => 'Gesamter Speicherverbrauch';

  @override
  String storageOverviewCounts(
      Object summaryCount, Object templateCount, Object backupCount) {
    return '$summaryCount Zusammenfassungen · $templateCount Vorlagen · $backupCount Backups';
  }

  @override
  String get summaryDatabase => 'Zusammenfassungsdatenbank';

  @override
  String summaryDatabaseSubtitle(Object count) {
    return '$count Zusammenfassungen';
  }

  @override
  String get templateDatabase => 'Vorlagendatenbank';

  @override
  String templateDatabaseSubtitle(Object count) {
    return '$count Vorlagen';
  }

  @override
  String get backupFiles => 'Backup-Dateien';

  @override
  String backupFilesSubtitle(Object count) {
    return '$count Backups';
  }

  @override
  String get modelFile => 'Modelldatei';

  @override
  String get bundledModelFootprint => 'Platzbedarf des integrierten Modells';

  @override
  String get modelCache => 'Modellcache';

  @override
  String get inferenceCacheAndIntermediateFiles =>
      'Inferenzcache und Zwischendateien';

  @override
  String get cleanupTools => 'Bereinigungswerkzeuge';

  @override
  String get clearLocalBackupFiles => 'Lokale Backup-Dateien löschen';

  @override
  String backupCreatedMessage(Object fileName) {
    return 'Backup erstellt: $fileName';
  }

  @override
  String failedToCreateBackupMessage(Object error) {
    return 'Backup konnte nicht erstellt werden: $error';
  }

  @override
  String importFailedMessage(Object error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get importFailedUnableReadSelectedFile =>
      'Import fehlgeschlagen: Die ausgewählte Datei konnte nicht gelesen werden';

  @override
  String get unknownValue => 'Unbekannt';

  @override
  String get importBackup => 'Backup importieren';

  @override
  String backupImportPreviewMessage(
      Object summaryCount, Object templateCount, Object exportedAt) {
    return 'Dieses Backup enthält $summaryCount Zusammenfassungen und $templateCount Vorlagen.\nExportiert am: $exportedAt\n\nBeim Import werden die aktuellen Zusammenfassungs- und Vorlagendaten überschrieben. Fortfahren?';
  }

  @override
  String importFinishedMessage(Object summaryCount, Object templateCount) {
    return 'Import abgeschlossen: $summaryCount Zusammenfassungen, $templateCount Vorlagen';
  }

  @override
  String get invalidBackupFileFormat =>
      'Import fehlgeschlagen: Ungültiges Backup-Dateiformat';

  @override
  String get restoreBackupMessage =>
      'Beim Wiederherstellen werden die aktuellen Zusammenfassungs- und Vorlagendaten überschrieben. Fortfahren?';

  @override
  String restoreFinishedMessage(Object summaryCount, Object templateCount) {
    return 'Wiederherstellung abgeschlossen: $summaryCount Zusammenfassungen, $templateCount Vorlagen';
  }

  @override
  String restoreFailedMessage(Object error) {
    return 'Wiederherstellung fehlgeschlagen: $error';
  }

  @override
  String deleteBackupConfirmMessage(Object fileName) {
    return 'Backup $fileName löschen?';
  }

  @override
  String get backupDeleted => 'Backup gelöscht';

  @override
  String failedToLoadBackupList(Object error) {
    return 'Backup-Liste konnte nicht geladen werden: $error';
  }

  @override
  String get noLocalBackupFilesYet => 'Noch keine lokalen Backup-Dateien';

  @override
  String get localBackups => 'Lokale Backups';

  @override
  String backupFilesAvailable(Object count) {
    return '$count Backup-Datei(en) verfügbar';
  }

  @override
  String get backupOverviewDescription =>
      'Beim Erstellen eines Backups wird eine JSON-Datei erzeugt und die Freigabeansicht geöffnet. Sie können auch eine Backup-Datei von außerhalb der App importieren.';

  @override
  String get createAndShareBackup => 'Backup erstellen und teilen';

  @override
  String get importBackupData => 'Backup-Daten importieren';

  @override
  String get shareBackupText => 'Local Vault Backup';

  @override
  String get shareBackupSubject => 'Local Vault Backup';

  @override
  String get confirmLabel => 'Confirm';

  @override
  String get clearLabel => 'Clear';

  @override
  String get runningLabel => 'Running...';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get statusEnabled => 'Enabled';

  @override
  String get statusDisabled => 'Disabled';

  @override
  String get statusGranted => 'Granted';

  @override
  String get statusNotGranted => 'Not granted';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusStopped => 'Stopped';

  @override
  String get statusUnavailable => 'Unavailable';

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusMissing => 'Missing';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusCompatible => 'Compatible';

  @override
  String get statusIncompatible => 'Incompatible';

  @override
  String get statusInitialized => 'Initialized';

  @override
  String get statusNotInitialized => 'Not initialized';

  @override
  String get statusDetected => 'Detected';

  @override
  String get statusNotDetected => 'Not detected';

  @override
  String get statusModelUsed => 'Model used';

  @override
  String get statusModelNotUsed => 'Model not used';

  @override
  String get statusInitializationComplete => 'Initialization complete';

  @override
  String get statusInitializationIncomplete => 'Initialization incomplete';

  @override
  String get gestureConfigurationSaved => 'Configuration saved';

  @override
  String gestureConfigurationLoadFailed(Object error) {
    return 'Failed to load gesture configuration: $error';
  }

  @override
  String get resetToDefaults => 'Reset to defaults';

  @override
  String get resetGesturesToDefaultsMessage =>
      'Reset all gestures back to the default configuration?';

  @override
  String get restoredDefaultSettings => 'Restored default settings';

  @override
  String get gestureShareOnly => 'Share only';

  @override
  String get gestureActionOpenTemplates => 'Open prompt templates';

  @override
  String get gestureActionSaveSummary => 'Save a summary from shared content';

  @override
  String get gestureActionOpenSavedContext => 'Open saved context';

  @override
  String get gestureDoubleTap => 'Double tap';

  @override
  String get gestureTripleTap => 'Triple tap';

  @override
  String get triggerAction => 'Trigger action';

  @override
  String get alreadyUsedByAnotherGesture => 'Already used by another gesture';

  @override
  String get searchAppsHint => 'Search apps...';

  @override
  String appWhitelistLoadFailed(Object error) {
    return 'Load failed: $error';
  }

  @override
  String selectedAppsCount(Object count) {
    return '$count app(s) selected';
  }

  @override
  String get clearAllowlistTooltip => 'Clear allowlist';

  @override
  String get gesturesActiveInAllApps => 'Gestures are active in all apps';

  @override
  String get filterAll => 'All';

  @override
  String get filterSelected => 'Selected';

  @override
  String get filterUnselected => 'Unselected';

  @override
  String get noAppsFound => 'No apps found';

  @override
  String get noMatchingAppsFound => 'No matching apps found';

  @override
  String get noSelectedAppsYet => 'No selected apps yet';

  @override
  String get noUnselectedApps => 'No unselected apps';

  @override
  String get clearAllowlistTitle => 'Clear allowlist';

  @override
  String get clearAllowlistMessage =>
      'Clear the app allowlist? Gestures will become active in all apps.';

  @override
  String get allowlistCleared => 'Allowlist cleared';

  @override
  String get databaseInspector => 'Database Inspector';

  @override
  String failedToOpenDatabase(Object error) {
    return 'Failed to open database: $error';
  }

  @override
  String get summariesTab => 'Summaries';

  @override
  String get templatesTab => 'Templates';

  @override
  String get noSummaryRecordsInBox => 'No summary records in this box';

  @override
  String get noTemplateRecordsInBox => 'No template records in this box';

  @override
  String recordsWithIssues(Object count) {
    return 'Records with issues: $count';
  }

  @override
  String legacyTemplateTypes(Object count) {
    return 'Legacy template types: $count';
  }

  @override
  String defaultTemplatesCount(Object count) {
    return 'Default templates: $count';
  }

  @override
  String boxMetricLabel(Object boxName) {
    return 'Box: $boxName';
  }

  @override
  String recordsMetricLabel(Object count) {
    return 'Records: $count';
  }

  @override
  String keyMetricLabel(Object key) {
    return 'Key: $key';
  }

  @override
  String get noObviousIssuesDetected => 'No obvious issues detected';

  @override
  String issuesMetricLabel(Object count) {
    return 'Issues: $count';
  }

  @override
  String get copyJson => 'Copy JSON';

  @override
  String get recordNotMapCorrupted =>
      'Record is not a Map and may be corrupted';

  @override
  String get unparseableSummaryRecord => 'Unparseable summary record';

  @override
  String get unparseableTemplateRecord => 'Unparseable template record';

  @override
  String rawTypeLabel(Object type) {
    return 'Raw type: $type';
  }

  @override
  String get legacyTemplateRecordDetected =>
      'Legacy template-type record detected and will be read as a fact';

  @override
  String get missingId => 'Missing id';

  @override
  String get titleIsEmpty => 'Title is empty';

  @override
  String get contentIsEmpty => 'Content is empty';

  @override
  String get accessCountInvalid => 'accessCount is not a valid number';

  @override
  String get accessCountBelowZero => 'accessCount is below 0';

  @override
  String get createdAtCouldNotBeParsed => 'createdAt could not be parsed';

  @override
  String summaryDeserializationFailed(Object error) {
    return 'SummaryEntity deserialization failed: $error';
  }

  @override
  String templateDeserializationFailed(Object error) {
    return 'TemplateEntity deserialization failed: $error';
  }

  @override
  String get unknownTime => 'Unknown time';

  @override
  String get untitledSummary => '(Untitled summary)';

  @override
  String get untitledTemplate => '(Untitled template)';

  @override
  String summaryRecordSubtitle(
      Object accessCount, Object createdAt, Object type) {
    return 'Type: $type  Access: $accessCount  Created: $createdAt';
  }

  @override
  String templateRecordSubtitle(Object createdAt, Object templateKind) {
    return '$templateKind  Created: $createdAt';
  }

  @override
  String get defaultTemplateLabel => 'Default template';

  @override
  String get customTemplateLabel => 'Custom template';

  @override
  String get refreshDiagnostics => 'Refresh diagnostics';

  @override
  String get failedToLoadDiagnostics => 'Failed to load diagnostics';

  @override
  String get gestureDiagnosticsTitle => 'Gesture diagnostics';

  @override
  String get gestureDiagnosticsDescription =>
      'Pull down to refresh permission, service, and native sync state.';

  @override
  String get slmDiagnosticsTitle => 'SLM diagnostics';

  @override
  String get slmDiagnosticsDescription =>
      'Inspect the current model, cache, and initialization state, then run a sample self-check inference.';

  @override
  String get allowlistedAppsLabel => 'Allowlisted apps';

  @override
  String get floatingGestureLauncherTitle => 'Floating gesture launcher';

  @override
  String get floatingGestureLauncherEnabledDescription =>
      'The master gesture toggle in settings is enabled.';

  @override
  String get floatingGestureLauncherDisabledDescription =>
      'When the master toggle is off, double-tap and triple-tap gestures will not fire.';

  @override
  String get overlayPermissionTitle => 'Overlay permission';

  @override
  String get overlayPermissionGrantedDescription =>
      'The system allows the app to draw over other apps.';

  @override
  String get overlayPermissionDeniedDescription =>
      'Without this permission, the floating overlay service cannot start normally.';

  @override
  String get usageAccessPermissionTitle => 'Usage Access permission';

  @override
  String get usageAccessGrantedDescription =>
      'The app can identify the current foreground app for allowlist checks.';

  @override
  String get usageAccessDeniedDescription =>
      'Without this permission, allowlist matching and cross-app gesture triggers will fail.';

  @override
  String get floatingServiceStatusTitle => 'Floating service status';

  @override
  String get floatingServiceRunningDescription =>
      'The native floating service is currently listening for gestures.';

  @override
  String get floatingServiceEnabledButStoppedDescription =>
      'The master toggle is enabled, but the native floating service is not running right now.';

  @override
  String get floatingServiceStoppedDescription =>
      'When the master toggle is off, the service usually remains stopped.';

  @override
  String get floatingServiceUnavailableDescription =>
      'The native service state could not be read.';

  @override
  String get doubleTapActionSyncTitle => 'Double-tap action sync';

  @override
  String get doubleTapActionSyncedDescription =>
      'The double-tap action is synced to the native layer.';

  @override
  String get doubleTapActionOutOfSyncDescription =>
      'The current double-tap action does not match the native layer. Re-saving gesture settings is recommended.';

  @override
  String get tripleTapActionSyncTitle => 'Triple-tap action sync';

  @override
  String get tripleTapActionSyncedDescription =>
      'The triple-tap action is synced to the native layer.';

  @override
  String get tripleTapActionOutOfSyncDescription =>
      'The current triple-tap action does not match the native layer. Re-saving gesture settings is recommended.';

  @override
  String get allowlistScopeTitle => 'Allowlist scope';

  @override
  String get allAppsValue => 'All apps';

  @override
  String restrictedAppsValue(Object count) {
    return 'Restricted to $count app(s)';
  }

  @override
  String get allowlistScopeAllAppsDescription =>
      'Gestures currently attempt to work in every foreground app.';

  @override
  String get allowlistScopeRestrictedDescription =>
      'Only allowlisted foreground apps currently respond to gestures.';

  @override
  String get allowlistNativeSyncTitle => 'Allowlist native sync';

  @override
  String flutterNativeCountLabel(Object flutterCount, Object nativeCount) {
    return 'Flutter: $flutterCount / Native: $nativeCount';
  }

  @override
  String actionSyncValue(Object flutterAction, Object nativeAction) {
    return 'Flutter: $flutterAction / Native: $nativeAction';
  }

  @override
  String get allowlistNativeUnreadableDescription =>
      'The native allowlist could not be read.';

  @override
  String get allowlistNativeSyncedDescription =>
      'The allowlist is synced to the native layer.';

  @override
  String get allowlistNativeOutOfSyncDescription =>
      'Flutter and native allowlists are out of sync. Re-opening the allowlist page can trigger another sync.';

  @override
  String get runtimeEnvironmentTitle => 'Runtime environment';

  @override
  String get environmentAndroid => 'Android';

  @override
  String get environmentWeb => 'Web';

  @override
  String get environmentDesktop => 'Desktop';

  @override
  String get runtimeEnvironmentAndroidDescription =>
      'This environment meets the baseline conditions for attempting on-device SLM inference.';

  @override
  String get runtimeEnvironmentNonAndroidDescription =>
      'This is not an Android device environment. The self-check can still run, but it will usually follow the rule-based fallback path.';

  @override
  String get experimentalNativeInferenceFlagTitle =>
      'Experimental native inference flag';

  @override
  String get experimentalNativeInferenceEnabledDescription =>
      'This build allows attempts to enter the native SLM inference path. On Android, it is currently enabled whenever the SLM inference switch is on.';

  @override
  String get experimentalNativeInferenceDisabledDescription =>
      'This build or runtime setting currently disables the native SLM inference path, so SLM remains in rule-fallback mode.';

  @override
  String get nativeInferenceSupportTitle => 'Native inference support';

  @override
  String get nativeInferenceSupportAvailableDescription =>
      'The required native symbols and runtime conditions for the current SLM inference path appear to be satisfied.';

  @override
  String get nativeInferenceSupportUnavailableDescription =>
      'This environment does not currently support native inference, so runtime will degrade automatically.';

  @override
  String get nativeSymbolDetectionTitle => 'Native symbol detection';

  @override
  String get nativeSymbolDetectedDescription =>
      'The required LlmInferenceEngine symbols are visible.';

  @override
  String get nativeSymbolMissingDescription =>
      'When critical native symbols are missing, model inference falls back to rule mode immediately.';

  @override
  String get bundledModelFormatTitle => 'Bundled model format';

  @override
  String get slmInitializationStateTitle => 'SLM initialization state';

  @override
  String get slmInitializedDescription =>
      'The service has already been initialized, so later self-checks reuse the current state.';

  @override
  String get slmNotInitializedDescription =>
      'Initialization has not been triggered yet. Running the self-check will attempt it automatically.';

  @override
  String get modelAvailabilityTitle => 'Model availability';

  @override
  String get modelAvailableNow => 'Available now';

  @override
  String get usingRuleFallback => 'Using rule fallback';

  @override
  String get modelAvailabilityAvailableDescription =>
      'Model inference can already be used directly on this device.';

  @override
  String get modelAvailabilityIncompatibleDescription =>
      'The current model file format is incompatible with the current Android native SLM runtime, so runtime will stay on the rule fallback path until the bundled model is replaced.';

  @override
  String get modelAvailabilityFallbackDescription =>
      'This does not block the main flow, but title, tag, and topic generation will prefer the rule fallback path.';

  @override
  String modelFileMissingDescription(Object path) {
    return 'Current file path: $path. If the file is missing, the runtime automatically falls back to rule mode.';
  }

  @override
  String get modelCacheRuntimeParametersTitle =>
      'Model cache and runtime parameters';

  @override
  String modelCacheRuntimeParametersDescription(Object assetPath,
      Object maxTokens, Object queueWait, Object requestTimeout) {
    return 'requestTimeout ${requestTimeout}s · queueWait ${queueWait}s · maxTokens $maxTokens\nassetPath: $assetPath';
  }

  @override
  String statusAndSizeLabel(Object size, Object status) {
    return '$status · $size';
  }

  @override
  String cacheSummaryLabel(Object count, Object size) {
    return '$size · max cache entries $count';
  }

  @override
  String slmSelfCheckFailed(Object error) {
    return 'SLM self-check failed: $error';
  }

  @override
  String get slmSelfCheckTitle => 'SLM self-check';

  @override
  String get slmSelfCheckAndroidHint =>
      'It is best to run this once on a real Android device to confirm whether the model is actually being used.';

  @override
  String get slmSelfCheckNonAndroidHint =>
      'This is not an Android device environment, so the self-check is mainly useful for validating fallback behavior and configuration state.';

  @override
  String get runSelfCheck => 'Run self-check';

  @override
  String get noSelfCheckYet =>
      'No self-check has been run yet. Running one on the target device is recommended to verify whether topic extraction and title/tag generation use the model or rule fallback.';

  @override
  String completedChipLabel(Object time) {
    return 'Completed $time';
  }

  @override
  String get topicExtraction => 'Topic extraction';

  @override
  String get titleAndTagGeneration => 'Title and tag generation';

  @override
  String fallbackDetailLabel(Object latency, Object mode) {
    return 'fallback: $mode · ${latency}ms';
  }

  @override
  String tagsDetailLabel(Object tags) {
    return 'tags: $tags';
  }

  @override
  String get fallbackModel => 'Model';

  @override
  String get fallbackCache => 'Cache';

  @override
  String get fallbackRules => 'Rules';

  @override
  String get fallbackDisabledUnavailable => 'Disabled/Unavailable';

  @override
  String get summaryBannerErrorTitle =>
      'Issues were found that can directly break gesture behavior';

  @override
  String get summaryBannerErrorDescription =>
      'Permission-related issues should usually be fixed first.';

  @override
  String get summaryBannerWarningTitle =>
      'Some gesture configuration issues need attention';

  @override
  String get summaryBannerWarningDescription =>
      'When sync state or service state drifts, gestures may not trigger as expected.';

  @override
  String get summaryBannerHealthyTitle =>
      'No obvious gesture issues were found';

  @override
  String get summaryBannerHealthyDescription =>
      'Permissions, service state, and native synchronization all look healthy.';

  @override
  String get ocrRecognitionTitlePrefix => 'OCR Recognition';

  @override
  String ocrRecognizedCharacters(Object count) {
    return 'Recognized $count characters';
  }

  @override
  String ocrFailedMessage(Object error) {
    return 'OCR failed: $error';
  }

  @override
  String ocrProcessingFailedMessage(Object error) {
    return 'OCR processing failed: $error';
  }

  @override
  String get previewEnterContent =>
      'Enter content to preview suggested titles and tags';

  @override
  String previewGenerationFailed(Object error) {
    return 'Preview generation failed: $error';
  }

  @override
  String get previewApplied => 'Applied preview title and tags to the form';

  @override
  String get contentRequiredMessage => 'Content is required';

  @override
  String get summaryUpdated => 'Summary updated';

  @override
  String get duplicateFactMemoryUpdated =>
      'Detected a duplicate fact memory and updated the existing record';

  @override
  String get savedAndMergedFactMemories => 'Saved and merged the fact memories';

  @override
  String saveFailedMessage(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get mergeCandidatesFound => 'Merge candidates found';

  @override
  String mergeCandidatesFoundDescription(Object title) {
    return '\"$title\" was saved. Review these merge candidates:';
  }

  @override
  String get laterLabel => 'Later';

  @override
  String get existingFactMemory => 'Existing fact memory';

  @override
  String get newFactMemory => 'New fact memory';

  @override
  String get editSummary => 'Edit summary';

  @override
  String get saveContent => 'Save content';

  @override
  String get sharedBadge => 'Shared';

  @override
  String get remarkLabel => 'Remark';

  @override
  String get enterTitleHint => 'Enter a title';

  @override
  String get contentShareHint =>
      'Content shared from other apps will appear here automatically';

  @override
  String get remarkHint => 'Add optional context or notes';

  @override
  String get tagsHint => 'Separate multiple tags with commas';

  @override
  String get previewSuggestedTitleTags => 'Preview suggested title and tags';

  @override
  String get previewSuggestedTitleTagsDescription =>
      'When enabled, suggestions are generated from the current content without overwriting your form automatically';

  @override
  String get updateSummary => 'Update summary';

  @override
  String get requiredFieldHint => '* indicates a required field';

  @override
  String get saveResultPreview => 'Save result preview';

  @override
  String get previewPrimaryDescription =>
      'The preview recommends titles and tags based primarily on the main content.';

  @override
  String get suggestedTitle => 'Suggested title';

  @override
  String get suggestedTags => 'Suggested tags';

  @override
  String get applyToForm => 'Apply to form';

  @override
  String get generatedByBuiltInModel => 'Generated by the built-in model';

  @override
  String get generatedByLocalRules => 'Generated by local rules';
}
