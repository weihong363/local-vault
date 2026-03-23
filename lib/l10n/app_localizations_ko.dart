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
  String get showFullContent => '전체 내용 보기';

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
  String get slmInferenceSettingTitle => 'SLM 추론 활성화';

  @override
  String get slmInferenceSettingDescription =>
      '이 설정은 향후 호환성을 위해 남겨둔 옵션입니다. 현재 앱 버전은 제목, 태그, 주제 생성에 항상 로컬 규칙을 사용합니다.';

  @override
  String get slmInferenceEnabledMessage =>
      'SLM 설정을 활성화했습니다. 현재 앱 버전은 계속해서 제목, 태그, 주제 생성에 로컬 규칙을 사용합니다.';

  @override
  String get slmInferenceDisabledMessage =>
      'SLM 설정을 비활성화했습니다. 현재 앱 버전은 계속해서 제목, 태그, 주제 생성에 로컬 규칙을 사용합니다.';

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
  String get permissionsRequiredTitle => '권한이 필요합니다';

  @override
  String get permissionsRequiredMessage =>
      '제스처 실행을 정상적으로 사용하려면 다음 권한이 필요합니다:\n\n1. 오버레이 권한: 다른 앱 위에 제스처 감지 영역을 표시하는 데 사용합니다\n2. 사용량 액세스 권한: 현재 전면 앱을 감지해 허용 목록 앱에서 제스처 영역을 표시하는 데 사용합니다\n\n다음 화면에서 이 권한들을 허용해 주세요.';

  @override
  String get usageAccessPermissionRequiredTitle => '사용량 액세스 권한이 필요합니다';

  @override
  String get usageAccessPermissionRequiredMessage =>
      '사용량 액세스 권한이 없습니다.\n\n이 권한이 없으면:\n• 현재 활성 앱을 확인할 수 없습니다\n• 다른 앱에서 제스처 실행이 제대로 동작하지 않습니다\n\n\"권한 허용\"을 눌러 시스템 설정을 열고 이 앱의 권한을 활성화해 주세요.';

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
  String get currentFactMemory => '원본 메모리';

  @override
  String get candidateFactMemory => '신규 메모리';

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
  String get confirmLabel => '확인';

  @override
  String get clearLabel => '지우기';

  @override
  String get runningLabel => '실행 중...';

  @override
  String get unknownError => '알 수 없는 오류';

  @override
  String get statusEnabled => '활성';

  @override
  String get statusDisabled => '비활성';

  @override
  String get statusGranted => '허용됨';

  @override
  String get statusNotGranted => '허용되지 않음';

  @override
  String get statusRunning => '실행 중';

  @override
  String get statusStopped => '중지됨';

  @override
  String get statusUnavailable => '사용 불가';

  @override
  String get statusAvailable => '사용 가능';

  @override
  String get statusMissing => '누락됨';

  @override
  String get statusReady => '준비됨';

  @override
  String get statusCompatible => '호환됨';

  @override
  String get statusIncompatible => '호환되지 않음';

  @override
  String get statusInitialized => '초기화됨';

  @override
  String get statusNotInitialized => '초기화되지 않음';

  @override
  String get statusDetected => '감지됨';

  @override
  String get statusNotDetected => '감지되지 않음';

  @override
  String get statusModelUsed => '모델 사용';

  @override
  String get statusModelNotUsed => '모델 미사용';

  @override
  String get statusInitializationComplete => '초기화 완료';

  @override
  String get statusInitializationIncomplete => '초기화 미완료';

  @override
  String get gestureConfigurationSaved => '구성이 저장되었습니다';

  @override
  String gestureConfigurationLoadFailed(Object error) {
    return '제스처 구성을 불러오지 못했습니다: $error';
  }

  @override
  String get resetToDefaults => '기본값으로 재설정';

  @override
  String get resetGesturesToDefaultsMessage => '모든 제스처를 기본 구성으로 되돌릴까요?';

  @override
  String get restoredDefaultSettings => '기본 설정을 복원했습니다';

  @override
  String get gestureShareOnly => '공유 전용';

  @override
  String get gestureActionOpenTemplates => '프롬프트 템플릿 열기';

  @override
  String get gestureActionSaveSummary => '공유된 내용으로 요약 저장';

  @override
  String get gestureActionOpenSavedContext => '저장된 컨텍스트 열기';

  @override
  String get gestureDoubleTap => '두 번 탭';

  @override
  String get gestureTripleTap => '세 번 탭';

  @override
  String get triggerAction => '실행 동작';

  @override
  String get alreadyUsedByAnotherGesture => '이미 다른 제스처에서 사용 중입니다';

  @override
  String get searchAppsHint => '앱 검색...';

  @override
  String appWhitelistLoadFailed(Object error) {
    return '불러오기 실패: $error';
  }

  @override
  String selectedAppsCount(Object count) {
    return '$count개 앱 선택됨';
  }

  @override
  String get clearAllowlistTooltip => '허용 목록 비우기';

  @override
  String get gesturesActiveInAllApps => '제스처가 모든 앱에서 활성화되어 있습니다';

  @override
  String get filterAll => '전체';

  @override
  String get filterSelected => '선택됨';

  @override
  String get filterUnselected => '미선택';

  @override
  String get noAppsFound => '앱을 찾을 수 없습니다';

  @override
  String get noMatchingAppsFound => '일치하는 앱을 찾을 수 없습니다';

  @override
  String get noSelectedAppsYet => '아직 선택된 앱이 없습니다';

  @override
  String get noUnselectedApps => '미선택 앱이 없습니다';

  @override
  String get clearAllowlistTitle => '허용 목록 비우기';

  @override
  String get clearAllowlistMessage => '앱 허용 목록을 비울까요? 제스처가 모든 앱에서 활성화됩니다.';

  @override
  String get allowlistCleared => '허용 목록을 비웠습니다';

  @override
  String get databaseInspector => '데이터베이스 검사기';

  @override
  String failedToOpenDatabase(Object error) {
    return '데이터베이스를 열지 못했습니다: $error';
  }

  @override
  String get summariesTab => '요약';

  @override
  String get templatesTab => '템플릿';

  @override
  String get noSummaryRecordsInBox => '이 박스에 요약 레코드가 없습니다';

  @override
  String get noTemplateRecordsInBox => '이 박스에 템플릿 레코드가 없습니다';

  @override
  String recordsWithIssues(Object count) {
    return '문제가 있는 레코드: $count';
  }

  @override
  String legacyTemplateTypes(Object count) {
    return '레거시 템플릿 유형: $count';
  }

  @override
  String defaultTemplatesCount(Object count) {
    return '기본 템플릿: $count';
  }

  @override
  String boxMetricLabel(Object boxName) {
    return '박스: $boxName';
  }

  @override
  String recordsMetricLabel(Object count) {
    return '레코드: $count';
  }

  @override
  String keyMetricLabel(Object key) {
    return '키: $key';
  }

  @override
  String get noObviousIssuesDetected => '뚜렷한 문제는 감지되지 않았습니다';

  @override
  String issuesMetricLabel(Object count) {
    return '문제 수: $count';
  }

  @override
  String get copyJson => 'JSON 복사';

  @override
  String get recordNotMapCorrupted => '레코드가 Map이 아니며 손상되었을 수 있습니다';

  @override
  String get unparseableSummaryRecord => '파싱할 수 없는 요약 레코드';

  @override
  String get unparseableTemplateRecord => '파싱할 수 없는 템플릿 레코드';

  @override
  String rawTypeLabel(Object type) {
    return '원시 타입: $type';
  }

  @override
  String get legacyTemplateRecordDetected =>
      '레거시 템플릿 유형 레코드가 감지되었으며 fact로 읽습니다';

  @override
  String get missingId => 'ID가 없습니다';

  @override
  String get titleIsEmpty => '제목이 비어 있습니다';

  @override
  String get contentIsEmpty => '내용이 비어 있습니다';

  @override
  String get accessCountInvalid => 'accessCount가 올바른 숫자가 아닙니다';

  @override
  String get accessCountBelowZero => 'accessCount가 0보다 작습니다';

  @override
  String get createdAtCouldNotBeParsed => 'createdAt을 해석할 수 없습니다';

  @override
  String summaryDeserializationFailed(Object error) {
    return 'SummaryEntity 역직렬화에 실패했습니다: $error';
  }

  @override
  String templateDeserializationFailed(Object error) {
    return 'TemplateEntity 역직렬화에 실패했습니다: $error';
  }

  @override
  String get unknownTime => '알 수 없는 시간';

  @override
  String get untitledSummary => '(제목 없는 요약)';

  @override
  String get untitledTemplate => '(제목 없는 템플릿)';

  @override
  String summaryRecordSubtitle(
      Object accessCount, Object createdAt, Object type) {
    return '유형: $type  접근: $accessCount  생성: $createdAt';
  }

  @override
  String templateRecordSubtitle(Object createdAt, Object templateKind) {
    return '$templateKind  생성: $createdAt';
  }

  @override
  String get defaultTemplateLabel => '기본 템플릿';

  @override
  String get customTemplateLabel => '사용자 정의 템플릿';

  @override
  String get refreshDiagnostics => '진단 새로고침';

  @override
  String get failedToLoadDiagnostics => '진단을 불러오지 못했습니다';

  @override
  String get gestureDiagnosticsTitle => '제스처 진단';

  @override
  String get gestureDiagnosticsDescription =>
      '아래로 당겨 권한, 서비스, 네이티브 동기화 상태를 새로고침합니다.';

  @override
  String get slmDiagnosticsTitle => 'SLM 진단';

  @override
  String get slmDiagnosticsDescription =>
      '현재 모델, 캐시, 초기화 상태를 확인한 뒤 샘플 자체 점검 추론을 실행합니다.';

  @override
  String get allowlistedAppsLabel => '허용 목록 앱';

  @override
  String get floatingGestureLauncherTitle => '플로팅 제스처 실행기';

  @override
  String get floatingGestureLauncherEnabledDescription =>
      '설정의 제스처 마스터 토글이 활성화되어 있습니다.';

  @override
  String get floatingGestureLauncherDisabledDescription =>
      '마스터 토글이 꺼져 있으면 두 번 탭 및 세 번 탭 제스처가 실행되지 않습니다.';

  @override
  String get overlayPermissionTitle => '오버레이 권한';

  @override
  String get overlayPermissionGrantedDescription =>
      '시스템이 이 앱이 다른 앱 위에 표시되는 것을 허용합니다.';

  @override
  String get overlayPermissionDeniedDescription =>
      '이 권한이 없으면 플로팅 오버레이 서비스가 정상적으로 시작되지 않습니다.';

  @override
  String get usageAccessPermissionTitle => '사용량 액세스 권한';

  @override
  String get usageAccessGrantedDescription =>
      '허용 목록 확인을 위해 현재 전경 앱을 식별할 수 있습니다.';

  @override
  String get usageAccessDeniedDescription =>
      '이 권한이 없으면 허용 목록 일치 및 앱 간 제스처 트리거가 실패합니다.';

  @override
  String get floatingServiceStatusTitle => '플로팅 서비스 상태';

  @override
  String get floatingServiceRunningDescription =>
      '네이티브 플로팅 서비스가 현재 제스처를 대기 중입니다.';

  @override
  String get floatingServiceEnabledButStoppedDescription =>
      '마스터 토글은 켜져 있지만 네이티브 플로팅 서비스는 현재 실행 중이 아닙니다.';

  @override
  String get floatingServiceStoppedDescription =>
      '마스터 토글이 꺼져 있으면 서비스는 보통 중지된 상태를 유지합니다.';

  @override
  String get floatingServiceUnavailableDescription => '네이티브 서비스 상태를 읽지 못했습니다.';

  @override
  String get doubleTapActionSyncTitle => '두 번 탭 동작 동기화';

  @override
  String get doubleTapActionSyncedDescription =>
      '두 번 탭 동작이 네이티브 레이어와 동기화되었습니다.';

  @override
  String get doubleTapActionOutOfSyncDescription =>
      '현재 두 번 탭 동작이 네이티브 레이어와 일치하지 않습니다. 제스처 설정을 다시 저장하는 것을 권장합니다.';

  @override
  String get tripleTapActionSyncTitle => '세 번 탭 동작 동기화';

  @override
  String get tripleTapActionSyncedDescription =>
      '세 번 탭 동작이 네이티브 레이어와 동기화되었습니다.';

  @override
  String get tripleTapActionOutOfSyncDescription =>
      '현재 세 번 탭 동작이 네이티브 레이어와 일치하지 않습니다. 제스처 설정을 다시 저장하는 것을 권장합니다.';

  @override
  String get allowlistScopeTitle => '허용 목록 범위';

  @override
  String get allAppsValue => '모든 앱';

  @override
  String restrictedAppsValue(Object count) {
    return '$count개 앱으로 제한됨';
  }

  @override
  String get allowlistScopeAllAppsDescription => '현재 제스처는 모든 전경 앱에서 동작을 시도합니다.';

  @override
  String get allowlistScopeRestrictedDescription =>
      '현재 허용 목록에 있는 전경 앱만 제스처에 반응합니다.';

  @override
  String get allowlistNativeSyncTitle => '허용 목록 네이티브 동기화';

  @override
  String flutterNativeCountLabel(Object flutterCount, Object nativeCount) {
    return 'Flutter: $flutterCount / 네이티브: $nativeCount';
  }

  @override
  String actionSyncValue(Object flutterAction, Object nativeAction) {
    return 'Flutter: $flutterAction / 네이티브: $nativeAction';
  }

  @override
  String get allowlistNativeUnreadableDescription => '네이티브 허용 목록을 읽지 못했습니다.';

  @override
  String get allowlistNativeSyncedDescription => '허용 목록이 네이티브 레이어와 동기화되었습니다.';

  @override
  String get allowlistNativeOutOfSyncDescription =>
      'Flutter와 네이티브 허용 목록이 동기화되지 않았습니다. 허용 목록 페이지를 다시 열면 다시 동기화될 수 있습니다.';

  @override
  String get runtimeEnvironmentTitle => '실행 환경';

  @override
  String get environmentAndroid => 'Android';

  @override
  String get environmentWeb => 'Web';

  @override
  String get environmentDesktop => '데스크톱';

  @override
  String get runtimeEnvironmentAndroidDescription =>
      '이 환경은 온디바이스 SLM 추론을 시도하기 위한 기본 조건을 충족합니다.';

  @override
  String get runtimeEnvironmentNonAndroidDescription =>
      '이 환경은 Android가 아닙니다. 자체 점검은 실행할 수 있지만 보통 규칙 기반 폴백 경로를 따릅니다.';

  @override
  String get experimentalNativeInferenceFlagTitle => '실험적 네이티브 추론 플래그';

  @override
  String get experimentalNativeInferenceEnabledDescription =>
      '현재 앱 버전은 기본적으로 순수 규칙 모드를 사용하며, 이 상태는 향후 확장을 위해서만 유지됩니다.';

  @override
  String get experimentalNativeInferenceDisabledDescription =>
      '현재 앱 버전은 순수 규칙 엔진으로 전환되었으므로 네이티브 추론 경로는 더 이상 사용되지 않습니다.';

  @override
  String get nativeInferenceSupportTitle => '네이티브 추론 지원';

  @override
  String get nativeInferenceSupportAvailableDescription =>
      '현재 SLM 추론 경로에 필요한 네이티브 심볼과 런타임 조건이 충족된 것으로 보입니다.';

  @override
  String get nativeInferenceSupportUnavailableDescription =>
      '이 앱 버전은 더 이상 네이티브 추론을 제공하지 않습니다. 제목, 태그, 주제는 로컬 규칙으로 생성됩니다.';

  @override
  String get nativeSymbolDetectionTitle => '네이티브 심볼 감지';

  @override
  String get nativeSymbolDetectedDescription =>
      '필수 LlmInferenceEngine 심볼을 확인했습니다.';

  @override
  String get nativeSymbolMissingDescription =>
      '중요한 네이티브 심볼이 없으면 모델 추론은 즉시 규칙 모드로 폴백합니다.';

  @override
  String get bundledModelFormatTitle => '번들 모델 형식';

  @override
  String get slmInitializationStateTitle => 'SLM 초기화 상태';

  @override
  String get slmInitializedDescription =>
      '서비스가 이미 초기화되었으므로 이후 자체 점검도 현재 상태를 재사용합니다.';

  @override
  String get slmNotInitializedDescription =>
      '초기화가 아직 시작되지 않았습니다. 자체 점검을 실행하면 자동으로 시도합니다.';

  @override
  String get modelAvailabilityTitle => '모델 사용 가능 여부';

  @override
  String get modelAvailableNow => '현재 사용 가능';

  @override
  String get usingRuleFallback => '규칙 폴백 사용 중';

  @override
  String get modelAvailabilityAvailableDescription =>
      '이 기기에서는 모델 추론을 이미 직접 사용할 수 있습니다.';

  @override
  String get modelAvailabilityIncompatibleDescription =>
      '현재 모델 파일 형식은 현재 Android 네이티브 SLM 런타임과 호환되지 않으므로, 번들 모델을 교체할 때까지 런타임은 규칙 폴백 경로에 머뭅니다.';

  @override
  String get modelAvailabilityFallbackDescription =>
      '현재 앱 버전은 제목, 태그, 주제 생성에 로컬 규칙을 사용하며 기기 내 모델 추론에 의존하지 않습니다.';

  @override
  String modelFileMissingDescription(Object path) {
    return '현재 파일 경로: $path. 파일이 없으면 런타임은 자동으로 규칙 모드로 폴백합니다.';
  }

  @override
  String get modelCacheRuntimeParametersTitle => '모델 캐시 및 런타임 매개변수';

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
    return '$size · 최대 캐시 항목 $count';
  }

  @override
  String slmSelfCheckFailed(Object error) {
    return 'SLM 자체 점검 실패: $error';
  }

  @override
  String get slmSelfCheckTitle => 'SLM 자체 점검';

  @override
  String get slmSelfCheckAndroidHint =>
      '모델이 실제로 사용되는지 확인하려면 실제 Android 기기에서 한 번 실행해 보는 것이 가장 좋습니다.';

  @override
  String get slmSelfCheckNonAndroidHint =>
      '이 환경은 Android가 아니므로 자체 점검은 주로 폴백 동작과 설정 상태를 검증하는 데 유용합니다.';

  @override
  String get runSelfCheck => '자체 점검 실행';

  @override
  String get noSelfCheckYet =>
      '아직 자체 점검이 실행되지 않았습니다. 대상 기기에서 한 번 실행해 주제 추출과 제목/태그 생성이 모델 또는 규칙 폴백 중 무엇을 사용하는지 확인하는 것을 권장합니다.';

  @override
  String completedChipLabel(Object time) {
    return '$time 완료';
  }

  @override
  String get topicExtraction => '주제 추출';

  @override
  String get titleAndTagGeneration => '제목 및 태그 생성';

  @override
  String fallbackDetailLabel(Object latency, Object mode) {
    return '폴백: $mode · ${latency}ms';
  }

  @override
  String tagsDetailLabel(Object tags) {
    return '태그: $tags';
  }

  @override
  String get fallbackModel => '모델';

  @override
  String get fallbackCache => '캐시';

  @override
  String get fallbackRules => '규칙';

  @override
  String get fallbackDisabledUnavailable => '비활성/사용 불가';

  @override
  String get summaryBannerErrorTitle => '제스처 동작을 직접 깨뜨릴 수 있는 문제가 발견되었습니다';

  @override
  String get summaryBannerErrorDescription => '보통 권한 관련 문제를 먼저 해결해야 합니다.';

  @override
  String get summaryBannerWarningTitle => '주의가 필요한 제스처 구성 문제가 있습니다';

  @override
  String get summaryBannerWarningDescription =>
      '동기화 상태나 서비스 상태가 어긋나면 제스처가 예상대로 실행되지 않을 수 있습니다.';

  @override
  String get summaryBannerHealthyTitle => '뚜렷한 제스처 문제는 발견되지 않았습니다';

  @override
  String get summaryBannerHealthyDescription =>
      '권한, 서비스 상태, 네이티브 동기화가 모두 정상으로 보입니다.';

  @override
  String get ocrRecognitionTitlePrefix => 'OCR 인식';

  @override
  String ocrRecognizedCharacters(Object count) {
    return '$count자 인식';
  }

  @override
  String ocrFailedMessage(Object error) {
    return 'OCR 실패: $error';
  }

  @override
  String ocrProcessingFailedMessage(Object error) {
    return 'OCR 처리 실패: $error';
  }

  @override
  String get unableToReadImageFile => '이미지 파일을 읽을 수 없습니다';

  @override
  String get previewEnterContent => '추천 제목과 태그를 미리 보려면 내용을 입력하세요';

  @override
  String previewGenerationFailed(Object error) {
    return '미리보기 생성 실패: $error';
  }

  @override
  String get previewApplied => '미리보기 제목과 태그를 폼에 적용했습니다';

  @override
  String get contentRequiredMessage => '내용은 필수입니다';

  @override
  String get summaryUpdated => '요약이 업데이트되었습니다';

  @override
  String get duplicateFactMemoryUpdated => '중복된 사실 기억을 감지해 기존 레코드를 업데이트했습니다';

  @override
  String get savedAndMergedFactMemories => '사실 기억을 저장하고 병합했습니다';

  @override
  String saveFailedMessage(Object error) {
    return '저장 실패: $error';
  }

  @override
  String get mergeCandidatesFound => '병합 후보를 찾았습니다';

  @override
  String mergeCandidatesFoundDescription(Object title) {
    return '\"$title\"을(를) 저장했습니다. 다음 병합 후보를 확인하세요:';
  }

  @override
  String get laterLabel => '나중에';

  @override
  String get grantAccessLabel => '권한 허용';

  @override
  String get existingFactMemory => '기존 사실 기억';

  @override
  String get newFactMemory => '새 사실 기억';

  @override
  String get editSummary => '요약 편집';

  @override
  String get saveContent => '내용 저장';

  @override
  String get sharedBadge => '공유됨';

  @override
  String get remarkLabel => '비고';

  @override
  String get enterTitleHint => '제목 입력';

  @override
  String get contentShareHint => '다른 앱에서 공유한 내용이 자동으로 여기에 표시됩니다';

  @override
  String get remarkHint => '선택 사항인 맥락이나 메모를 추가하세요';

  @override
  String get tagsHint => '여러 태그는 쉼표로 구분하세요';

  @override
  String get previewSuggestedTitleTags => '추천 제목과 태그 미리보기';

  @override
  String get previewSuggestedTitleTagsDescription =>
      '활성화하면 현재 내용을 기반으로 추천을 생성하지만 폼을 자동으로 덮어쓰지는 않습니다';

  @override
  String get updateSummary => '요약 업데이트';

  @override
  String get requiredFieldHint => '* 는 필수 항목입니다';

  @override
  String get saveResultPreview => '저장 결과 미리보기';

  @override
  String get previewPrimaryDescription =>
      '이 미리보기는 주로 본문 내용을 기반으로 제목과 태그를 추천합니다.';

  @override
  String get suggestedTitle => '추천 제목';

  @override
  String get suggestedTags => '추천 태그';

  @override
  String get applyToForm => '폼에 적용';

  @override
  String get generatedByBuiltInModel => '네이티브 SLM 런타임으로 생성됨';

  @override
  String get generatedByLocalRules => '로컬 규칙으로 생성됨';

  @override
  String get pendingSummary => '정리 대기 요약';

  @override
  String get temporaryTopic => '임시 주제';

  @override
  String get generalTopic => '일반 주제';

  @override
  String get uncategorized => '미분류';

  @override
  String get unknownModelFormat => '알 수 없는 모델 형식';

  @override
  String modelFormatBundledSupported(Object extension) {
    return '번들된 .$extension 자산을 감지했습니다. 현재 로컬 규칙 모드는 네이티브 런타임 없이도 계속 실행할 수 있습니다.';
  }

  @override
  String modelFormatUnsupportedForLocalRules(Object extension) {
    return '현재 로컬 규칙 모드는 .$extension 자산을 지원하지 않습니다.';
  }

  @override
  String get slmSelfCheckTopicSampleContent =>
      '이 진단 샘플은 현재 기기에서 로컬 규칙 기반 주제 추출이 정상 동작하는지 확인하기 위한 것입니다.';

  @override
  String get slmSelfCheckMetadataSampleContent =>
      '이 진단 샘플은 현재 Local Vault 환경에서 제목과 태그 생성이 정상 동작하는지 확인하기 위한 것입니다. 검색하기 쉬운 제목과 2~4개의 태그를 생성하세요.';
}
