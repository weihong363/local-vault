// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Biblioteca de Memoria Local';

  @override
  String get home => 'Inicio';

  @override
  String get templates => 'Plantillas';

  @override
  String get chooseTemplate => 'Elegir plantilla';

  @override
  String get addTemplate => 'Agregar plantilla';

  @override
  String get editTemplate => 'Editar plantilla';

  @override
  String get memory => 'Memoria';

  @override
  String get myMemories => 'Mis memorias';

  @override
  String get settings => 'Configuración';

  @override
  String get search => 'Buscar';

  @override
  String get save => 'Guardar';

  @override
  String get saveSummaryQuickActionTitle => 'Guardar resumen';

  @override
  String get inject => 'Inyectar';

  @override
  String get generalSettings => 'Configuración general';

  @override
  String get themeSettings => 'Configuración de tema';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get systemMode => 'Sistema';

  @override
  String get language => 'Idioma';

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
  String get storageSettings => 'Configuración de almacenamiento';

  @override
  String get storageSpace => 'Espacio de almacenamiento';

  @override
  String get backupData => 'Respaldar datos';

  @override
  String get about => 'Acerca de';

  @override
  String get versionInfo => 'Información de versión';

  @override
  String get feedback => 'Comentarios';

  @override
  String get inDevelopment => 'En desarrollo';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get title => 'Título';

  @override
  String get content => 'Contenido';

  @override
  String get tags => 'Etiquetas';

  @override
  String get saveToVault => 'Guardar en la bóveda';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get savedToVault => 'Guardado en la bóveda';

  @override
  String get titleAndContentRequired => 'Título y contenido son obligatorios';

  @override
  String get commaSeparatedTagsHint => 'Etiquetas (separadas por comas)';

  @override
  String get searchHint => 'Buscar título, contenido o etiquetas...';

  @override
  String get noSearchResults => 'No hay resultados de búsqueda';

  @override
  String get noData => 'Sin datos';

  @override
  String get noTemplatesYet => 'Aún no hay plantillas';

  @override
  String get noSummariesYet => 'Aún no hay memorias';

  @override
  String get navHome => 'Inicio';

  @override
  String get navTemplates => 'Plantillas';

  @override
  String get navMemory => 'Memoria';

  @override
  String get navSettings => 'Configuración';

  @override
  String get refresh => 'Actualizar';

  @override
  String get cancelLabel => 'Cancelar';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get deleteLabel => 'Eliminar';

  @override
  String get deleteSummary => 'Eliminar resumen';

  @override
  String get deleteTemplate => 'Eliminar plantilla';

  @override
  String get shareLabel => 'Compartir';

  @override
  String get restoreLabel => 'Restaurar';

  @override
  String get retryLabel => 'Reintentar';

  @override
  String get closeLabel => 'Cerrar';

  @override
  String get workingLabel => 'Procesando...';

  @override
  String get okLabel => 'Aceptar';

  @override
  String get quickSave => 'Guardado rápido';

  @override
  String get manualInput => 'Entrada manual';

  @override
  String get quickSaveClipboardTip =>
      'Consejo: el guardado rápido usará automáticamente el texto del portapapeles.\nSi está vacío, puedes introducir el contenido manualmente.';

  @override
  String get invalidActionType => 'Tipo de acción no válido';

  @override
  String get quickActions => 'Acciones rápidas';

  @override
  String get enableFloatingGestureLauncher =>
      'Activar lanzador flotante por gestos';

  @override
  String get floatingGestureLauncherDescription =>
      'Abre la app rápidamente con gestos desde otras aplicaciones';

  @override
  String get gestureConfiguration => 'Configuración de gestos';

  @override
  String get gestureConfigurationDescription =>
      'Personaliza el comportamiento de los gestos';

  @override
  String get appAllowlist => 'Lista de aplicaciones permitidas';

  @override
  String get appAllowlistDescription =>
      'Los gestos solo están activos dentro de las aplicaciones seleccionadas';

  @override
  String get diagnostics => 'Diagnóstico';

  @override
  String get diagnosticsDescription =>
      'Revisa permisos, servicios y estado de sincronización de gestos';

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
      'El título y las etiquetas ahora usan el modelo integrado';

  @override
  String get titleTagsUseLocalRuleGenerator =>
      'El título y las etiquetas ahora usan el generador local basado en reglas';

  @override
  String get storageSummaryTapToView =>
      'Toca para ver los detalles del almacenamiento';

  @override
  String get createShareRestoreLocalBackups =>
      'Crear, compartir y restaurar copias locales';

  @override
  String storageSummaryFormat(
      Object bytes, Object summaryCount, Object templateCount) {
    return '$bytes · $summaryCount resúmenes · $templateCount plantillas';
  }

  @override
  String get backupSummaryNone =>
      'Aún no hay copias locales. Toca para crear una';

  @override
  String backupSummaryAvailable(Object backupCount) {
    return '$backupCount copias locales disponibles';
  }

  @override
  String get architectureChecksDebugOnly =>
      'Comprobaciones de arquitectura - SOLO DEBUG';

  @override
  String get runArchitectureVerification =>
      'Ejecutar verificación de arquitectura';

  @override
  String get runArchitectureVerificationDescription =>
      'Verifica que la nueva arquitectura funcione correctamente';

  @override
  String get runningArchitectureVerification =>
      'Ejecutando verificación de arquitectura...';

  @override
  String get architectureVerificationFinished =>
      'La verificación de arquitectura terminó. Revisa la salida de la consola.';

  @override
  String get inspectDatabase => 'Inspeccionar base de datos';

  @override
  String get inspectDatabaseDescription =>
      'Ver registros sin procesar del almacenamiento de resúmenes y plantillas';

  @override
  String get notAllPermissionsGranted =>
      'No se concedieron todos los permisos. Es posible que los gestos no funcionen correctamente.';

  @override
  String get floatingWindowServiceStarted =>
      'Se inició el servicio de ventana flotante';

  @override
  String get floatingWindowServiceStopped =>
      'Se detuvo el servicio de ventana flotante';

  @override
  String failedToStartMessage(Object error) {
    return 'No se pudo iniciar: $error';
  }

  @override
  String failedToStopMessage(Object error) {
    return 'No se pudo detener: $error';
  }

  @override
  String get serviceStarted => 'Servicio iniciado';

  @override
  String get floatingWindowTips =>
      'El servicio de gestos flotantes ya está en ejecución.\n\nConsejos de uso:\n1. Busca las zonas de gestos semitransparentes cerca de los bordes de la pantalla.\n2. Desliza dentro de esas zonas para abrir la app rápidamente.\n3. Si la superposición no aparece, confirma que todos los permisos requeridos estén concedidos.\n\nImportante:\nSi los gestos dejan de funcionar después de cambiar de app, revisa:\n- Si la app está en la lista permitida\n- Si se concedió el permiso de acceso al uso';

  @override
  String get openAllowlist => 'Abrir lista permitida';

  @override
  String get memoryManagement => 'Gestión de memoria';

  @override
  String loadFailedMessage(Object error) {
    return 'Error al cargar: $error';
  }

  @override
  String get loadFailedLabel => 'Error al cargar';

  @override
  String errorWithDetails(Object error) {
    return 'Error: $error';
  }

  @override
  String deleteSummaryConfirm(Object title) {
    return '¿Eliminar el resumen \"$title\"?';
  }

  @override
  String deleteTemplateConfirm(Object title) {
    return '¿Eliminar la plantilla \"$title\"?';
  }

  @override
  String deleteFailedMessage(Object error) {
    return 'La eliminación falló: $error';
  }

  @override
  String get templateDeleted => 'Plantilla eliminada';

  @override
  String get currentView => 'Vista actual';

  @override
  String get allMemories => 'Todas las memorias';

  @override
  String get searchFilter => 'Filtro de búsqueda';

  @override
  String itemCountLabel(Object count) {
    return '$count elementos';
  }

  @override
  String get notFiltered => 'Sin filtro';

  @override
  String get filtered => 'Filtrado';

  @override
  String get memoryType => 'Tipo de memoria';

  @override
  String metaImportanceLabel(Object percent) {
    return 'Importancia $percent';
  }

  @override
  String metaVisitsLabel(Object count) {
    return 'Visitas $count';
  }

  @override
  String metaUpdatedLabel(Object date) {
    return 'Actualizado $date';
  }

  @override
  String metaLastOpenedLabel(Object date) {
    return 'Última apertura $date';
  }

  @override
  String get editLabel => 'Editar';

  @override
  String get promoteToCore => 'Promover a núcleo';

  @override
  String get setAsCore => 'Definir como núcleo';

  @override
  String get setAsCoreMemory => 'Definir como memoria núcleo';

  @override
  String get mergeSimilar => 'Combinar similares';

  @override
  String get importanceScore => 'Puntuación de importancia';

  @override
  String get refreshAndCleanup => 'Actualizar y limpiar';

  @override
  String get refreshCleanupCompleted => 'Actualización y limpieza completadas';

  @override
  String get promoteToCoreMemory => 'Promover a memoria núcleo';

  @override
  String promotionDialogBody(Object title) {
    return '\"$title\" dejará de participar en el olvido regular y se conservará como una memoria prioritaria de largo plazo.';
  }

  @override
  String promotionStatsLine(Object accessCount, Object importancePercent) {
    return 'Visitas actuales $accessCount · importancia $importancePercent';
  }

  @override
  String get promotionThresholdMet =>
      'Esta memoria ya cumple el umbral de promoción automática.';

  @override
  String get promotionThresholdNotMet =>
      'Esta memoria todavía no alcanza el umbral automático, pero puedes fijarla manualmente como memoria núcleo.';

  @override
  String promotionThresholdLine(
      Object accessCountThreshold, Object importanceThreshold) {
    return 'Umbral automático actual: visitas >= $accessCountThreshold o importancia >= $importanceThreshold';
  }

  @override
  String get generatingPromotionReason => 'Generando motivo de promoción...';

  @override
  String get promotionReason => 'Motivo de promoción';

  @override
  String get defaultPromotionReason =>
      'Esta memoria ya tiene valor duradero y conviene conservarla como memoria núcleo de largo plazo.';

  @override
  String get upgradeReasonHighAccess =>
      'Esta memoria se consulta con frecuencia y ha demostrado un valor estable a largo plazo, por lo que es una buena candidata para promoverla a memoria núcleo.';

  @override
  String get upgradeReasonHighImportance =>
      'Esta memoria tiene una puntuación de importancia alta y vale la pena conservarla como memoria núcleo de largo plazo.';

  @override
  String get confirmPromotion => 'Confirmar promoción';

  @override
  String get confirmSetAsCore => 'Confirmar definición como núcleo';

  @override
  String get promotedToCoreMemory => 'Promovida a memoria núcleo';

  @override
  String get setAsCoreSuccess => 'Definida como memoria núcleo';

  @override
  String get viewCore => 'Ver núcleo';

  @override
  String get noSimilarMemoriesFound => 'No se encontraron memorias similares';

  @override
  String get currentFactMemory => 'Memoria factual actual';

  @override
  String get candidateFactMemory => 'Memoria factual candidata';

  @override
  String get mergeCompleted => 'Combinación completada';

  @override
  String get chooseMemoryToCompare => 'Elige una memoria para comparar';

  @override
  String mergeCandidateCount(Object title, Object count) {
    return '\"$title\" tiene $count candidato(s) para combinar';
  }

  @override
  String similarityWithContent(Object similarity, Object content) {
    return 'Similitud $similarity · $content';
  }

  @override
  String get deleteMemory => 'Eliminar memoria';

  @override
  String deleteMemoryConfirm(Object title) {
    return '¿Eliminar \"$title\"?';
  }

  @override
  String get deletedLabel => 'Eliminado';

  @override
  String get factMemories => 'Memorias factuales';

  @override
  String get coreMemories => 'Memorias núcleo';

  @override
  String get sessionMemories => 'Memorias de sesión';

  @override
  String get factMemoryLabel => 'Factual';

  @override
  String get coreMemoryLabel => 'Núcleo';

  @override
  String get sessionMemoryLabel => 'Sesión';

  @override
  String get factMemoryDescription =>
      'Hechos ordinarios e información estable que vale la pena conservar a largo plazo.';

  @override
  String get coreMemoryDescription =>
      'Las memorias de largo plazo de mayor prioridad que no participan en el olvido regular.';

  @override
  String get sessionMemoryDescription =>
      'Contexto temporal de interacciones recientes útil para la organización a corto plazo.';

  @override
  String relativeMinutesAgo(Object count) {
    return 'hace $count min';
  }

  @override
  String relativeHoursAgo(Object count) {
    return 'hace $count h';
  }

  @override
  String relativeDaysAgo(Object count) {
    return 'hace $count d';
  }

  @override
  String get noMatchingMemories => 'No hay memorias coincidentes';

  @override
  String get noFactMemoriesYet => 'Aún no hay memorias factuales';

  @override
  String get noCoreMemoriesYet => 'Aún no hay memorias núcleo';

  @override
  String get noSessionMemoriesYet => 'Aún no hay memorias de sesión';

  @override
  String get mergeFactMemories => 'Combinar memorias factuales';

  @override
  String get mergeFactMemoriesDescription =>
      'Compara ambas versiones y elige el título, contenido y etiquetas finales que se conservarán.';

  @override
  String similarityPercent(Object percent) {
    return 'Similitud $percent';
  }

  @override
  String get mergedPreview => 'Vista previa combinada';

  @override
  String get noTags => 'Sin etiquetas';

  @override
  String get notNow => 'Ahora no';

  @override
  String get mergingLabel => 'Combinando...';

  @override
  String get confirmMerge => 'Confirmar combinación';

  @override
  String get keepOriginal => 'Conservar original';

  @override
  String get keepNew => 'Conservar nuevo';

  @override
  String get smartMerge => 'Combinación inteligente';

  @override
  String get emptyValue => 'Vacío';

  @override
  String get candidateMemory => 'Memoria candidata';

  @override
  String mergeFailedMessage(Object error) {
    return 'La combinación falló: $error';
  }

  @override
  String get clearModelCache => 'Limpiar caché del modelo';

  @override
  String get clearModelCacheMessage =>
      'Esto elimina archivos locales de caché de inferencia del modelo, pero conserva resúmenes, plantillas y el archivo del modelo.';

  @override
  String get noModelCacheFilesToClear =>
      'No hay archivos de caché del modelo para limpiar';

  @override
  String clearedModelCacheResult(Object count, Object bytes) {
    return 'Se limpiaron $count archivo(s) de caché y se liberaron $bytes';
  }

  @override
  String get clearBackupFiles => 'Limpiar archivos de copia';

  @override
  String get clearBackupFilesMessage =>
      'Esto elimina archivos de copia generados localmente sin cambiar los resúmenes o plantillas actuales en la base de datos.';

  @override
  String get noBackupFilesToClear => 'No hay archivos de copia para limpiar';

  @override
  String deletedBackupFilesResult(Object count, Object bytes) {
    return 'Se eliminaron $count archivo(s) de copia y se liberaron $bytes';
  }

  @override
  String failedToReadStorageUsage(Object error) {
    return 'No se pudo leer el uso de almacenamiento: $error';
  }

  @override
  String get totalStorageUsed => 'Almacenamiento total usado';

  @override
  String storageOverviewCounts(
      Object summaryCount, Object templateCount, Object backupCount) {
    return '$summaryCount resúmenes · $templateCount plantillas · $backupCount copias';
  }

  @override
  String get summaryDatabase => 'Base de datos de resúmenes';

  @override
  String summaryDatabaseSubtitle(Object count) {
    return '$count resúmenes';
  }

  @override
  String get templateDatabase => 'Base de datos de plantillas';

  @override
  String templateDatabaseSubtitle(Object count) {
    return '$count plantillas';
  }

  @override
  String get backupFiles => 'Archivos de copia';

  @override
  String backupFilesSubtitle(Object count) {
    return '$count copias';
  }

  @override
  String get modelFile => 'Archivo del modelo';

  @override
  String get bundledModelFootprint => 'Tamaño del modelo integrado';

  @override
  String get modelCache => 'Caché del modelo';

  @override
  String get inferenceCacheAndIntermediateFiles =>
      'Caché de inferencia y archivos intermedios';

  @override
  String get cleanupTools => 'Herramientas de limpieza';

  @override
  String get clearLocalBackupFiles => 'Limpiar archivos de copia locales';

  @override
  String backupCreatedMessage(Object fileName) {
    return 'Copia creada: $fileName';
  }

  @override
  String failedToCreateBackupMessage(Object error) {
    return 'No se pudo crear la copia: $error';
  }

  @override
  String importFailedMessage(Object error) {
    return 'La importación falló: $error';
  }

  @override
  String get importFailedUnableReadSelectedFile =>
      'Importación fallida: no se pudo leer el archivo seleccionado';

  @override
  String get unknownValue => 'Desconocido';

  @override
  String get importBackup => 'Importar copia';

  @override
  String backupImportPreviewMessage(
      Object summaryCount, Object templateCount, Object exportedAt) {
    return 'Esta copia contiene $summaryCount resúmenes y $templateCount plantillas.\nExportada en: $exportedAt\n\nImportarla sobrescribirá los datos actuales de resúmenes y plantillas. ¿Continuar?';
  }

  @override
  String importFinishedMessage(Object summaryCount, Object templateCount) {
    return 'Importación completada: $summaryCount resúmenes, $templateCount plantillas';
  }

  @override
  String get invalidBackupFileFormat =>
      'Importación fallida: formato de copia no válido';

  @override
  String get restoreBackupMessage =>
      'Restaurar sobrescribirá los datos actuales de resúmenes y plantillas. ¿Continuar?';

  @override
  String restoreFinishedMessage(Object summaryCount, Object templateCount) {
    return 'Restauración completada: $summaryCount resúmenes, $templateCount plantillas';
  }

  @override
  String restoreFailedMessage(Object error) {
    return 'La restauración falló: $error';
  }

  @override
  String deleteBackupConfirmMessage(Object fileName) {
    return '¿Eliminar la copia $fileName?';
  }

  @override
  String get backupDeleted => 'Copia eliminada';

  @override
  String failedToLoadBackupList(Object error) {
    return 'No se pudo cargar la lista de copias: $error';
  }

  @override
  String get noLocalBackupFilesYet => 'Aún no hay archivos de copia locales';

  @override
  String get localBackups => 'Copias locales';

  @override
  String backupFilesAvailable(Object count) {
    return '$count archivo(s) de copia disponibles';
  }

  @override
  String get backupOverviewDescription =>
      'Crear una copia genera un archivo JSON y abre la hoja para compartir. También puedes importar un archivo de copia desde fuera de la app.';

  @override
  String get createAndShareBackup => 'Crear y compartir copia';

  @override
  String get importBackupData => 'Importar datos de copia';

  @override
  String get shareBackupText => 'Copia de seguridad de Local Vault';

  @override
  String get shareBackupSubject => 'Copia de seguridad de Local Vault';

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
