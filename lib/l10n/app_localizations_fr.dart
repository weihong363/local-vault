// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Bibliothèque de Mémoire Locale';

  @override
  String get home => 'Accueil';

  @override
  String get templates => 'Modèles';

  @override
  String get chooseTemplate => 'Choisir un modèle';

  @override
  String get addTemplate => 'Ajouter un modèle';

  @override
  String get editTemplate => 'Modifier le modèle';

  @override
  String get memory => 'Mémoire';

  @override
  String get myMemories => 'Mes mémoires';

  @override
  String get settings => 'Paramètres';

  @override
  String get search => 'Rechercher';

  @override
  String get save => 'Enregistrer';

  @override
  String get saveSummaryQuickActionTitle => 'Enregistrer le résumé';

  @override
  String get inject => 'Injecter';

  @override
  String get generalSettings => 'Paramètres généraux';

  @override
  String get themeSettings => 'Paramètres de thème';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get systemMode => 'Système';

  @override
  String get language => 'Langue';

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
  String get storageSettings => 'Paramètres de stockage';

  @override
  String get storageSpace => 'Espace de stockage';

  @override
  String get backupData => 'Sauvegarder les données';

  @override
  String get about => 'À propos';

  @override
  String get versionInfo => 'Informations de version';

  @override
  String get feedback => 'Commentaires';

  @override
  String get inDevelopment => 'En développement';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get title => 'Titre';

  @override
  String get content => 'Contenu';

  @override
  String get tags => 'Étiquettes';

  @override
  String get saveToVault => 'Enregistrer dans le coffre';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get savedToVault => 'Enregistré dans le coffre';

  @override
  String get titleAndContentRequired =>
      'Le titre et le contenu sont obligatoires';

  @override
  String get commaSeparatedTagsHint => 'Étiquettes (séparées par des virgules)';

  @override
  String get searchHint => 'Rechercher titre, contenu ou étiquettes...';

  @override
  String get noSearchResults => 'Aucun résultat de recherche';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get noTemplatesYet => 'Aucun modèle pour le moment';

  @override
  String get noSummariesYet => 'Aucune mémoire pour le moment';

  @override
  String get navHome => 'Accueil';

  @override
  String get navTemplates => 'Modèles';

  @override
  String get navMemory => 'Mémoire';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get refresh => 'Actualiser';

  @override
  String get cancelLabel => 'Annuler';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get deleteLabel => 'Supprimer';

  @override
  String get deleteSummary => 'Supprimer le résumé';

  @override
  String get deleteTemplate => 'Supprimer le modèle';

  @override
  String get shareLabel => 'Partager';

  @override
  String get restoreLabel => 'Restaurer';

  @override
  String get retryLabel => 'Réessayer';

  @override
  String get closeLabel => 'Fermer';

  @override
  String get workingLabel => 'Traitement...';

  @override
  String get okLabel => 'OK';

  @override
  String get quickSave => 'Enregistrement rapide';

  @override
  String get manualInput => 'Saisie manuelle';

  @override
  String get quickSaveClipboardTip =>
      'Astuce : l\'enregistrement rapide utilisera automatiquement le texte du presse-papiers.\nS\'il est vide, vous pouvez saisir le contenu manuellement.';

  @override
  String get invalidActionType => 'Type d\'action invalide';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get enableFloatingGestureLauncher =>
      'Activer le lanceur gestuel flottant';

  @override
  String get floatingGestureLauncherDescription =>
      'Ouvrir rapidement l\'application avec des gestes depuis d\'autres applications';

  @override
  String get gestureConfiguration => 'Configuration des gestes';

  @override
  String get gestureConfigurationDescription =>
      'Personnaliser le comportement des gestes';

  @override
  String get appAllowlist => 'Liste des applications autorisées';

  @override
  String get appAllowlistDescription =>
      'Les gestes ne sont actifs que dans les applications sélectionnées';

  @override
  String get diagnostics => 'Diagnostic';

  @override
  String get diagnosticsDescription =>
      'Vérifier les autorisations, services et l\'état de synchronisation des gestes';

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
      'Le titre et les étiquettes utilisent maintenant le modèle intégré';

  @override
  String get titleTagsUseLocalRuleGenerator =>
      'Le titre et les étiquettes utilisent maintenant le générateur local basé sur des règles';

  @override
  String get storageSummaryTapToView =>
      'Touchez pour voir les détails du stockage';

  @override
  String get createShareRestoreLocalBackups =>
      'Créer, partager et restaurer des sauvegardes locales';

  @override
  String storageSummaryFormat(
      Object bytes, Object summaryCount, Object templateCount) {
    return '$bytes · $summaryCount résumés · $templateCount modèles';
  }

  @override
  String get backupSummaryNone =>
      'Aucune sauvegarde locale pour le moment. Touchez pour en créer une';

  @override
  String backupSummaryAvailable(Object backupCount) {
    return '$backupCount sauvegarde(s) locale(s) disponible(s)';
  }

  @override
  String get architectureChecksDebugOnly =>
      'Vérifications d\'architecture - DEBUG UNIQUEMENT';

  @override
  String get runArchitectureVerification =>
      'Lancer la vérification d\'architecture';

  @override
  String get runArchitectureVerificationDescription =>
      'Vérifier que la nouvelle architecture fonctionne correctement';

  @override
  String get runningArchitectureVerification =>
      'Vérification d\'architecture en cours...';

  @override
  String get architectureVerificationFinished =>
      'La vérification d\'architecture est terminée. Consultez la sortie de la console.';

  @override
  String get inspectDatabase => 'Inspecter la base de données';

  @override
  String get inspectDatabaseDescription =>
      'Afficher les enregistrements bruts du stockage des résumés et des modèles';

  @override
  String get notAllPermissionsGranted =>
      'Toutes les autorisations n\'ont pas été accordées. Les gestes risquent de ne pas fonctionner correctement.';

  @override
  String get floatingWindowServiceStarted =>
      'Le service de fenêtre flottante a démarré';

  @override
  String get floatingWindowServiceStopped =>
      'Le service de fenêtre flottante a été arrêté';

  @override
  String failedToStartMessage(Object error) {
    return 'Échec du démarrage : $error';
  }

  @override
  String failedToStopMessage(Object error) {
    return 'Échec de l\'arrêt : $error';
  }

  @override
  String get serviceStarted => 'Service démarré';

  @override
  String get floatingWindowTips =>
      'Le service de gestes flottants fonctionne maintenant.\n\nConseils d\'utilisation :\n1. Recherchez les zones de geste semi-transparentes près des bords de l\'écran.\n2. Balayez dans ces zones pour lancer rapidement l\'application.\n3. Si la surcouche est absente, vérifiez que toutes les autorisations requises ont été accordées.\n\nImportant :\nSi les gestes cessent de fonctionner après un changement d\'application, vérifiez :\n- si l\'application figure dans la liste autorisée\n- si l\'autorisation d\'accès à l\'utilisation a été accordée';

  @override
  String get openAllowlist => 'Ouvrir la liste autorisée';

  @override
  String get memoryManagement => 'Gestion de la mémoire';

  @override
  String loadFailedMessage(Object error) {
    return 'Échec du chargement : $error';
  }

  @override
  String get loadFailedLabel => 'Échec du chargement';

  @override
  String errorWithDetails(Object error) {
    return 'Erreur : $error';
  }

  @override
  String deleteSummaryConfirm(Object title) {
    return 'Supprimer le résumé \"$title\" ?';
  }

  @override
  String deleteTemplateConfirm(Object title) {
    return 'Supprimer le modèle \"$title\" ?';
  }

  @override
  String deleteFailedMessage(Object error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String get templateDeleted => 'Modèle supprimé';

  @override
  String get currentView => 'Vue actuelle';

  @override
  String get allMemories => 'Toutes les mémoires';

  @override
  String get searchFilter => 'Filtre de recherche';

  @override
  String itemCountLabel(Object count) {
    return '$count éléments';
  }

  @override
  String get notFiltered => 'Non filtré';

  @override
  String get filtered => 'Filtré';

  @override
  String get memoryType => 'Type de mémoire';

  @override
  String metaImportanceLabel(Object percent) {
    return 'Importance $percent';
  }

  @override
  String metaVisitsLabel(Object count) {
    return 'Consultations $count';
  }

  @override
  String metaUpdatedLabel(Object date) {
    return 'Mis à jour $date';
  }

  @override
  String metaLastOpenedLabel(Object date) {
    return 'Dernière ouverture $date';
  }

  @override
  String get editLabel => 'Modifier';

  @override
  String get promoteToCore => 'Promouvoir en noyau';

  @override
  String get setAsCore => 'Définir comme noyau';

  @override
  String get setAsCoreMemory => 'Définir comme mémoire noyau';

  @override
  String get mergeSimilar => 'Fusionner les similaires';

  @override
  String get importanceScore => 'Score d\'importance';

  @override
  String get refreshAndCleanup => 'Actualiser et nettoyer';

  @override
  String get refreshCleanupCompleted => 'Actualisation et nettoyage terminés';

  @override
  String get promoteToCoreMemory => 'Promouvoir en mémoire noyau';

  @override
  String promotionDialogBody(Object title) {
    return '\"$title\" ne participera plus à l\'oubli régulier et sera conservé comme mémoire prioritaire à long terme.';
  }

  @override
  String promotionStatsLine(Object accessCount, Object importancePercent) {
    return 'Consultations actuelles $accessCount · importance $importancePercent';
  }

  @override
  String get promotionThresholdMet =>
      'Cette mémoire atteint déjà le seuil de promotion automatique.';

  @override
  String get promotionThresholdNotMet =>
      'Cette mémoire n\'atteint pas encore le seuil automatique, mais vous pouvez quand même l\'épingler manuellement comme mémoire noyau.';

  @override
  String promotionThresholdLine(
      Object accessCountThreshold, Object importanceThreshold) {
    return 'Seuil automatique actuel : consultations >= $accessCountThreshold ou importance >= $importanceThreshold';
  }

  @override
  String get generatingPromotionReason =>
      'Génération de la raison de promotion...';

  @override
  String get promotionReason => 'Raison de promotion';

  @override
  String get defaultPromotionReason =>
      'Cette mémoire a déjà une valeur durable et mérite d\'être conservée comme mémoire noyau à long terme.';

  @override
  String get upgradeReasonHighAccess =>
      'Cette mémoire est consultée fréquemment et a démontré une valeur stable à long terme, ce qui en fait une bonne candidate à la promotion en mémoire noyau.';

  @override
  String get upgradeReasonHighImportance =>
      'Cette mémoire a un score d\'importance élevé et mérite d\'être conservée comme mémoire noyau à long terme.';

  @override
  String get confirmPromotion => 'Confirmer la promotion';

  @override
  String get confirmSetAsCore => 'Confirmer comme noyau';

  @override
  String get promotedToCoreMemory => 'Promue en mémoire noyau';

  @override
  String get setAsCoreSuccess => 'Définie comme mémoire noyau';

  @override
  String get viewCore => 'Voir le noyau';

  @override
  String get noSimilarMemoriesFound => 'Aucune mémoire similaire trouvée';

  @override
  String get currentFactMemory => 'Mémoire factuelle actuelle';

  @override
  String get candidateFactMemory => 'Mémoire factuelle candidate';

  @override
  String get mergeCompleted => 'Fusion terminée';

  @override
  String get chooseMemoryToCompare => 'Choisissez une mémoire à comparer';

  @override
  String mergeCandidateCount(Object title, Object count) {
    return '\"$title\" a $count candidat(s) à la fusion';
  }

  @override
  String similarityWithContent(Object similarity, Object content) {
    return 'Similarité $similarity · $content';
  }

  @override
  String get deleteMemory => 'Supprimer la mémoire';

  @override
  String deleteMemoryConfirm(Object title) {
    return 'Supprimer \"$title\" ?';
  }

  @override
  String get deletedLabel => 'Supprimé';

  @override
  String get factMemories => 'Mémoires factuelles';

  @override
  String get coreMemories => 'Mémoires noyau';

  @override
  String get sessionMemories => 'Mémoires de session';

  @override
  String get factMemoryLabel => 'Fait';

  @override
  String get coreMemoryLabel => 'Noyau';

  @override
  String get sessionMemoryLabel => 'Session';

  @override
  String get factMemoryDescription =>
      'Faits ordinaires et informations stables qu\'il vaut la peine de conserver à long terme.';

  @override
  String get coreMemoryDescription =>
      'Les mémoires à long terme de priorité maximale qui ne participent pas à l\'oubli régulier.';

  @override
  String get sessionMemoryDescription =>
      'Contexte temporaire des interactions récentes utile pour l\'organisation à court terme.';

  @override
  String relativeMinutesAgo(Object count) {
    return 'il y a $count min';
  }

  @override
  String relativeHoursAgo(Object count) {
    return 'il y a $count h';
  }

  @override
  String relativeDaysAgo(Object count) {
    return 'il y a $count j';
  }

  @override
  String get noMatchingMemories => 'Aucune mémoire correspondante';

  @override
  String get noFactMemoriesYet => 'Aucune mémoire factuelle pour le moment';

  @override
  String get noCoreMemoriesYet => 'Aucune mémoire noyau pour le moment';

  @override
  String get noSessionMemoriesYet => 'Aucune mémoire de session pour le moment';

  @override
  String get mergeFactMemories => 'Fusionner les mémoires factuelles';

  @override
  String get mergeFactMemoriesDescription =>
      'Comparez les deux versions et choisissez le titre, le contenu et les étiquettes finaux à conserver.';

  @override
  String similarityPercent(Object percent) {
    return 'Similarité $percent';
  }

  @override
  String get mergedPreview => 'Aperçu fusionné';

  @override
  String get noTags => 'Aucune étiquette';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get mergingLabel => 'Fusion...';

  @override
  String get confirmMerge => 'Confirmer la fusion';

  @override
  String get keepOriginal => 'Garder l\'original';

  @override
  String get keepNew => 'Garder le nouveau';

  @override
  String get smartMerge => 'Fusion intelligente';

  @override
  String get emptyValue => 'Vide';

  @override
  String get candidateMemory => 'Mémoire candidate';

  @override
  String mergeFailedMessage(Object error) {
    return 'Échec de la fusion : $error';
  }

  @override
  String get clearModelCache => 'Vider le cache du modèle';

  @override
  String get clearModelCacheMessage =>
      'Cela supprime les fichiers locaux de cache d\'inférence du modèle, mais conserve les résumés, les modèles et le fichier du modèle lui-même.';

  @override
  String get noModelCacheFilesToClear =>
      'Aucun fichier de cache du modèle à supprimer';

  @override
  String clearedModelCacheResult(Object count, Object bytes) {
    return '$count fichier(s) de cache supprimé(s) et $bytes libérés';
  }

  @override
  String get clearBackupFiles => 'Supprimer les fichiers de sauvegarde';

  @override
  String get clearBackupFilesMessage =>
      'Cela supprime les fichiers de sauvegarde générés localement sans modifier les résumés ou modèles actuels dans la base de données.';

  @override
  String get noBackupFilesToClear => 'Aucun fichier de sauvegarde à supprimer';

  @override
  String deletedBackupFilesResult(Object count, Object bytes) {
    return '$count fichier(s) de sauvegarde supprimé(s) et $bytes libérés';
  }

  @override
  String failedToReadStorageUsage(Object error) {
    return 'Impossible de lire l\'utilisation du stockage : $error';
  }

  @override
  String get totalStorageUsed => 'Stockage total utilisé';

  @override
  String storageOverviewCounts(
      Object summaryCount, Object templateCount, Object backupCount) {
    return '$summaryCount résumés · $templateCount modèles · $backupCount sauvegardes';
  }

  @override
  String get summaryDatabase => 'Base de données des résumés';

  @override
  String summaryDatabaseSubtitle(Object count) {
    return '$count résumés';
  }

  @override
  String get templateDatabase => 'Base de données des modèles';

  @override
  String templateDatabaseSubtitle(Object count) {
    return '$count modèles';
  }

  @override
  String get backupFiles => 'Fichiers de sauvegarde';

  @override
  String backupFilesSubtitle(Object count) {
    return '$count sauvegardes';
  }

  @override
  String get modelFile => 'Fichier du modèle';

  @override
  String get bundledModelFootprint => 'Empreinte du modèle intégré';

  @override
  String get modelCache => 'Cache du modèle';

  @override
  String get inferenceCacheAndIntermediateFiles =>
      'Cache d\'inférence et fichiers intermédiaires';

  @override
  String get cleanupTools => 'Outils de nettoyage';

  @override
  String get clearLocalBackupFiles => 'Supprimer les sauvegardes locales';

  @override
  String backupCreatedMessage(Object fileName) {
    return 'Sauvegarde créée : $fileName';
  }

  @override
  String failedToCreateBackupMessage(Object error) {
    return 'Échec de la création de la sauvegarde : $error';
  }

  @override
  String importFailedMessage(Object error) {
    return 'Échec de l\'importation : $error';
  }

  @override
  String get importFailedUnableReadSelectedFile =>
      'Échec de l\'importation : impossible de lire le fichier sélectionné';

  @override
  String get unknownValue => 'Inconnu';

  @override
  String get importBackup => 'Importer une sauvegarde';

  @override
  String backupImportPreviewMessage(
      Object summaryCount, Object templateCount, Object exportedAt) {
    return 'Cette sauvegarde contient $summaryCount résumés et $templateCount modèles.\nExportée le : $exportedAt\n\nL\'importation écrasera les données actuelles des résumés et des modèles. Continuer ?';
  }

  @override
  String importFinishedMessage(Object summaryCount, Object templateCount) {
    return 'Importation terminée : $summaryCount résumés, $templateCount modèles';
  }

  @override
  String get invalidBackupFileFormat =>
      'Échec de l\'importation : format de sauvegarde invalide';

  @override
  String get restoreBackupMessage =>
      'La restauration écrasera les données actuelles des résumés et des modèles. Continuer ?';

  @override
  String restoreFinishedMessage(Object summaryCount, Object templateCount) {
    return 'Restauration terminée : $summaryCount résumés, $templateCount modèles';
  }

  @override
  String restoreFailedMessage(Object error) {
    return 'Échec de la restauration : $error';
  }

  @override
  String deleteBackupConfirmMessage(Object fileName) {
    return 'Supprimer la sauvegarde $fileName ?';
  }

  @override
  String get backupDeleted => 'Sauvegarde supprimée';

  @override
  String failedToLoadBackupList(Object error) {
    return 'Impossible de charger la liste des sauvegardes : $error';
  }

  @override
  String get noLocalBackupFilesYet =>
      'Aucun fichier de sauvegarde local pour le moment';

  @override
  String get localBackups => 'Sauvegardes locales';

  @override
  String backupFilesAvailable(Object count) {
    return '$count fichier(s) de sauvegarde disponible(s)';
  }

  @override
  String get backupOverviewDescription =>
      'Créer une sauvegarde génère un fichier JSON et ouvre la feuille de partage. Vous pouvez aussi importer un fichier de sauvegarde depuis l\'extérieur de l\'application.';

  @override
  String get createAndShareBackup => 'Créer et partager une sauvegarde';

  @override
  String get importBackupData => 'Importer des données de sauvegarde';

  @override
  String get shareBackupText => 'Sauvegarde Local Vault';

  @override
  String get shareBackupSubject => 'Sauvegarde Local Vault';

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
