import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Vault'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @chooseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose template'**
  String get chooseTemplate;

  /// No description provided for @addTemplate.
  ///
  /// In en, this message translates to:
  /// **'Add template'**
  String get addTemplate;

  /// No description provided for @editTemplate.
  ///
  /// In en, this message translates to:
  /// **'Edit template'**
  String get editTemplate;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memory;

  /// No description provided for @myMemories.
  ///
  /// In en, this message translates to:
  /// **'My memories'**
  String get myMemories;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveSummaryQuickActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Save summary'**
  String get saveSummaryQuickActionTitle;

  /// No description provided for @inject.
  ///
  /// In en, this message translates to:
  /// **'Inject'**
  String get inject;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @themeSettings.
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @storageSettings.
  ///
  /// In en, this message translates to:
  /// **'Storage Settings'**
  String get storageSettings;

  /// No description provided for @storageSpace.
  ///
  /// In en, this message translates to:
  /// **'Storage Space'**
  String get storageSpace;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Backup Data'**
  String get backupData;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @versionInfo.
  ///
  /// In en, this message translates to:
  /// **'Version Info'**
  String get versionInfo;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @inDevelopment.
  ///
  /// In en, this message translates to:
  /// **'In Development'**
  String get inDevelopment;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @saveToVault.
  ///
  /// In en, this message translates to:
  /// **'Save to Vault'**
  String get saveToVault;

  /// No description provided for @showFullContent.
  ///
  /// In en, this message translates to:
  /// **'Show full content'**
  String get showFullContent;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to Clipboard'**
  String get copiedToClipboard;

  /// No description provided for @savedToVault.
  ///
  /// In en, this message translates to:
  /// **'Saved to Local Vault'**
  String get savedToVault;

  /// No description provided for @titleAndContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and content are required'**
  String get titleAndContentRequired;

  /// No description provided for @commaSeparatedTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get commaSeparatedTagsHint;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search title, content or tags...'**
  String get searchHint;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get noSearchResults;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noTemplatesYet.
  ///
  /// In en, this message translates to:
  /// **'No templates yet'**
  String get noTemplatesYet;

  /// No description provided for @noSummariesYet.
  ///
  /// In en, this message translates to:
  /// **'No memories yet'**
  String get noSummariesYet;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get navTemplates;

  /// No description provided for @navMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get navMemory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @deleteSummary.
  ///
  /// In en, this message translates to:
  /// **'Delete summary'**
  String get deleteSummary;

  /// No description provided for @deleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'Delete template'**
  String get deleteTemplate;

  /// No description provided for @shareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// No description provided for @restoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreLabel;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @workingLabel.
  ///
  /// In en, this message translates to:
  /// **'Working...'**
  String get workingLabel;

  /// No description provided for @okLabel.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okLabel;

  /// No description provided for @quickSave.
  ///
  /// In en, this message translates to:
  /// **'Quick save'**
  String get quickSave;

  /// No description provided for @manualInput.
  ///
  /// In en, this message translates to:
  /// **'Manual input'**
  String get manualInput;

  /// No description provided for @quickSaveClipboardTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: clipboard text will be used for quick save automatically.\nIf it is empty, you can enter content manually.'**
  String get quickSaveClipboardTip;

  /// No description provided for @invalidActionType.
  ///
  /// In en, this message translates to:
  /// **'Invalid action type'**
  String get invalidActionType;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @enableFloatingGestureLauncher.
  ///
  /// In en, this message translates to:
  /// **'Enable floating gesture launcher'**
  String get enableFloatingGestureLauncher;

  /// No description provided for @floatingGestureLauncherDescription.
  ///
  /// In en, this message translates to:
  /// **'Open the app quickly with gestures from other apps'**
  String get floatingGestureLauncherDescription;

  /// No description provided for @gestureConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Gesture configuration'**
  String get gestureConfiguration;

  /// No description provided for @gestureConfigurationDescription.
  ///
  /// In en, this message translates to:
  /// **'Customize gesture behavior'**
  String get gestureConfigurationDescription;

  /// No description provided for @appAllowlist.
  ///
  /// In en, this message translates to:
  /// **'App allowlist'**
  String get appAllowlist;

  /// No description provided for @appAllowlistDescription.
  ///
  /// In en, this message translates to:
  /// **'Gestures are only active inside selected apps'**
  String get appAllowlistDescription;

  /// No description provided for @diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnostics;

  /// No description provided for @diagnosticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Review gesture permissions, services, and sync state'**
  String get diagnosticsDescription;

  /// No description provided for @slmInferenceSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable SLM inference'**
  String get slmInferenceSettingTitle;

  /// No description provided for @slmInferenceSettingDescription.
  ///
  /// In en, this message translates to:
  /// **'This preference is reserved for future compatibility. The current app version always uses local rules for titles, tags, and topics.'**
  String get slmInferenceSettingDescription;

  /// No description provided for @slmInferenceEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'SLM preference enabled. The current app version still uses local rules for titles, tags, and topics.'**
  String get slmInferenceEnabledMessage;

  /// No description provided for @slmInferenceDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'SLM preference disabled. The current app version still uses local rules for titles, tags, and topics.'**
  String get slmInferenceDisabledMessage;

  /// No description provided for @titleTagsUseBuiltInModel.
  ///
  /// In en, this message translates to:
  /// **'Title and tags now use the native SLM runtime'**
  String get titleTagsUseBuiltInModel;

  /// No description provided for @titleTagsUseLocalRuleGenerator.
  ///
  /// In en, this message translates to:
  /// **'Title and tags now use the local rule-based generator'**
  String get titleTagsUseLocalRuleGenerator;

  /// No description provided for @storageSummaryTapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view storage details'**
  String get storageSummaryTapToView;

  /// No description provided for @createShareRestoreLocalBackups.
  ///
  /// In en, this message translates to:
  /// **'Create, share, and restore local backups'**
  String get createShareRestoreLocalBackups;

  /// No description provided for @storageSummaryFormat.
  ///
  /// In en, this message translates to:
  /// **'{bytes} · {summaryCount} summaries · {templateCount} templates'**
  String storageSummaryFormat(
      Object bytes, Object summaryCount, Object templateCount);

  /// No description provided for @backupSummaryNone.
  ///
  /// In en, this message translates to:
  /// **'No local backups yet. Tap to create one'**
  String get backupSummaryNone;

  /// No description provided for @backupSummaryAvailable.
  ///
  /// In en, this message translates to:
  /// **'{backupCount} local backups available'**
  String backupSummaryAvailable(Object backupCount);

  /// No description provided for @architectureChecksDebugOnly.
  ///
  /// In en, this message translates to:
  /// **'Architecture Checks - DEBUG ONLY'**
  String get architectureChecksDebugOnly;

  /// No description provided for @runArchitectureVerification.
  ///
  /// In en, this message translates to:
  /// **'Run architecture verification'**
  String get runArchitectureVerification;

  /// No description provided for @runArchitectureVerificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Verify that the new architecture is functioning correctly'**
  String get runArchitectureVerificationDescription;

  /// No description provided for @runningArchitectureVerification.
  ///
  /// In en, this message translates to:
  /// **'Running architecture verification...'**
  String get runningArchitectureVerification;

  /// No description provided for @architectureVerificationFinished.
  ///
  /// In en, this message translates to:
  /// **'Architecture verification finished. Check the console output.'**
  String get architectureVerificationFinished;

  /// No description provided for @inspectDatabase.
  ///
  /// In en, this message translates to:
  /// **'Inspect database'**
  String get inspectDatabase;

  /// No description provided for @inspectDatabaseDescription.
  ///
  /// In en, this message translates to:
  /// **'View raw records from summary and template storage'**
  String get inspectDatabaseDescription;

  /// No description provided for @notAllPermissionsGranted.
  ///
  /// In en, this message translates to:
  /// **'Not all permissions were granted. Gesture features may not work correctly.'**
  String get notAllPermissionsGranted;

  /// No description provided for @permissionsRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions required'**
  String get permissionsRequiredTitle;

  /// No description provided for @permissionsRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'To make gesture wake-up work correctly, grant the following permissions:\n\n1. Overlay permission: used to display the gesture detection area over other apps\n2. Usage Access permission: used to detect the current foreground app so gesture areas can appear in allowlisted apps\n\nPlease grant these permissions on the next screens.'**
  String get permissionsRequiredMessage;

  /// No description provided for @usageAccessPermissionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage Access permission required'**
  String get usageAccessPermissionRequiredTitle;

  /// No description provided for @usageAccessPermissionRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Usage Access permission is missing.\n\nWithout it:\n• The app cannot detect which app is currently active\n• Gesture wake-up will not work correctly in other apps\n\nTap \"Grant access\" to open system settings and enable the permission for this app.'**
  String get usageAccessPermissionRequiredMessage;

  /// No description provided for @floatingWindowServiceStarted.
  ///
  /// In en, this message translates to:
  /// **'Floating window service started'**
  String get floatingWindowServiceStarted;

  /// No description provided for @floatingWindowServiceStopped.
  ///
  /// In en, this message translates to:
  /// **'Floating window service stopped'**
  String get floatingWindowServiceStopped;

  /// No description provided for @failedToStartMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to start: {error}'**
  String failedToStartMessage(Object error);

  /// No description provided for @failedToStopMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to stop: {error}'**
  String failedToStopMessage(Object error);

  /// No description provided for @serviceStarted.
  ///
  /// In en, this message translates to:
  /// **'Service started'**
  String get serviceStarted;

  /// No description provided for @floatingWindowTips.
  ///
  /// In en, this message translates to:
  /// **'The floating gesture service is now running.\n\nUsage tips:\n1. Look for the semi-transparent gesture zones near the screen edges.\n2. Swipe inside those zones to launch the app quickly.\n3. If the overlay is missing, confirm that all required permissions were granted.\n\nImportant:\nIf gestures stop working after switching apps, check:\n- Whether the app is included in the allowlist\n- Whether Usage Access permission has been granted'**
  String get floatingWindowTips;

  /// No description provided for @openAllowlist.
  ///
  /// In en, this message translates to:
  /// **'Open allowlist'**
  String get openAllowlist;

  /// No description provided for @memoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Memory Management'**
  String get memoryManagement;

  /// No description provided for @loadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String loadFailedMessage(Object error);

  /// No description provided for @loadFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get loadFailedLabel;

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetails(Object error);

  /// No description provided for @deleteSummaryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteSummaryConfirm(Object title);

  /// No description provided for @deleteTemplateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete template \"{title}\"?'**
  String deleteTemplateConfirm(Object title);

  /// No description provided for @deleteFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailedMessage(Object error);

  /// No description provided for @templateDeleted.
  ///
  /// In en, this message translates to:
  /// **'Template deleted'**
  String get templateDeleted;

  /// No description provided for @currentView.
  ///
  /// In en, this message translates to:
  /// **'Current view'**
  String get currentView;

  /// No description provided for @allMemories.
  ///
  /// In en, this message translates to:
  /// **'All memories'**
  String get allMemories;

  /// No description provided for @searchFilter.
  ///
  /// In en, this message translates to:
  /// **'Search filter'**
  String get searchFilter;

  /// No description provided for @itemCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemCountLabel(Object count);

  /// No description provided for @notFiltered.
  ///
  /// In en, this message translates to:
  /// **'Not filtered'**
  String get notFiltered;

  /// No description provided for @filtered.
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get filtered;

  /// No description provided for @memoryType.
  ///
  /// In en, this message translates to:
  /// **'Memory type'**
  String get memoryType;

  /// No description provided for @metaImportanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Importance {percent}'**
  String metaImportanceLabel(Object percent);

  /// No description provided for @metaVisitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Visits {count}'**
  String metaVisitsLabel(Object count);

  /// No description provided for @metaUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String metaUpdatedLabel(Object date);

  /// No description provided for @metaLastOpenedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last opened {date}'**
  String metaLastOpenedLabel(Object date);

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// No description provided for @promoteToCore.
  ///
  /// In en, this message translates to:
  /// **'Promote to core'**
  String get promoteToCore;

  /// No description provided for @setAsCore.
  ///
  /// In en, this message translates to:
  /// **'Set as core'**
  String get setAsCore;

  /// No description provided for @setAsCoreMemory.
  ///
  /// In en, this message translates to:
  /// **'Set as core memory'**
  String get setAsCoreMemory;

  /// No description provided for @mergeSimilar.
  ///
  /// In en, this message translates to:
  /// **'Merge similar'**
  String get mergeSimilar;

  /// No description provided for @importanceScore.
  ///
  /// In en, this message translates to:
  /// **'Importance score'**
  String get importanceScore;

  /// No description provided for @refreshAndCleanup.
  ///
  /// In en, this message translates to:
  /// **'Refresh and clean up'**
  String get refreshAndCleanup;

  /// No description provided for @refreshCleanupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Refresh and cleanup completed'**
  String get refreshCleanupCompleted;

  /// No description provided for @promoteToCoreMemory.
  ///
  /// In en, this message translates to:
  /// **'Promote to core memory'**
  String get promoteToCoreMemory;

  /// No description provided for @promotionDialogBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will stop participating in regular forgetting decay and will be kept as a prioritized long-term memory.'**
  String promotionDialogBody(Object title);

  /// No description provided for @promotionStatsLine.
  ///
  /// In en, this message translates to:
  /// **'Current visits {accessCount} · importance {importancePercent}'**
  String promotionStatsLine(Object accessCount, Object importancePercent);

  /// No description provided for @promotionThresholdMet.
  ///
  /// In en, this message translates to:
  /// **'This memory already meets the automatic promotion threshold.'**
  String get promotionThresholdMet;

  /// No description provided for @promotionThresholdNotMet.
  ///
  /// In en, this message translates to:
  /// **'This memory does not meet the automatic threshold yet, but you can still pin it as a core memory manually.'**
  String get promotionThresholdNotMet;

  /// No description provided for @promotionThresholdLine.
  ///
  /// In en, this message translates to:
  /// **'Current automatic threshold: visits >= {accessCountThreshold} or importance >= {importanceThreshold}'**
  String promotionThresholdLine(
      Object accessCountThreshold, Object importanceThreshold);

  /// No description provided for @generatingPromotionReason.
  ///
  /// In en, this message translates to:
  /// **'Generating promotion reason...'**
  String get generatingPromotionReason;

  /// No description provided for @promotionReason.
  ///
  /// In en, this message translates to:
  /// **'Promotion reason'**
  String get promotionReason;

  /// No description provided for @defaultPromotionReason.
  ///
  /// In en, this message translates to:
  /// **'This memory already has lasting value and is suitable to preserve as a long-term core memory.'**
  String get defaultPromotionReason;

  /// No description provided for @upgradeReasonHighAccess.
  ///
  /// In en, this message translates to:
  /// **'This memory is accessed frequently and has demonstrated stable long-term value, making it a good candidate for promotion to core memory.'**
  String get upgradeReasonHighAccess;

  /// No description provided for @upgradeReasonHighImportance.
  ///
  /// In en, this message translates to:
  /// **'This memory has a high importance score and is worth retaining as a long-term core memory.'**
  String get upgradeReasonHighImportance;

  /// No description provided for @confirmPromotion.
  ///
  /// In en, this message translates to:
  /// **'Confirm promotion'**
  String get confirmPromotion;

  /// No description provided for @confirmSetAsCore.
  ///
  /// In en, this message translates to:
  /// **'Confirm set as core'**
  String get confirmSetAsCore;

  /// No description provided for @promotedToCoreMemory.
  ///
  /// In en, this message translates to:
  /// **'Promoted to core memory'**
  String get promotedToCoreMemory;

  /// No description provided for @setAsCoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Set as core memory'**
  String get setAsCoreSuccess;

  /// No description provided for @viewCore.
  ///
  /// In en, this message translates to:
  /// **'View core'**
  String get viewCore;

  /// No description provided for @noSimilarMemoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No similar memories found'**
  String get noSimilarMemoriesFound;

  /// No description provided for @currentFactMemory.
  ///
  /// In en, this message translates to:
  /// **'Original memory'**
  String get currentFactMemory;

  /// No description provided for @candidateFactMemory.
  ///
  /// In en, this message translates to:
  /// **'New memory'**
  String get candidateFactMemory;

  /// No description provided for @mergeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Merge completed'**
  String get mergeCompleted;

  /// No description provided for @chooseMemoryToCompare.
  ///
  /// In en, this message translates to:
  /// **'Choose a memory to compare'**
  String get chooseMemoryToCompare;

  /// No description provided for @mergeCandidateCount.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" has {count} merge candidate(s)'**
  String mergeCandidateCount(Object title, Object count);

  /// No description provided for @similarityWithContent.
  ///
  /// In en, this message translates to:
  /// **'Similarity {similarity} · {content}'**
  String similarityWithContent(Object similarity, Object content);

  /// No description provided for @deleteMemory.
  ///
  /// In en, this message translates to:
  /// **'Delete memory'**
  String get deleteMemory;

  /// No description provided for @deleteMemoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteMemoryConfirm(Object title);

  /// No description provided for @deletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deletedLabel;

  /// No description provided for @factMemories.
  ///
  /// In en, this message translates to:
  /// **'Fact memories'**
  String get factMemories;

  /// No description provided for @coreMemories.
  ///
  /// In en, this message translates to:
  /// **'Core memories'**
  String get coreMemories;

  /// No description provided for @sessionMemories.
  ///
  /// In en, this message translates to:
  /// **'Session memories'**
  String get sessionMemories;

  /// No description provided for @factMemoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Fact'**
  String get factMemoryLabel;

  /// No description provided for @coreMemoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get coreMemoryLabel;

  /// No description provided for @sessionMemoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get sessionMemoryLabel;

  /// No description provided for @factMemoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Ordinary facts and stable information that are worth keeping long term.'**
  String get factMemoryDescription;

  /// No description provided for @coreMemoryDescription.
  ///
  /// In en, this message translates to:
  /// **'The highest-priority long-term memories that do not participate in regular forgetting decay.'**
  String get coreMemoryDescription;

  /// No description provided for @sessionMemoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Temporary context from recent interactions that is useful for short-term organization.'**
  String get sessionMemoryDescription;

  /// No description provided for @relativeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String relativeMinutesAgo(Object count);

  /// No description provided for @relativeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String relativeHoursAgo(Object count);

  /// No description provided for @relativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String relativeDaysAgo(Object count);

  /// No description provided for @noMatchingMemories.
  ///
  /// In en, this message translates to:
  /// **'No matching memories'**
  String get noMatchingMemories;

  /// No description provided for @noFactMemoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No fact memories yet'**
  String get noFactMemoriesYet;

  /// No description provided for @noCoreMemoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No core memories yet'**
  String get noCoreMemoriesYet;

  /// No description provided for @noSessionMemoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No session memories yet'**
  String get noSessionMemoriesYet;

  /// No description provided for @mergeFactMemories.
  ///
  /// In en, this message translates to:
  /// **'Merge fact memories'**
  String get mergeFactMemories;

  /// No description provided for @mergeFactMemoriesDescription.
  ///
  /// In en, this message translates to:
  /// **'Compare both versions and choose the final title, content, and tags to keep.'**
  String get mergeFactMemoriesDescription;

  /// No description provided for @similarityPercent.
  ///
  /// In en, this message translates to:
  /// **'Similarity {percent}'**
  String similarityPercent(Object percent);

  /// No description provided for @mergedPreview.
  ///
  /// In en, this message translates to:
  /// **'Merged preview'**
  String get mergedPreview;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get noTags;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @mergingLabel.
  ///
  /// In en, this message translates to:
  /// **'Merging...'**
  String get mergingLabel;

  /// No description provided for @confirmMerge.
  ///
  /// In en, this message translates to:
  /// **'Confirm merge'**
  String get confirmMerge;

  /// No description provided for @keepOriginal.
  ///
  /// In en, this message translates to:
  /// **'Keep original'**
  String get keepOriginal;

  /// No description provided for @keepNew.
  ///
  /// In en, this message translates to:
  /// **'Keep new'**
  String get keepNew;

  /// No description provided for @smartMerge.
  ///
  /// In en, this message translates to:
  /// **'Smart merge'**
  String get smartMerge;

  /// No description provided for @emptyValue.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get emptyValue;

  /// No description provided for @candidateMemory.
  ///
  /// In en, this message translates to:
  /// **'Candidate memory'**
  String get candidateMemory;

  /// No description provided for @mergeFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Merge failed: {error}'**
  String mergeFailedMessage(Object error);

  /// No description provided for @clearModelCache.
  ///
  /// In en, this message translates to:
  /// **'Clear model cache'**
  String get clearModelCache;

  /// No description provided for @clearModelCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes local model inference cache files, but keeps summaries, templates, and the model file itself.'**
  String get clearModelCacheMessage;

  /// No description provided for @noModelCacheFilesToClear.
  ///
  /// In en, this message translates to:
  /// **'No model cache files to clear'**
  String get noModelCacheFilesToClear;

  /// No description provided for @clearedModelCacheResult.
  ///
  /// In en, this message translates to:
  /// **'Cleared {count} cache file(s) and freed {bytes}'**
  String clearedModelCacheResult(Object count, Object bytes);

  /// No description provided for @clearBackupFiles.
  ///
  /// In en, this message translates to:
  /// **'Clear backup files'**
  String get clearBackupFiles;

  /// No description provided for @clearBackupFilesMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes locally generated backup files without changing the current summaries or templates in the database.'**
  String get clearBackupFilesMessage;

  /// No description provided for @noBackupFilesToClear.
  ///
  /// In en, this message translates to:
  /// **'No backup files to clear'**
  String get noBackupFilesToClear;

  /// No description provided for @deletedBackupFilesResult.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} backup file(s) and freed {bytes}'**
  String deletedBackupFilesResult(Object count, Object bytes);

  /// No description provided for @failedToReadStorageUsage.
  ///
  /// In en, this message translates to:
  /// **'Failed to read storage usage: {error}'**
  String failedToReadStorageUsage(Object error);

  /// No description provided for @totalStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Total storage used'**
  String get totalStorageUsed;

  /// No description provided for @storageOverviewCounts.
  ///
  /// In en, this message translates to:
  /// **'{summaryCount} summaries · {templateCount} templates · {backupCount} backups'**
  String storageOverviewCounts(
      Object summaryCount, Object templateCount, Object backupCount);

  /// No description provided for @summaryDatabase.
  ///
  /// In en, this message translates to:
  /// **'Summary database'**
  String get summaryDatabase;

  /// No description provided for @summaryDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} summaries'**
  String summaryDatabaseSubtitle(Object count);

  /// No description provided for @templateDatabase.
  ///
  /// In en, this message translates to:
  /// **'Template database'**
  String get templateDatabase;

  /// No description provided for @templateDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} templates'**
  String templateDatabaseSubtitle(Object count);

  /// No description provided for @backupFiles.
  ///
  /// In en, this message translates to:
  /// **'Backup files'**
  String get backupFiles;

  /// No description provided for @backupFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} backups'**
  String backupFilesSubtitle(Object count);

  /// No description provided for @modelFile.
  ///
  /// In en, this message translates to:
  /// **'Model file'**
  String get modelFile;

  /// No description provided for @bundledModelFootprint.
  ///
  /// In en, this message translates to:
  /// **'Bundled model footprint'**
  String get bundledModelFootprint;

  /// No description provided for @modelCache.
  ///
  /// In en, this message translates to:
  /// **'Model cache'**
  String get modelCache;

  /// No description provided for @inferenceCacheAndIntermediateFiles.
  ///
  /// In en, this message translates to:
  /// **'Inference cache and intermediate files'**
  String get inferenceCacheAndIntermediateFiles;

  /// No description provided for @cleanupTools.
  ///
  /// In en, this message translates to:
  /// **'Cleanup tools'**
  String get cleanupTools;

  /// No description provided for @clearLocalBackupFiles.
  ///
  /// In en, this message translates to:
  /// **'Clear local backup files'**
  String get clearLocalBackupFiles;

  /// No description provided for @backupCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup created: {fileName}'**
  String backupCreatedMessage(Object fileName);

  /// No description provided for @failedToCreateBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup: {error}'**
  String failedToCreateBackupMessage(Object error);

  /// No description provided for @importFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailedMessage(Object error);

  /// No description provided for @importFailedUnableReadSelectedFile.
  ///
  /// In en, this message translates to:
  /// **'Import failed: unable to read the selected file'**
  String get importFailedUnableReadSelectedFile;

  /// No description provided for @unknownValue.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownValue;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importBackup;

  /// No description provided for @backupImportPreviewMessage.
  ///
  /// In en, this message translates to:
  /// **'This backup contains {summaryCount} summaries and {templateCount} templates.\nExported at: {exportedAt}\n\nImporting it will overwrite the current summary and template data. Continue?'**
  String backupImportPreviewMessage(
      Object summaryCount, Object templateCount, Object exportedAt);

  /// No description provided for @importFinishedMessage.
  ///
  /// In en, this message translates to:
  /// **'Import finished: {summaryCount} summaries, {templateCount} templates'**
  String importFinishedMessage(Object summaryCount, Object templateCount);

  /// No description provided for @invalidBackupFileFormat.
  ///
  /// In en, this message translates to:
  /// **'Import failed: invalid backup file format'**
  String get invalidBackupFileFormat;

  /// No description provided for @restoreBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Restoring will overwrite the current summary and template data. Continue?'**
  String get restoreBackupMessage;

  /// No description provided for @restoreFinishedMessage.
  ///
  /// In en, this message translates to:
  /// **'Restore finished: {summaryCount} summaries, {templateCount} templates'**
  String restoreFinishedMessage(Object summaryCount, Object templateCount);

  /// No description provided for @restoreFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailedMessage(Object error);

  /// No description provided for @deleteBackupConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete backup {fileName}?'**
  String deleteBackupConfirmMessage(Object fileName);

  /// No description provided for @backupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Backup deleted'**
  String get backupDeleted;

  /// No description provided for @failedToLoadBackupList.
  ///
  /// In en, this message translates to:
  /// **'Failed to load backup list: {error}'**
  String failedToLoadBackupList(Object error);

  /// No description provided for @noLocalBackupFilesYet.
  ///
  /// In en, this message translates to:
  /// **'No local backup files yet'**
  String get noLocalBackupFilesYet;

  /// No description provided for @localBackups.
  ///
  /// In en, this message translates to:
  /// **'Local backups'**
  String get localBackups;

  /// No description provided for @backupFilesAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} backup file(s) available'**
  String backupFilesAvailable(Object count);

  /// No description provided for @backupOverviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Creating a backup generates a JSON file and opens the share sheet. You can also import a backup file from outside the app.'**
  String get backupOverviewDescription;

  /// No description provided for @createAndShareBackup.
  ///
  /// In en, this message translates to:
  /// **'Create and share backup'**
  String get createAndShareBackup;

  /// No description provided for @importBackupData.
  ///
  /// In en, this message translates to:
  /// **'Import backup data'**
  String get importBackupData;

  /// No description provided for @shareBackupText.
  ///
  /// In en, this message translates to:
  /// **'Local Vault backup'**
  String get shareBackupText;

  /// No description provided for @shareBackupSubject.
  ///
  /// In en, this message translates to:
  /// **'Local Vault Backup'**
  String get shareBackupSubject;

  /// No description provided for @confirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmLabel;

  /// No description provided for @clearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLabel;

  /// No description provided for @runningLabel.
  ///
  /// In en, this message translates to:
  /// **'Running...'**
  String get runningLabel;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @statusEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get statusEnabled;

  /// No description provided for @statusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get statusDisabled;

  /// No description provided for @statusGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get statusGranted;

  /// No description provided for @statusNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Not granted'**
  String get statusNotGranted;

  /// No description provided for @statusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get statusRunning;

  /// No description provided for @statusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get statusStopped;

  /// No description provided for @statusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get statusUnavailable;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @statusMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get statusMissing;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusCompatible.
  ///
  /// In en, this message translates to:
  /// **'Compatible'**
  String get statusCompatible;

  /// No description provided for @statusIncompatible.
  ///
  /// In en, this message translates to:
  /// **'Incompatible'**
  String get statusIncompatible;

  /// No description provided for @statusInitialized.
  ///
  /// In en, this message translates to:
  /// **'Initialized'**
  String get statusInitialized;

  /// No description provided for @statusNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Not initialized'**
  String get statusNotInitialized;

  /// No description provided for @statusDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get statusDetected;

  /// No description provided for @statusNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Not detected'**
  String get statusNotDetected;

  /// No description provided for @statusModelUsed.
  ///
  /// In en, this message translates to:
  /// **'Model used'**
  String get statusModelUsed;

  /// No description provided for @statusModelNotUsed.
  ///
  /// In en, this message translates to:
  /// **'Model not used'**
  String get statusModelNotUsed;

  /// No description provided for @statusInitializationComplete.
  ///
  /// In en, this message translates to:
  /// **'Initialization complete'**
  String get statusInitializationComplete;

  /// No description provided for @statusInitializationIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Initialization incomplete'**
  String get statusInitializationIncomplete;

  /// No description provided for @gestureConfigurationSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get gestureConfigurationSaved;

  /// No description provided for @gestureConfigurationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load gesture configuration: {error}'**
  String gestureConfigurationLoadFailed(Object error);

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get resetToDefaults;

  /// No description provided for @resetGesturesToDefaultsMessage.
  ///
  /// In en, this message translates to:
  /// **'Reset all gestures back to the default configuration?'**
  String get resetGesturesToDefaultsMessage;

  /// No description provided for @restoredDefaultSettings.
  ///
  /// In en, this message translates to:
  /// **'Restored default settings'**
  String get restoredDefaultSettings;

  /// No description provided for @gestureShareOnly.
  ///
  /// In en, this message translates to:
  /// **'Share only'**
  String get gestureShareOnly;

  /// No description provided for @gestureActionOpenTemplates.
  ///
  /// In en, this message translates to:
  /// **'Open prompt templates'**
  String get gestureActionOpenTemplates;

  /// No description provided for @gestureActionSaveSummary.
  ///
  /// In en, this message translates to:
  /// **'Save a summary from shared content'**
  String get gestureActionSaveSummary;

  /// No description provided for @gestureActionOpenSavedContext.
  ///
  /// In en, this message translates to:
  /// **'Open saved context'**
  String get gestureActionOpenSavedContext;

  /// No description provided for @gestureDoubleTap.
  ///
  /// In en, this message translates to:
  /// **'Double tap'**
  String get gestureDoubleTap;

  /// No description provided for @gestureTripleTap.
  ///
  /// In en, this message translates to:
  /// **'Triple tap'**
  String get gestureTripleTap;

  /// No description provided for @triggerAction.
  ///
  /// In en, this message translates to:
  /// **'Trigger action'**
  String get triggerAction;

  /// No description provided for @alreadyUsedByAnotherGesture.
  ///
  /// In en, this message translates to:
  /// **'Already used by another gesture'**
  String get alreadyUsedByAnotherGesture;

  /// No description provided for @searchAppsHint.
  ///
  /// In en, this message translates to:
  /// **'Search apps...'**
  String get searchAppsHint;

  /// No description provided for @appWhitelistLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String appWhitelistLoadFailed(Object error);

  /// No description provided for @selectedAppsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} app(s) selected'**
  String selectedAppsCount(Object count);

  /// No description provided for @clearAllowlistTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear allowlist'**
  String get clearAllowlistTooltip;

  /// No description provided for @gesturesActiveInAllApps.
  ///
  /// In en, this message translates to:
  /// **'Gestures are active in all apps'**
  String get gesturesActiveInAllApps;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get filterSelected;

  /// No description provided for @filterUnselected.
  ///
  /// In en, this message translates to:
  /// **'Unselected'**
  String get filterUnselected;

  /// No description provided for @noAppsFound.
  ///
  /// In en, this message translates to:
  /// **'No apps found'**
  String get noAppsFound;

  /// No description provided for @noMatchingAppsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching apps found'**
  String get noMatchingAppsFound;

  /// No description provided for @noSelectedAppsYet.
  ///
  /// In en, this message translates to:
  /// **'No selected apps yet'**
  String get noSelectedAppsYet;

  /// No description provided for @noUnselectedApps.
  ///
  /// In en, this message translates to:
  /// **'No unselected apps'**
  String get noUnselectedApps;

  /// No description provided for @clearAllowlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear allowlist'**
  String get clearAllowlistTitle;

  /// No description provided for @clearAllowlistMessage.
  ///
  /// In en, this message translates to:
  /// **'Clear the app allowlist? Gestures will become active in all apps.'**
  String get clearAllowlistMessage;

  /// No description provided for @allowlistCleared.
  ///
  /// In en, this message translates to:
  /// **'Allowlist cleared'**
  String get allowlistCleared;

  /// No description provided for @databaseInspector.
  ///
  /// In en, this message translates to:
  /// **'Database Inspector'**
  String get databaseInspector;

  /// No description provided for @failedToOpenDatabase.
  ///
  /// In en, this message translates to:
  /// **'Failed to open database: {error}'**
  String failedToOpenDatabase(Object error);

  /// No description provided for @summariesTab.
  ///
  /// In en, this message translates to:
  /// **'Summaries'**
  String get summariesTab;

  /// No description provided for @templatesTab.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templatesTab;

  /// No description provided for @noSummaryRecordsInBox.
  ///
  /// In en, this message translates to:
  /// **'No summary records in this box'**
  String get noSummaryRecordsInBox;

  /// No description provided for @noTemplateRecordsInBox.
  ///
  /// In en, this message translates to:
  /// **'No template records in this box'**
  String get noTemplateRecordsInBox;

  /// No description provided for @recordsWithIssues.
  ///
  /// In en, this message translates to:
  /// **'Records with issues: {count}'**
  String recordsWithIssues(Object count);

  /// No description provided for @legacyTemplateTypes.
  ///
  /// In en, this message translates to:
  /// **'Legacy template types: {count}'**
  String legacyTemplateTypes(Object count);

  /// No description provided for @defaultTemplatesCount.
  ///
  /// In en, this message translates to:
  /// **'Default templates: {count}'**
  String defaultTemplatesCount(Object count);

  /// No description provided for @boxMetricLabel.
  ///
  /// In en, this message translates to:
  /// **'Box: {boxName}'**
  String boxMetricLabel(Object boxName);

  /// No description provided for @recordsMetricLabel.
  ///
  /// In en, this message translates to:
  /// **'Records: {count}'**
  String recordsMetricLabel(Object count);

  /// No description provided for @keyMetricLabel.
  ///
  /// In en, this message translates to:
  /// **'Key: {key}'**
  String keyMetricLabel(Object key);

  /// No description provided for @noObviousIssuesDetected.
  ///
  /// In en, this message translates to:
  /// **'No obvious issues detected'**
  String get noObviousIssuesDetected;

  /// No description provided for @issuesMetricLabel.
  ///
  /// In en, this message translates to:
  /// **'Issues: {count}'**
  String issuesMetricLabel(Object count);

  /// No description provided for @copyJson.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get copyJson;

  /// No description provided for @recordNotMapCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Record is not a Map and may be corrupted'**
  String get recordNotMapCorrupted;

  /// No description provided for @unparseableSummaryRecord.
  ///
  /// In en, this message translates to:
  /// **'Unparseable summary record'**
  String get unparseableSummaryRecord;

  /// No description provided for @unparseableTemplateRecord.
  ///
  /// In en, this message translates to:
  /// **'Unparseable template record'**
  String get unparseableTemplateRecord;

  /// No description provided for @rawTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Raw type: {type}'**
  String rawTypeLabel(Object type);

  /// No description provided for @legacyTemplateRecordDetected.
  ///
  /// In en, this message translates to:
  /// **'Legacy template-type record detected and will be read as a fact'**
  String get legacyTemplateRecordDetected;

  /// No description provided for @missingId.
  ///
  /// In en, this message translates to:
  /// **'Missing id'**
  String get missingId;

  /// No description provided for @titleIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Title is empty'**
  String get titleIsEmpty;

  /// No description provided for @contentIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Content is empty'**
  String get contentIsEmpty;

  /// No description provided for @accessCountInvalid.
  ///
  /// In en, this message translates to:
  /// **'accessCount is not a valid number'**
  String get accessCountInvalid;

  /// No description provided for @accessCountBelowZero.
  ///
  /// In en, this message translates to:
  /// **'accessCount is below 0'**
  String get accessCountBelowZero;

  /// No description provided for @createdAtCouldNotBeParsed.
  ///
  /// In en, this message translates to:
  /// **'createdAt could not be parsed'**
  String get createdAtCouldNotBeParsed;

  /// No description provided for @summaryDeserializationFailed.
  ///
  /// In en, this message translates to:
  /// **'SummaryEntity deserialization failed: {error}'**
  String summaryDeserializationFailed(Object error);

  /// No description provided for @templateDeserializationFailed.
  ///
  /// In en, this message translates to:
  /// **'TemplateEntity deserialization failed: {error}'**
  String templateDeserializationFailed(Object error);

  /// No description provided for @unknownTime.
  ///
  /// In en, this message translates to:
  /// **'Unknown time'**
  String get unknownTime;

  /// No description provided for @untitledSummary.
  ///
  /// In en, this message translates to:
  /// **'(Untitled summary)'**
  String get untitledSummary;

  /// No description provided for @untitledTemplate.
  ///
  /// In en, this message translates to:
  /// **'(Untitled template)'**
  String get untitledTemplate;

  /// No description provided for @summaryRecordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type: {type}  Access: {accessCount}  Created: {createdAt}'**
  String summaryRecordSubtitle(
      Object accessCount, Object createdAt, Object type);

  /// No description provided for @templateRecordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{templateKind}  Created: {createdAt}'**
  String templateRecordSubtitle(Object createdAt, Object templateKind);

  /// No description provided for @defaultTemplateLabel.
  ///
  /// In en, this message translates to:
  /// **'Default template'**
  String get defaultTemplateLabel;

  /// No description provided for @customTemplateLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom template'**
  String get customTemplateLabel;

  /// No description provided for @refreshDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Refresh diagnostics'**
  String get refreshDiagnostics;

  /// No description provided for @failedToLoadDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Failed to load diagnostics'**
  String get failedToLoadDiagnostics;

  /// No description provided for @gestureDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Gesture diagnostics'**
  String get gestureDiagnosticsTitle;

  /// No description provided for @gestureDiagnosticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh permission, service, and native sync state.'**
  String get gestureDiagnosticsDescription;

  /// No description provided for @slmDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'SLM diagnostics'**
  String get slmDiagnosticsTitle;

  /// No description provided for @slmDiagnosticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Inspect the current model, cache, and initialization state, then run a sample self-check inference.'**
  String get slmDiagnosticsDescription;

  /// No description provided for @allowlistedAppsLabel.
  ///
  /// In en, this message translates to:
  /// **'Allowlisted apps'**
  String get allowlistedAppsLabel;

  /// No description provided for @floatingGestureLauncherTitle.
  ///
  /// In en, this message translates to:
  /// **'Floating gesture launcher'**
  String get floatingGestureLauncherTitle;

  /// No description provided for @floatingGestureLauncherEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'The master gesture toggle in settings is enabled.'**
  String get floatingGestureLauncherEnabledDescription;

  /// No description provided for @floatingGestureLauncherDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'When the master toggle is off, double-tap and triple-tap gestures will not fire.'**
  String get floatingGestureLauncherDisabledDescription;

  /// No description provided for @overlayPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Overlay permission'**
  String get overlayPermissionTitle;

  /// No description provided for @overlayPermissionGrantedDescription.
  ///
  /// In en, this message translates to:
  /// **'The system allows the app to draw over other apps.'**
  String get overlayPermissionGrantedDescription;

  /// No description provided for @overlayPermissionDeniedDescription.
  ///
  /// In en, this message translates to:
  /// **'Without this permission, the floating overlay service cannot start normally.'**
  String get overlayPermissionDeniedDescription;

  /// No description provided for @usageAccessPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage Access permission'**
  String get usageAccessPermissionTitle;

  /// No description provided for @usageAccessGrantedDescription.
  ///
  /// In en, this message translates to:
  /// **'The app can identify the current foreground app for allowlist checks.'**
  String get usageAccessGrantedDescription;

  /// No description provided for @usageAccessDeniedDescription.
  ///
  /// In en, this message translates to:
  /// **'Without this permission, allowlist matching and cross-app gesture triggers will fail.'**
  String get usageAccessDeniedDescription;

  /// No description provided for @floatingServiceStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Floating service status'**
  String get floatingServiceStatusTitle;

  /// No description provided for @floatingServiceRunningDescription.
  ///
  /// In en, this message translates to:
  /// **'The native floating service is currently listening for gestures.'**
  String get floatingServiceRunningDescription;

  /// No description provided for @floatingServiceEnabledButStoppedDescription.
  ///
  /// In en, this message translates to:
  /// **'The master toggle is enabled, but the native floating service is not running right now.'**
  String get floatingServiceEnabledButStoppedDescription;

  /// No description provided for @floatingServiceStoppedDescription.
  ///
  /// In en, this message translates to:
  /// **'When the master toggle is off, the service usually remains stopped.'**
  String get floatingServiceStoppedDescription;

  /// No description provided for @floatingServiceUnavailableDescription.
  ///
  /// In en, this message translates to:
  /// **'The native service state could not be read.'**
  String get floatingServiceUnavailableDescription;

  /// No description provided for @doubleTapActionSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Double-tap action sync'**
  String get doubleTapActionSyncTitle;

  /// No description provided for @doubleTapActionSyncedDescription.
  ///
  /// In en, this message translates to:
  /// **'The double-tap action is synced to the native layer.'**
  String get doubleTapActionSyncedDescription;

  /// No description provided for @doubleTapActionOutOfSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'The current double-tap action does not match the native layer. Re-saving gesture settings is recommended.'**
  String get doubleTapActionOutOfSyncDescription;

  /// No description provided for @tripleTapActionSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Triple-tap action sync'**
  String get tripleTapActionSyncTitle;

  /// No description provided for @tripleTapActionSyncedDescription.
  ///
  /// In en, this message translates to:
  /// **'The triple-tap action is synced to the native layer.'**
  String get tripleTapActionSyncedDescription;

  /// No description provided for @tripleTapActionOutOfSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'The current triple-tap action does not match the native layer. Re-saving gesture settings is recommended.'**
  String get tripleTapActionOutOfSyncDescription;

  /// No description provided for @allowlistScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Allowlist scope'**
  String get allowlistScopeTitle;

  /// No description provided for @allAppsValue.
  ///
  /// In en, this message translates to:
  /// **'All apps'**
  String get allAppsValue;

  /// No description provided for @restrictedAppsValue.
  ///
  /// In en, this message translates to:
  /// **'Restricted to {count} app(s)'**
  String restrictedAppsValue(Object count);

  /// No description provided for @allowlistScopeAllAppsDescription.
  ///
  /// In en, this message translates to:
  /// **'Gestures currently attempt to work in every foreground app.'**
  String get allowlistScopeAllAppsDescription;

  /// No description provided for @allowlistScopeRestrictedDescription.
  ///
  /// In en, this message translates to:
  /// **'Only allowlisted foreground apps currently respond to gestures.'**
  String get allowlistScopeRestrictedDescription;

  /// No description provided for @allowlistNativeSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Allowlist native sync'**
  String get allowlistNativeSyncTitle;

  /// No description provided for @flutterNativeCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Flutter: {flutterCount} / Native: {nativeCount}'**
  String flutterNativeCountLabel(Object flutterCount, Object nativeCount);

  /// No description provided for @actionSyncValue.
  ///
  /// In en, this message translates to:
  /// **'Flutter: {flutterAction} / Native: {nativeAction}'**
  String actionSyncValue(Object flutterAction, Object nativeAction);

  /// No description provided for @allowlistNativeUnreadableDescription.
  ///
  /// In en, this message translates to:
  /// **'The native allowlist could not be read.'**
  String get allowlistNativeUnreadableDescription;

  /// No description provided for @allowlistNativeSyncedDescription.
  ///
  /// In en, this message translates to:
  /// **'The allowlist is synced to the native layer.'**
  String get allowlistNativeSyncedDescription;

  /// No description provided for @allowlistNativeOutOfSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Flutter and native allowlists are out of sync. Re-opening the allowlist page can trigger another sync.'**
  String get allowlistNativeOutOfSyncDescription;

  /// No description provided for @runtimeEnvironmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime environment'**
  String get runtimeEnvironmentTitle;

  /// No description provided for @environmentAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get environmentAndroid;

  /// No description provided for @environmentWeb.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get environmentWeb;

  /// No description provided for @environmentDesktop.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get environmentDesktop;

  /// No description provided for @runtimeEnvironmentAndroidDescription.
  ///
  /// In en, this message translates to:
  /// **'This environment meets the baseline conditions for attempting on-device SLM inference.'**
  String get runtimeEnvironmentAndroidDescription;

  /// No description provided for @runtimeEnvironmentNonAndroidDescription.
  ///
  /// In en, this message translates to:
  /// **'This is not an Android device environment. The self-check can still run, but it will usually follow the rule-based fallback path.'**
  String get runtimeEnvironmentNonAndroidDescription;

  /// No description provided for @experimentalNativeInferenceFlagTitle.
  ///
  /// In en, this message translates to:
  /// **'Experimental native inference flag'**
  String get experimentalNativeInferenceFlagTitle;

  /// No description provided for @experimentalNativeInferenceEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'The current app version defaults to pure rule mode; this state is kept only for future extensibility.'**
  String get experimentalNativeInferenceEnabledDescription;

  /// No description provided for @experimentalNativeInferenceDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'The current app version has switched to a pure rule engine, so the native inference path is no longer used.'**
  String get experimentalNativeInferenceDisabledDescription;

  /// No description provided for @nativeInferenceSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Native inference support'**
  String get nativeInferenceSupportTitle;

  /// No description provided for @nativeInferenceSupportAvailableDescription.
  ///
  /// In en, this message translates to:
  /// **'The required native symbols and runtime conditions for the current SLM inference path appear to be satisfied.'**
  String get nativeInferenceSupportAvailableDescription;

  /// No description provided for @nativeInferenceSupportUnavailableDescription.
  ///
  /// In en, this message translates to:
  /// **'This app version no longer provides native inference. Titles, tags, and topics are generated with local rules.'**
  String get nativeInferenceSupportUnavailableDescription;

  /// No description provided for @nativeSymbolDetectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Native symbol detection'**
  String get nativeSymbolDetectionTitle;

  /// No description provided for @nativeSymbolDetectedDescription.
  ///
  /// In en, this message translates to:
  /// **'The required LlmInferenceEngine symbols are visible.'**
  String get nativeSymbolDetectedDescription;

  /// No description provided for @nativeSymbolMissingDescription.
  ///
  /// In en, this message translates to:
  /// **'When critical native symbols are missing, model inference falls back to rule mode immediately.'**
  String get nativeSymbolMissingDescription;

  /// No description provided for @bundledModelFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Bundled model format'**
  String get bundledModelFormatTitle;

  /// No description provided for @slmInitializationStateTitle.
  ///
  /// In en, this message translates to:
  /// **'SLM initialization state'**
  String get slmInitializationStateTitle;

  /// No description provided for @slmInitializedDescription.
  ///
  /// In en, this message translates to:
  /// **'The service has already been initialized, so later self-checks reuse the current state.'**
  String get slmInitializedDescription;

  /// No description provided for @slmNotInitializedDescription.
  ///
  /// In en, this message translates to:
  /// **'Initialization has not been triggered yet. Running the self-check will attempt it automatically.'**
  String get slmNotInitializedDescription;

  /// No description provided for @modelAvailabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Model availability'**
  String get modelAvailabilityTitle;

  /// No description provided for @modelAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'Available now'**
  String get modelAvailableNow;

  /// No description provided for @usingRuleFallback.
  ///
  /// In en, this message translates to:
  /// **'Using rule fallback'**
  String get usingRuleFallback;

  /// No description provided for @modelAvailabilityAvailableDescription.
  ///
  /// In en, this message translates to:
  /// **'Model inference can already be used directly on this device.'**
  String get modelAvailabilityAvailableDescription;

  /// No description provided for @modelAvailabilityIncompatibleDescription.
  ///
  /// In en, this message translates to:
  /// **'The current model file format is incompatible with the current Android native SLM runtime, so runtime will stay on the rule fallback path until the bundled model is replaced.'**
  String get modelAvailabilityIncompatibleDescription;

  /// No description provided for @modelAvailabilityFallbackDescription.
  ///
  /// In en, this message translates to:
  /// **'The current app version uses local rules for title, tag, and topic generation and does not depend on on-device model inference.'**
  String get modelAvailabilityFallbackDescription;

  /// No description provided for @modelFileMissingDescription.
  ///
  /// In en, this message translates to:
  /// **'Current file path: {path}. If the file is missing, the runtime automatically falls back to rule mode.'**
  String modelFileMissingDescription(Object path);

  /// No description provided for @modelCacheRuntimeParametersTitle.
  ///
  /// In en, this message translates to:
  /// **'Model cache and runtime parameters'**
  String get modelCacheRuntimeParametersTitle;

  /// No description provided for @modelCacheRuntimeParametersDescription.
  ///
  /// In en, this message translates to:
  /// **'requestTimeout {requestTimeout}s · queueWait {queueWait}s · maxTokens {maxTokens}\nassetPath: {assetPath}'**
  String modelCacheRuntimeParametersDescription(Object assetPath,
      Object maxTokens, Object queueWait, Object requestTimeout);

  /// No description provided for @statusAndSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'{status} · {size}'**
  String statusAndSizeLabel(Object size, Object status);

  /// No description provided for @cacheSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'{size} · max cache entries {count}'**
  String cacheSummaryLabel(Object count, Object size);

  /// No description provided for @slmSelfCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'SLM self-check failed: {error}'**
  String slmSelfCheckFailed(Object error);

  /// No description provided for @slmSelfCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'SLM self-check'**
  String get slmSelfCheckTitle;

  /// No description provided for @slmSelfCheckAndroidHint.
  ///
  /// In en, this message translates to:
  /// **'It is best to run this once on a real Android device to confirm whether the model is actually being used.'**
  String get slmSelfCheckAndroidHint;

  /// No description provided for @slmSelfCheckNonAndroidHint.
  ///
  /// In en, this message translates to:
  /// **'This is not an Android device environment, so the self-check is mainly useful for validating fallback behavior and configuration state.'**
  String get slmSelfCheckNonAndroidHint;

  /// No description provided for @runSelfCheck.
  ///
  /// In en, this message translates to:
  /// **'Run self-check'**
  String get runSelfCheck;

  /// No description provided for @noSelfCheckYet.
  ///
  /// In en, this message translates to:
  /// **'No self-check has been run yet. Running one on the target device is recommended to verify whether topic extraction and title/tag generation use the model or rule fallback.'**
  String get noSelfCheckYet;

  /// No description provided for @completedChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed {time}'**
  String completedChipLabel(Object time);

  /// No description provided for @topicExtraction.
  ///
  /// In en, this message translates to:
  /// **'Topic extraction'**
  String get topicExtraction;

  /// No description provided for @titleAndTagGeneration.
  ///
  /// In en, this message translates to:
  /// **'Title and tag generation'**
  String get titleAndTagGeneration;

  /// No description provided for @fallbackDetailLabel.
  ///
  /// In en, this message translates to:
  /// **'fallback: {mode} · {latency}ms'**
  String fallbackDetailLabel(Object latency, Object mode);

  /// No description provided for @tagsDetailLabel.
  ///
  /// In en, this message translates to:
  /// **'tags: {tags}'**
  String tagsDetailLabel(Object tags);

  /// No description provided for @fallbackModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get fallbackModel;

  /// No description provided for @fallbackCache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get fallbackCache;

  /// No description provided for @fallbackRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get fallbackRules;

  /// No description provided for @fallbackDisabledUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Disabled/Unavailable'**
  String get fallbackDisabledUnavailable;

  /// No description provided for @summaryBannerErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Issues were found that can directly break gesture behavior'**
  String get summaryBannerErrorTitle;

  /// No description provided for @summaryBannerErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Permission-related issues should usually be fixed first.'**
  String get summaryBannerErrorDescription;

  /// No description provided for @summaryBannerWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Some gesture configuration issues need attention'**
  String get summaryBannerWarningTitle;

  /// No description provided for @summaryBannerWarningDescription.
  ///
  /// In en, this message translates to:
  /// **'When sync state or service state drifts, gestures may not trigger as expected.'**
  String get summaryBannerWarningDescription;

  /// No description provided for @summaryBannerHealthyTitle.
  ///
  /// In en, this message translates to:
  /// **'No obvious gesture issues were found'**
  String get summaryBannerHealthyTitle;

  /// No description provided for @summaryBannerHealthyDescription.
  ///
  /// In en, this message translates to:
  /// **'Permissions, service state, and native synchronization all look healthy.'**
  String get summaryBannerHealthyDescription;

  /// No description provided for @ocrRecognitionTitlePrefix.
  ///
  /// In en, this message translates to:
  /// **'OCR Recognition'**
  String get ocrRecognitionTitlePrefix;

  /// No description provided for @ocrRecognizedCharacters.
  ///
  /// In en, this message translates to:
  /// **'Recognized {count} characters'**
  String ocrRecognizedCharacters(Object count);

  /// No description provided for @ocrFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'OCR failed: {error}'**
  String ocrFailedMessage(Object error);

  /// No description provided for @ocrProcessingFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'OCR processing failed: {error}'**
  String ocrProcessingFailedMessage(Object error);

  /// No description provided for @unableToReadImageFile.
  ///
  /// In en, this message translates to:
  /// **'Unable to read image file'**
  String get unableToReadImageFile;

  /// No description provided for @previewEnterContent.
  ///
  /// In en, this message translates to:
  /// **'Enter content to preview suggested titles and tags'**
  String get previewEnterContent;

  /// No description provided for @previewGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Preview generation failed: {error}'**
  String previewGenerationFailed(Object error);

  /// No description provided for @previewApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied preview title and tags to the form'**
  String get previewApplied;

  /// No description provided for @contentRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Content is required'**
  String get contentRequiredMessage;

  /// No description provided for @summaryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Summary updated'**
  String get summaryUpdated;

  /// No description provided for @duplicateFactMemoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Detected a duplicate fact memory and updated the existing record'**
  String get duplicateFactMemoryUpdated;

  /// No description provided for @savedAndMergedFactMemories.
  ///
  /// In en, this message translates to:
  /// **'Saved and merged the fact memories'**
  String get savedAndMergedFactMemories;

  /// No description provided for @saveFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailedMessage(Object error);

  /// No description provided for @mergeCandidatesFound.
  ///
  /// In en, this message translates to:
  /// **'Merge candidates found'**
  String get mergeCandidatesFound;

  /// No description provided for @mergeCandidatesFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" was saved. Review these merge candidates:'**
  String mergeCandidatesFoundDescription(Object title);

  /// No description provided for @laterLabel.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get laterLabel;

  /// No description provided for @grantAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get grantAccessLabel;

  /// No description provided for @existingFactMemory.
  ///
  /// In en, this message translates to:
  /// **'Existing fact memory'**
  String get existingFactMemory;

  /// No description provided for @newFactMemory.
  ///
  /// In en, this message translates to:
  /// **'New fact memory'**
  String get newFactMemory;

  /// No description provided for @editSummary.
  ///
  /// In en, this message translates to:
  /// **'Edit summary'**
  String get editSummary;

  /// No description provided for @saveContent.
  ///
  /// In en, this message translates to:
  /// **'Save content'**
  String get saveContent;

  /// No description provided for @sharedBadge.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get sharedBadge;

  /// No description provided for @remarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remarkLabel;

  /// No description provided for @enterTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get enterTitleHint;

  /// No description provided for @contentShareHint.
  ///
  /// In en, this message translates to:
  /// **'Content shared from other apps will appear here automatically'**
  String get contentShareHint;

  /// No description provided for @remarkHint.
  ///
  /// In en, this message translates to:
  /// **'Add optional context or notes'**
  String get remarkHint;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Separate multiple tags with commas'**
  String get tagsHint;

  /// No description provided for @previewSuggestedTitleTags.
  ///
  /// In en, this message translates to:
  /// **'Preview suggested title and tags'**
  String get previewSuggestedTitleTags;

  /// No description provided for @previewSuggestedTitleTagsDescription.
  ///
  /// In en, this message translates to:
  /// **'When enabled, suggestions are generated from the current content without overwriting your form automatically'**
  String get previewSuggestedTitleTagsDescription;

  /// No description provided for @updateSummary.
  ///
  /// In en, this message translates to:
  /// **'Update summary'**
  String get updateSummary;

  /// No description provided for @requiredFieldHint.
  ///
  /// In en, this message translates to:
  /// **'* indicates a required field'**
  String get requiredFieldHint;

  /// No description provided for @saveResultPreview.
  ///
  /// In en, this message translates to:
  /// **'Save result preview'**
  String get saveResultPreview;

  /// No description provided for @previewPrimaryDescription.
  ///
  /// In en, this message translates to:
  /// **'The preview recommends titles and tags based primarily on the main content.'**
  String get previewPrimaryDescription;

  /// No description provided for @suggestedTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested title'**
  String get suggestedTitle;

  /// No description provided for @suggestedTags.
  ///
  /// In en, this message translates to:
  /// **'Suggested tags'**
  String get suggestedTags;

  /// No description provided for @applyToForm.
  ///
  /// In en, this message translates to:
  /// **'Apply to form'**
  String get applyToForm;

  /// No description provided for @generatedByBuiltInModel.
  ///
  /// In en, this message translates to:
  /// **'Generated by the native SLM runtime'**
  String get generatedByBuiltInModel;

  /// No description provided for @generatedByLocalRules.
  ///
  /// In en, this message translates to:
  /// **'Generated by local rules'**
  String get generatedByLocalRules;

  /// No description provided for @pendingSummary.
  ///
  /// In en, this message translates to:
  /// **'Pending summary'**
  String get pendingSummary;

  /// No description provided for @temporaryTopic.
  ///
  /// In en, this message translates to:
  /// **'Temporary topic'**
  String get temporaryTopic;

  /// No description provided for @generalTopic.
  ///
  /// In en, this message translates to:
  /// **'General topic'**
  String get generalTopic;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @unknownModelFormat.
  ///
  /// In en, this message translates to:
  /// **'Unknown model format'**
  String get unknownModelFormat;

  /// No description provided for @modelFormatBundledSupported.
  ///
  /// In en, this message translates to:
  /// **'Bundled .{extension} asset detected. Local rule mode can continue without a native runtime.'**
  String modelFormatBundledSupported(Object extension);

  /// No description provided for @modelFormatUnsupportedForLocalRules.
  ///
  /// In en, this message translates to:
  /// **'Unsupported .{extension} asset for the current local rule mode.'**
  String modelFormatUnsupportedForLocalRules(Object extension);

  /// No description provided for @slmSelfCheckTopicSampleContent.
  ///
  /// In en, this message translates to:
  /// **'This diagnostic sample verifies that local rule-based topic extraction works on this device.'**
  String get slmSelfCheckTopicSampleContent;

  /// No description provided for @slmSelfCheckMetadataSampleContent.
  ///
  /// In en, this message translates to:
  /// **'This diagnostic sample verifies title and tag generation in the current Local Vault environment. Produce a searchable title and 2 to 4 tags.'**
  String get slmSelfCheckMetadataSampleContent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'ja',
        'ko',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
