// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Local Vault';

  @override
  String get home => 'Home';

  @override
  String get templates => 'Templates';

  @override
  String get chooseTemplate => 'Choose template';

  @override
  String get addTemplate => 'Add template';

  @override
  String get editTemplate => 'Edit template';

  @override
  String get memory => 'Memory';

  @override
  String get myMemories => 'My memories';

  @override
  String get settings => 'Settings';

  @override
  String get search => 'Search';

  @override
  String get save => 'Save';

  @override
  String get saveSummaryQuickActionTitle => 'Save summary';

  @override
  String get inject => 'Inject';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemMode => 'System';

  @override
  String get language => 'Language';

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
  String get storageSettings => 'Storage Settings';

  @override
  String get storageSpace => 'Storage Space';

  @override
  String get backupData => 'Backup Data';

  @override
  String get about => 'About';

  @override
  String get versionInfo => 'Version Info';

  @override
  String get feedback => 'Feedback';

  @override
  String get inDevelopment => 'In Development';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get title => 'Title';

  @override
  String get content => 'Content';

  @override
  String get tags => 'Tags';

  @override
  String get saveToVault => 'Save to Vault';

  @override
  String get copiedToClipboard => 'Copied to Clipboard';

  @override
  String get savedToVault => 'Saved to Local Vault';

  @override
  String get titleAndContentRequired => 'Title and content are required';

  @override
  String get commaSeparatedTagsHint => 'Tags (comma separated)';

  @override
  String get searchHint => 'Search title, content or tags...';

  @override
  String get noSearchResults => 'No search results';

  @override
  String get noData => 'No data';

  @override
  String get noTemplatesYet => 'No templates yet';

  @override
  String get noSummariesYet => 'No memories yet';

  @override
  String get navHome => 'Home';

  @override
  String get navTemplates => 'Templates';

  @override
  String get navMemory => 'Memory';

  @override
  String get navSettings => 'Settings';

  @override
  String get refresh => 'Refresh';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get continueLabel => 'Continue';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get deleteSummary => 'Delete summary';

  @override
  String get deleteTemplate => 'Delete template';

  @override
  String get shareLabel => 'Share';

  @override
  String get restoreLabel => 'Restore';

  @override
  String get retryLabel => 'Retry';

  @override
  String get closeLabel => 'Close';

  @override
  String get workingLabel => 'Working...';

  @override
  String get okLabel => 'OK';

  @override
  String get quickSave => 'Quick save';

  @override
  String get manualInput => 'Manual input';

  @override
  String get quickSaveClipboardTip =>
      'Tip: clipboard text will be used for quick save automatically.\nIf it is empty, you can enter content manually.';

  @override
  String get invalidActionType => 'Invalid action type';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get enableFloatingGestureLauncher =>
      'Enable floating gesture launcher';

  @override
  String get floatingGestureLauncherDescription =>
      'Open the app quickly with gestures from other apps';

  @override
  String get gestureConfiguration => 'Gesture configuration';

  @override
  String get gestureConfigurationDescription => 'Customize gesture behavior';

  @override
  String get appAllowlist => 'App allowlist';

  @override
  String get appAllowlistDescription =>
      'Gestures are only active inside selected apps';

  @override
  String get diagnostics => 'Diagnostics';

  @override
  String get diagnosticsDescription =>
      'Review gesture permissions, services, and sync state';

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
      'Title and tags now use the built-in model';

  @override
  String get titleTagsUseLocalRuleGenerator =>
      'Title and tags now use the local rule-based generator';

  @override
  String get storageSummaryTapToView => 'Tap to view storage details';

  @override
  String get createShareRestoreLocalBackups =>
      'Create, share, and restore local backups';

  @override
  String storageSummaryFormat(
      Object bytes, Object summaryCount, Object templateCount) {
    return '$bytes · $summaryCount summaries · $templateCount templates';
  }

  @override
  String get backupSummaryNone => 'No local backups yet. Tap to create one';

  @override
  String backupSummaryAvailable(Object backupCount) {
    return '$backupCount local backups available';
  }

  @override
  String get architectureChecksDebugOnly => 'Architecture Checks - DEBUG ONLY';

  @override
  String get runArchitectureVerification => 'Run architecture verification';

  @override
  String get runArchitectureVerificationDescription =>
      'Verify that the new architecture is functioning correctly';

  @override
  String get runningArchitectureVerification =>
      'Running architecture verification...';

  @override
  String get architectureVerificationFinished =>
      'Architecture verification finished. Check the console output.';

  @override
  String get inspectDatabase => 'Inspect database';

  @override
  String get inspectDatabaseDescription =>
      'View raw records from summary and template storage';

  @override
  String get notAllPermissionsGranted =>
      'Not all permissions were granted. Gesture features may not work correctly.';

  @override
  String get floatingWindowServiceStarted => 'Floating window service started';

  @override
  String get floatingWindowServiceStopped => 'Floating window service stopped';

  @override
  String failedToStartMessage(Object error) {
    return 'Failed to start: $error';
  }

  @override
  String failedToStopMessage(Object error) {
    return 'Failed to stop: $error';
  }

  @override
  String get serviceStarted => 'Service started';

  @override
  String get floatingWindowTips =>
      'The floating gesture service is now running.\n\nUsage tips:\n1. Look for the semi-transparent gesture zones near the screen edges.\n2. Swipe inside those zones to launch the app quickly.\n3. If the overlay is missing, confirm that all required permissions were granted.\n\nImportant:\nIf gestures stop working after switching apps, check:\n- Whether the app is included in the allowlist\n- Whether Usage Access permission has been granted';

  @override
  String get openAllowlist => 'Open allowlist';

  @override
  String get memoryManagement => 'Memory Management';

  @override
  String loadFailedMessage(Object error) {
    return 'Load failed: $error';
  }

  @override
  String get loadFailedLabel => 'Load failed';

  @override
  String errorWithDetails(Object error) {
    return 'Error: $error';
  }

  @override
  String deleteSummaryConfirm(Object title) {
    return 'Delete \"$title\"?';
  }

  @override
  String deleteTemplateConfirm(Object title) {
    return 'Delete template \"$title\"?';
  }

  @override
  String deleteFailedMessage(Object error) {
    return 'Delete failed: $error';
  }

  @override
  String get templateDeleted => 'Template deleted';

  @override
  String get currentView => 'Current view';

  @override
  String get allMemories => 'All memories';

  @override
  String get searchFilter => 'Search filter';

  @override
  String itemCountLabel(Object count) {
    return '$count items';
  }

  @override
  String get notFiltered => 'Not filtered';

  @override
  String get filtered => 'Filtered';

  @override
  String get memoryType => 'Memory type';

  @override
  String metaImportanceLabel(Object percent) {
    return 'Importance $percent';
  }

  @override
  String metaVisitsLabel(Object count) {
    return 'Visits $count';
  }

  @override
  String metaUpdatedLabel(Object date) {
    return 'Updated $date';
  }

  @override
  String metaLastOpenedLabel(Object date) {
    return 'Last opened $date';
  }

  @override
  String get editLabel => 'Edit';

  @override
  String get promoteToCore => 'Promote to core';

  @override
  String get setAsCore => 'Set as core';

  @override
  String get setAsCoreMemory => 'Set as core memory';

  @override
  String get mergeSimilar => 'Merge similar';

  @override
  String get importanceScore => 'Importance score';

  @override
  String get refreshAndCleanup => 'Refresh and clean up';

  @override
  String get refreshCleanupCompleted => 'Refresh and cleanup completed';

  @override
  String get promoteToCoreMemory => 'Promote to core memory';

  @override
  String promotionDialogBody(Object title) {
    return '\"$title\" will stop participating in regular forgetting decay and will be kept as a prioritized long-term memory.';
  }

  @override
  String promotionStatsLine(Object accessCount, Object importancePercent) {
    return 'Current visits $accessCount · importance $importancePercent';
  }

  @override
  String get promotionThresholdMet =>
      'This memory already meets the automatic promotion threshold.';

  @override
  String get promotionThresholdNotMet =>
      'This memory does not meet the automatic threshold yet, but you can still pin it as a core memory manually.';

  @override
  String promotionThresholdLine(
      Object accessCountThreshold, Object importanceThreshold) {
    return 'Current automatic threshold: visits >= $accessCountThreshold or importance >= $importanceThreshold';
  }

  @override
  String get generatingPromotionReason => 'Generating promotion reason...';

  @override
  String get promotionReason => 'Promotion reason';

  @override
  String get defaultPromotionReason =>
      'This memory already has lasting value and is suitable to preserve as a long-term core memory.';

  @override
  String get upgradeReasonHighAccess =>
      'This memory is accessed frequently and has demonstrated stable long-term value, making it a good candidate for promotion to core memory.';

  @override
  String get upgradeReasonHighImportance =>
      'This memory has a high importance score and is worth retaining as a long-term core memory.';

  @override
  String get confirmPromotion => 'Confirm promotion';

  @override
  String get confirmSetAsCore => 'Confirm set as core';

  @override
  String get promotedToCoreMemory => 'Promoted to core memory';

  @override
  String get setAsCoreSuccess => 'Set as core memory';

  @override
  String get viewCore => 'View core';

  @override
  String get noSimilarMemoriesFound => 'No similar memories found';

  @override
  String get currentFactMemory => 'Current fact memory';

  @override
  String get candidateFactMemory => 'Candidate fact memory';

  @override
  String get mergeCompleted => 'Merge completed';

  @override
  String get chooseMemoryToCompare => 'Choose a memory to compare';

  @override
  String mergeCandidateCount(Object title, Object count) {
    return '\"$title\" has $count merge candidate(s)';
  }

  @override
  String similarityWithContent(Object similarity, Object content) {
    return 'Similarity $similarity · $content';
  }

  @override
  String get deleteMemory => 'Delete memory';

  @override
  String deleteMemoryConfirm(Object title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get deletedLabel => 'Deleted';

  @override
  String get factMemories => 'Fact memories';

  @override
  String get coreMemories => 'Core memories';

  @override
  String get sessionMemories => 'Session memories';

  @override
  String get factMemoryLabel => 'Fact';

  @override
  String get coreMemoryLabel => 'Core';

  @override
  String get sessionMemoryLabel => 'Session';

  @override
  String get factMemoryDescription =>
      'Ordinary facts and stable information that are worth keeping long term.';

  @override
  String get coreMemoryDescription =>
      'The highest-priority long-term memories that do not participate in regular forgetting decay.';

  @override
  String get sessionMemoryDescription =>
      'Temporary context from recent interactions that is useful for short-term organization.';

  @override
  String relativeMinutesAgo(Object count) {
    return '$count min ago';
  }

  @override
  String relativeHoursAgo(Object count) {
    return '$count h ago';
  }

  @override
  String relativeDaysAgo(Object count) {
    return '$count d ago';
  }

  @override
  String get noMatchingMemories => 'No matching memories';

  @override
  String get noFactMemoriesYet => 'No fact memories yet';

  @override
  String get noCoreMemoriesYet => 'No core memories yet';

  @override
  String get noSessionMemoriesYet => 'No session memories yet';

  @override
  String get mergeFactMemories => 'Merge fact memories';

  @override
  String get mergeFactMemoriesDescription =>
      'Compare both versions and choose the final title, content, and tags to keep.';

  @override
  String similarityPercent(Object percent) {
    return 'Similarity $percent';
  }

  @override
  String get mergedPreview => 'Merged preview';

  @override
  String get noTags => 'No tags';

  @override
  String get notNow => 'Not now';

  @override
  String get mergingLabel => 'Merging...';

  @override
  String get confirmMerge => 'Confirm merge';

  @override
  String get keepOriginal => 'Keep original';

  @override
  String get keepNew => 'Keep new';

  @override
  String get smartMerge => 'Smart merge';

  @override
  String get emptyValue => 'Empty';

  @override
  String get candidateMemory => 'Candidate memory';

  @override
  String mergeFailedMessage(Object error) {
    return 'Merge failed: $error';
  }

  @override
  String get clearModelCache => 'Clear model cache';

  @override
  String get clearModelCacheMessage =>
      'This removes local model inference cache files, but keeps summaries, templates, and the model file itself.';

  @override
  String get noModelCacheFilesToClear => 'No model cache files to clear';

  @override
  String clearedModelCacheResult(Object count, Object bytes) {
    return 'Cleared $count cache file(s) and freed $bytes';
  }

  @override
  String get clearBackupFiles => 'Clear backup files';

  @override
  String get clearBackupFilesMessage =>
      'This removes locally generated backup files without changing the current summaries or templates in the database.';

  @override
  String get noBackupFilesToClear => 'No backup files to clear';

  @override
  String deletedBackupFilesResult(Object count, Object bytes) {
    return 'Deleted $count backup file(s) and freed $bytes';
  }

  @override
  String failedToReadStorageUsage(Object error) {
    return 'Failed to read storage usage: $error';
  }

  @override
  String get totalStorageUsed => 'Total storage used';

  @override
  String storageOverviewCounts(
      Object summaryCount, Object templateCount, Object backupCount) {
    return '$summaryCount summaries · $templateCount templates · $backupCount backups';
  }

  @override
  String get summaryDatabase => 'Summary database';

  @override
  String summaryDatabaseSubtitle(Object count) {
    return '$count summaries';
  }

  @override
  String get templateDatabase => 'Template database';

  @override
  String templateDatabaseSubtitle(Object count) {
    return '$count templates';
  }

  @override
  String get backupFiles => 'Backup files';

  @override
  String backupFilesSubtitle(Object count) {
    return '$count backups';
  }

  @override
  String get modelFile => 'Model file';

  @override
  String get bundledModelFootprint => 'Bundled model footprint';

  @override
  String get modelCache => 'Model cache';

  @override
  String get inferenceCacheAndIntermediateFiles =>
      'Inference cache and intermediate files';

  @override
  String get cleanupTools => 'Cleanup tools';

  @override
  String get clearLocalBackupFiles => 'Clear local backup files';

  @override
  String backupCreatedMessage(Object fileName) {
    return 'Backup created: $fileName';
  }

  @override
  String failedToCreateBackupMessage(Object error) {
    return 'Failed to create backup: $error';
  }

  @override
  String importFailedMessage(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get importFailedUnableReadSelectedFile =>
      'Import failed: unable to read the selected file';

  @override
  String get unknownValue => 'Unknown';

  @override
  String get importBackup => 'Import backup';

  @override
  String backupImportPreviewMessage(
      Object summaryCount, Object templateCount, Object exportedAt) {
    return 'This backup contains $summaryCount summaries and $templateCount templates.\nExported at: $exportedAt\n\nImporting it will overwrite the current summary and template data. Continue?';
  }

  @override
  String importFinishedMessage(Object summaryCount, Object templateCount) {
    return 'Import finished: $summaryCount summaries, $templateCount templates';
  }

  @override
  String get invalidBackupFileFormat =>
      'Import failed: invalid backup file format';

  @override
  String get restoreBackupMessage =>
      'Restoring will overwrite the current summary and template data. Continue?';

  @override
  String restoreFinishedMessage(Object summaryCount, Object templateCount) {
    return 'Restore finished: $summaryCount summaries, $templateCount templates';
  }

  @override
  String restoreFailedMessage(Object error) {
    return 'Restore failed: $error';
  }

  @override
  String deleteBackupConfirmMessage(Object fileName) {
    return 'Delete backup $fileName?';
  }

  @override
  String get backupDeleted => 'Backup deleted';

  @override
  String failedToLoadBackupList(Object error) {
    return 'Failed to load backup list: $error';
  }

  @override
  String get noLocalBackupFilesYet => 'No local backup files yet';

  @override
  String get localBackups => 'Local backups';

  @override
  String backupFilesAvailable(Object count) {
    return '$count backup file(s) available';
  }

  @override
  String get backupOverviewDescription =>
      'Creating a backup generates a JSON file and opens the share sheet. You can also import a backup file from outside the app.';

  @override
  String get createAndShareBackup => 'Create and share backup';

  @override
  String get importBackupData => 'Import backup data';

  @override
  String get shareBackupText => 'Local Vault backup';

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
