// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '로컬 메모리 라이브러리';

  @override
  String get home => '홈';

  @override
  String get templates => '템플릿';

  @override
  String get chooseTemplate => '템플릿 선택';

  @override
  String get addTemplate => '템플릿 추가';

  @override
  String get editTemplate => '템플릿 편집';

  @override
  String get memory => '기억';

  @override
  String get myMemories => '내 기억';

  @override
  String get settings => '설정';

  @override
  String get search => '검색';

  @override
  String get save => '저장';

  @override
  String get saveSummaryQuickActionTitle => '요약 저장';

  @override
  String get inject => '주입';

  @override
  String get generalSettings => '일반 설정';

  @override
  String get themeSettings => '테마 설정';

  @override
  String get darkMode => '다크 모드';

  @override
  String get lightMode => '라이트 모드';

  @override
  String get systemMode => '시스템';

  @override
  String get language => '언어';

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
  String get storageSettings => '스토리지 설정';

  @override
  String get storageSpace => '저장 공간';

  @override
  String get backupData => '데이터 백업';

  @override
  String get about => '정보';

  @override
  String get versionInfo => '버전 정보';

  @override
  String get feedback => '피드백';

  @override
  String get inDevelopment => '개발 중';

  @override
  String get comingSoon => '곧 출시';

  @override
  String get title => '제목';

  @override
  String get content => '내용';

  @override
  String get tags => '태그';

  @override
  String get saveToVault => '로컬 메모리에 저장';

  @override
  String get copiedToClipboard => '클립보드에 복사됨';

  @override
  String get savedToVault => '로컬 메모리에 저장됨';

  @override
  String get titleAndContentRequired => '제목과 내용은 필수입니다';

  @override
  String get commaSeparatedTagsHint => '태그(쉼표로 구분)';

  @override
  String get searchHint => '제목, 내용 또는 태그 검색...';

  @override
  String get noSearchResults => '검색 결과가 없습니다';

  @override
  String get noData => '데이터가 없습니다';

  @override
  String get noTemplatesYet => '아직 템플릿이 없습니다';

  @override
  String get noSummariesYet => '아직 기억이 없습니다';

  @override
  String get navHome => '홈';

  @override
  String get navTemplates => '템플릿';

  @override
  String get navMemory => '기억';

  @override
  String get navSettings => '설정';

  @override
  String get refresh => '새로고침';

  @override
  String get cancelLabel => '취소';

  @override
  String get continueLabel => '계속';

  @override
  String get deleteLabel => '삭제';

  @override
  String get deleteSummary => '요약 삭제';

  @override
  String get deleteTemplate => '템플릿 삭제';

  @override
  String get shareLabel => '공유';

  @override
  String get restoreLabel => '복원';

  @override
  String get retryLabel => '다시 시도';

  @override
  String get closeLabel => '닫기';

  @override
  String get workingLabel => '처리 중...';

  @override
  String get okLabel => '확인';

  @override
  String get quickSave => '빠른 저장';

  @override
  String get manualInput => '직접 입력';

  @override
  String get quickSaveClipboardTip =>
      '팁: 빠른 저장은 클립보드 텍스트를 자동으로 사용합니다.\n클립보드가 비어 있으면 내용을 직접 입력할 수 있습니다.';

  @override
  String get invalidActionType => '잘못된 작업 유형입니다';

  @override
  String get quickActions => '빠른 작업';

  @override
  String get enableFloatingGestureLauncher => '플로팅 제스처 실행기 활성화';

  @override
  String get floatingGestureLauncherDescription => '다른 앱에서도 제스처로 빠르게 앱을 엽니다';

  @override
  String get gestureConfiguration => '제스처 설정';

  @override
  String get gestureConfigurationDescription => '제스처 동작을 사용자 지정합니다';

  @override
  String get appAllowlist => '허용 앱 목록';

  @override
  String get appAllowlistDescription => '제스처는 선택한 앱 안에서만 활성화됩니다';

  @override
  String get diagnostics => '진단';

  @override
  String get diagnosticsDescription => '제스처 권한, 서비스, 동기화 상태를 확인합니다';

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
  String get titleTagsUseBuiltInModel => '제목과 태그가 이제 내장 모델을 사용합니다';

  @override
  String get titleTagsUseLocalRuleGenerator => '제목과 태그가 이제 로컬 규칙 생성기를 사용합니다';

  @override
  String get storageSummaryTapToView => '탭하여 저장소 세부 정보를 확인';

  @override
  String get createShareRestoreLocalBackups => '로컬 백업 생성, 공유 및 복원';

  @override
  String storageSummaryFormat(
      Object bytes, Object summaryCount, Object templateCount) {
    return '$bytes · 요약 $summaryCount개 · 템플릿 $templateCount개';
  }

  @override
  String get backupSummaryNone => '로컬 백업이 아직 없습니다. 탭하여 생성하세요';

  @override
  String backupSummaryAvailable(Object backupCount) {
    return '로컬 백업 $backupCount개 사용 가능';
  }

  @override
  String get architectureChecksDebugOnly => '아키텍처 검사 - DEBUG 전용';

  @override
  String get runArchitectureVerification => '아키텍처 검증 실행';

  @override
  String get runArchitectureVerificationDescription =>
      '새 아키텍처가 정상적으로 동작하는지 확인합니다';

  @override
  String get runningArchitectureVerification => '아키텍처 검증 실행 중...';

  @override
  String get architectureVerificationFinished =>
      '아키텍처 검증이 완료되었습니다. 콘솔 출력을 확인하세요.';

  @override
  String get inspectDatabase => '데이터베이스 확인';

  @override
  String get inspectDatabaseDescription => '요약 및 템플릿 저장소의 원시 레코드를 봅니다';

  @override
  String get notAllPermissionsGranted =>
      '모든 권한이 허용되지 않았습니다. 제스처 기능이 제대로 동작하지 않을 수 있습니다.';

  @override
  String get floatingWindowServiceStarted => '플로팅 창 서비스가 시작되었습니다';

  @override
  String get floatingWindowServiceStopped => '플로팅 창 서비스가 중지되었습니다';

  @override
  String failedToStartMessage(Object error) {
    return '시작 실패: $error';
  }

  @override
  String failedToStopMessage(Object error) {
    return '중지 실패: $error';
  }

  @override
  String get serviceStarted => '서비스 시작됨';

  @override
  String get floatingWindowTips =>
      '플로팅 제스처 서비스가 실행 중입니다.\n\n사용 방법:\n1. 화면 가장자리 근처의 반투명 제스처 영역을 찾으세요.\n2. 그 영역 안에서 스와이프하면 앱을 빠르게 실행할 수 있습니다.\n3. 오버레이가 보이지 않으면 필요한 권한이 모두 허용되었는지 확인하세요.\n\n중요:\n앱 전환 후 제스처가 동작하지 않으면 다음을 확인하세요:\n- 앱이 허용 목록에 포함되어 있는지\n- 사용량 액세스 권한이 허용되었는지';

  @override
  String get openAllowlist => '허용 목록 열기';

  @override
  String get memoryManagement => '기억 관리';

  @override
  String loadFailedMessage(Object error) {
    return '불러오기 실패: $error';
  }

  @override
  String get loadFailedLabel => '불러오기에 실패했습니다';

  @override
  String errorWithDetails(Object error) {
    return '오류: $error';
  }

  @override
  String deleteSummaryConfirm(Object title) {
    return '\"$title\" 요약을 삭제할까요?';
  }

  @override
  String deleteTemplateConfirm(Object title) {
    return '\"$title\" 템플릿을 삭제할까요?';
  }

  @override
  String deleteFailedMessage(Object error) {
    return '삭제 실패: $error';
  }

  @override
  String get templateDeleted => '템플릿이 삭제되었습니다';

  @override
  String get currentView => '현재 보기';

  @override
  String get allMemories => '전체 기억';

  @override
  String get searchFilter => '검색 필터';

  @override
  String itemCountLabel(Object count) {
    return '$count개 항목';
  }

  @override
  String get notFiltered => '필터 없음';

  @override
  String get filtered => '필터 적용됨';

  @override
  String get memoryType => '기억 유형';

  @override
  String metaImportanceLabel(Object percent) {
    return '중요도 $percent';
  }

  @override
  String metaVisitsLabel(Object count) {
    return '방문 $count';
  }

  @override
  String metaUpdatedLabel(Object date) {
    return '업데이트 $date';
  }

  @override
  String metaLastOpenedLabel(Object date) {
    return '마지막 열람 $date';
  }

  @override
  String get editLabel => '편집';

  @override
  String get promoteToCore => '코어로 승격';

  @override
  String get setAsCore => '코어로 설정';

  @override
  String get setAsCoreMemory => '코어 기억으로 설정';

  @override
  String get mergeSimilar => '유사 항목 병합';

  @override
  String get importanceScore => '중요도 점수';

  @override
  String get refreshAndCleanup => '새로고침 및 정리';

  @override
  String get refreshCleanupCompleted => '새로고침과 정리가 완료되었습니다';

  @override
  String get promoteToCoreMemory => '코어 기억으로 승격';

  @override
  String promotionDialogBody(Object title) {
    return '\"$title\"은 일반적인 망각 감쇠에서 제외되고 우선순위가 높은 장기 기억으로 유지됩니다.';
  }

  @override
  String promotionStatsLine(Object accessCount, Object importancePercent) {
    return '현재 방문 $accessCount회 · 중요도 $importancePercent';
  }

  @override
  String get promotionThresholdMet => '이 기억은 이미 자동 승격 기준을 충족합니다.';

  @override
  String get promotionThresholdNotMet =>
      '이 기억은 아직 자동 기준에 도달하지 않았지만 수동으로 코어 기억으로 고정할 수 있습니다.';

  @override
  String promotionThresholdLine(
      Object accessCountThreshold, Object importanceThreshold) {
    return '현재 자동 기준: 방문 수 >= $accessCountThreshold 또는 중요도 >= $importanceThreshold';
  }

  @override
  String get generatingPromotionReason => '승격 이유 생성 중...';

  @override
  String get promotionReason => '승격 이유';

  @override
  String get defaultPromotionReason =>
      '이 기억은 지속적인 가치가 있어 장기 코어 기억으로 보존하기에 적합합니다.';

  @override
  String get upgradeReasonHighAccess =>
      '이 기억은 자주 접근되며 안정적인 장기 가치를 보여 주므로 코어 기억으로 승격하기에 적합합니다.';

  @override
  String get upgradeReasonHighImportance =>
      '이 기억은 중요도가 높아 장기 코어 기억으로 유지할 가치가 있습니다.';

  @override
  String get confirmPromotion => '승격 확인';

  @override
  String get confirmSetAsCore => '코어 설정 확인';

  @override
  String get promotedToCoreMemory => '코어 기억으로 승격되었습니다';

  @override
  String get setAsCoreSuccess => '코어 기억으로 설정되었습니다';

  @override
  String get viewCore => '코어 보기';

  @override
  String get noSimilarMemoriesFound => '유사한 기억을 찾지 못했습니다';

  @override
  String get currentFactMemory => '현재 사실 기억';

  @override
  String get candidateFactMemory => '후보 사실 기억';

  @override
  String get mergeCompleted => '병합이 완료되었습니다';

  @override
  String get chooseMemoryToCompare => '비교할 기억을 선택하세요';

  @override
  String mergeCandidateCount(Object title, Object count) {
    return '\"$title\"에 병합 후보가 $count개 있습니다';
  }

  @override
  String similarityWithContent(Object similarity, Object content) {
    return '유사도 $similarity · $content';
  }

  @override
  String get deleteMemory => '기억 삭제';

  @override
  String deleteMemoryConfirm(Object title) {
    return '\"$title\"을(를) 삭제할까요?';
  }

  @override
  String get deletedLabel => '삭제됨';

  @override
  String get factMemories => '사실 기억';

  @override
  String get coreMemories => '코어 기억';

  @override
  String get sessionMemories => '세션 기억';

  @override
  String get factMemoryLabel => '사실';

  @override
  String get coreMemoryLabel => '코어';

  @override
  String get sessionMemoryLabel => '세션';

  @override
  String get factMemoryDescription => '장기간 보관할 가치가 있는 일반적인 사실과 안정적인 정보입니다.';

  @override
  String get coreMemoryDescription => '일반적인 망각 감쇠에 참여하지 않는 최우선 장기 기억입니다.';

  @override
  String get sessionMemoryDescription => '단기 정리에 유용한 최근 상호작용의 임시 문맥입니다.';

  @override
  String relativeMinutesAgo(Object count) {
    return '$count분 전';
  }

  @override
  String relativeHoursAgo(Object count) {
    return '$count시간 전';
  }

  @override
  String relativeDaysAgo(Object count) {
    return '$count일 전';
  }

  @override
  String get noMatchingMemories => '일치하는 기억이 없습니다';

  @override
  String get noFactMemoriesYet => '아직 사실 기억이 없습니다';

  @override
  String get noCoreMemoriesYet => '아직 코어 기억이 없습니다';

  @override
  String get noSessionMemoriesYet => '아직 세션 기억이 없습니다';

  @override
  String get mergeFactMemories => '사실 기억 병합';

  @override
  String get mergeFactMemoriesDescription =>
      '두 버전을 비교하고 최종으로 유지할 제목, 내용, 태그를 선택하세요.';

  @override
  String similarityPercent(Object percent) {
    return '유사도 $percent';
  }

  @override
  String get mergedPreview => '병합 미리보기';

  @override
  String get noTags => '태그 없음';

  @override
  String get notNow => '나중에';

  @override
  String get mergingLabel => '병합 중...';

  @override
  String get confirmMerge => '병합 확인';

  @override
  String get keepOriginal => '원본 유지';

  @override
  String get keepNew => '새 항목 유지';

  @override
  String get smartMerge => '스마트 병합';

  @override
  String get emptyValue => '비어 있음';

  @override
  String get candidateMemory => '후보 기억';

  @override
  String mergeFailedMessage(Object error) {
    return '병합 실패: $error';
  }

  @override
  String get clearModelCache => '모델 캐시 지우기';

  @override
  String get clearModelCacheMessage =>
      '로컬 모델 추론 캐시 파일을 제거하지만 요약, 템플릿, 모델 파일 자체는 유지됩니다.';

  @override
  String get noModelCacheFilesToClear => '지울 모델 캐시 파일이 없습니다';

  @override
  String clearedModelCacheResult(Object count, Object bytes) {
    return '캐시 파일 $count개를 지우고 $bytes를 확보했습니다';
  }

  @override
  String get clearBackupFiles => '백업 파일 지우기';

  @override
  String get clearBackupFilesMessage =>
      '로컬에서 생성된 백업 파일을 삭제하지만 데이터베이스의 현재 요약과 템플릿은 변경되지 않습니다.';

  @override
  String get noBackupFilesToClear => '지울 백업 파일이 없습니다';

  @override
  String deletedBackupFilesResult(Object count, Object bytes) {
    return '백업 파일 $count개를 삭제하고 $bytes를 확보했습니다';
  }

  @override
  String failedToReadStorageUsage(Object error) {
    return '저장소 사용량을 읽지 못했습니다: $error';
  }

  @override
  String get totalStorageUsed => '총 저장소 사용량';

  @override
  String storageOverviewCounts(
      Object summaryCount, Object templateCount, Object backupCount) {
    return '요약 $summaryCount개 · 템플릿 $templateCount개 · 백업 $backupCount개';
  }

  @override
  String get summaryDatabase => '요약 데이터베이스';

  @override
  String summaryDatabaseSubtitle(Object count) {
    return '요약 $count개';
  }

  @override
  String get templateDatabase => '템플릿 데이터베이스';

  @override
  String templateDatabaseSubtitle(Object count) {
    return '템플릿 $count개';
  }

  @override
  String get backupFiles => '백업 파일';

  @override
  String backupFilesSubtitle(Object count) {
    return '백업 $count개';
  }

  @override
  String get modelFile => '모델 파일';

  @override
  String get bundledModelFootprint => '내장 모델 용량';

  @override
  String get modelCache => '모델 캐시';

  @override
  String get inferenceCacheAndIntermediateFiles => '추론 캐시 및 중간 파일';

  @override
  String get cleanupTools => '정리 도구';

  @override
  String get clearLocalBackupFiles => '로컬 백업 파일 지우기';

  @override
  String backupCreatedMessage(Object fileName) {
    return '백업 생성됨: $fileName';
  }

  @override
  String failedToCreateBackupMessage(Object error) {
    return '백업 생성 실패: $error';
  }

  @override
  String importFailedMessage(Object error) {
    return '가져오기 실패: $error';
  }

  @override
  String get importFailedUnableReadSelectedFile => '가져오기 실패: 선택한 파일을 읽을 수 없습니다';

  @override
  String get unknownValue => '알 수 없음';

  @override
  String get importBackup => '백업 가져오기';

  @override
  String backupImportPreviewMessage(
      Object summaryCount, Object templateCount, Object exportedAt) {
    return '이 백업에는 요약 $summaryCount개와 템플릿 $templateCount개가 포함되어 있습니다.\n내보낸 시각: $exportedAt\n\n가져오면 현재 요약 및 템플릿 데이터가 덮어써집니다. 계속할까요?';
  }

  @override
  String importFinishedMessage(Object summaryCount, Object templateCount) {
    return '가져오기 완료: 요약 $summaryCount개, 템플릿 $templateCount개';
  }

  @override
  String get invalidBackupFileFormat => '가져오기 실패: 백업 파일 형식이 올바르지 않습니다';

  @override
  String get restoreBackupMessage => '복원하면 현재 요약 및 템플릿 데이터가 덮어써집니다. 계속할까요?';

  @override
  String restoreFinishedMessage(Object summaryCount, Object templateCount) {
    return '복원 완료: 요약 $summaryCount개, 템플릿 $templateCount개';
  }

  @override
  String restoreFailedMessage(Object error) {
    return '복원 실패: $error';
  }

  @override
  String deleteBackupConfirmMessage(Object fileName) {
    return '백업 $fileName을(를) 삭제할까요?';
  }

  @override
  String get backupDeleted => '백업이 삭제되었습니다';

  @override
  String failedToLoadBackupList(Object error) {
    return '백업 목록을 불러오지 못했습니다: $error';
  }

  @override
  String get noLocalBackupFilesYet => '아직 로컬 백업 파일이 없습니다';

  @override
  String get localBackups => '로컬 백업';

  @override
  String backupFilesAvailable(Object count) {
    return '사용 가능한 백업 파일 $count개';
  }

  @override
  String get backupOverviewDescription =>
      '백업을 만들면 JSON 파일이 생성되고 공유 시트가 열립니다. 앱 외부의 백업 파일을 가져올 수도 있습니다.';

  @override
  String get createAndShareBackup => '백업 생성 및 공유';

  @override
  String get importBackupData => '백업 데이터 가져오기';

  @override
  String get shareBackupText => '로컬 메모리 라이브러리 백업';

  @override
  String get shareBackupSubject => '로컬 메모리 라이브러리 백업';

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
