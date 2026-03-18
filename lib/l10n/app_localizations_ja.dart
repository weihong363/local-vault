// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ローカル記憶庫';

  @override
  String get home => 'ホーム';

  @override
  String get templates => 'テンプレート';

  @override
  String get chooseTemplate => 'テンプレートを選択';

  @override
  String get addTemplate => 'テンプレートを追加';

  @override
  String get editTemplate => 'テンプレートを編集';

  @override
  String get memory => '記憶';

  @override
  String get myMemories => 'マイメモリー';

  @override
  String get settings => '設定';

  @override
  String get search => '検索';

  @override
  String get save => '保存';

  @override
  String get saveSummaryQuickActionTitle => '要約を保存';

  @override
  String get inject => '注入';

  @override
  String get generalSettings => '一般設定';

  @override
  String get themeSettings => 'テーマ設定';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get lightMode => 'ライトモード';

  @override
  String get systemMode => 'システム';

  @override
  String get language => '言語';

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
  String get storageSettings => 'ストレージ設定';

  @override
  String get storageSpace => 'ストレージ容量';

  @override
  String get backupData => 'データバックアップ';

  @override
  String get about => '情報';

  @override
  String get versionInfo => 'バージョン情報';

  @override
  String get feedback => 'フィードバック';

  @override
  String get inDevelopment => '開発中';

  @override
  String get comingSoon => '近日公開';

  @override
  String get title => 'タイトル';

  @override
  String get content => '内容';

  @override
  String get tags => 'タグ';

  @override
  String get saveToVault => 'ローカル記憶庫に保存';

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get savedToVault => 'ローカル記憶庫に保存しました';

  @override
  String get titleAndContentRequired => 'タイトルと内容は必須です';

  @override
  String get commaSeparatedTagsHint => 'タグ（カンマ区切り）';

  @override
  String get searchHint => 'タイトル、内容、タグで検索...';

  @override
  String get noSearchResults => '検索結果がありません';

  @override
  String get noData => 'データがありません';

  @override
  String get noTemplatesYet => 'テンプレートはまだありません';

  @override
  String get noSummariesYet => 'まだ記憶はありません';

  @override
  String get navHome => 'ホーム';

  @override
  String get navTemplates => 'テンプレート';

  @override
  String get navMemory => '記憶';

  @override
  String get navSettings => '設定';

  @override
  String get refresh => '更新';

  @override
  String get cancelLabel => 'キャンセル';

  @override
  String get continueLabel => '続行';

  @override
  String get deleteLabel => '削除';

  @override
  String get deleteSummary => '要約を削除';

  @override
  String get deleteTemplate => 'テンプレートを削除';

  @override
  String get shareLabel => '共有';

  @override
  String get restoreLabel => '復元';

  @override
  String get retryLabel => '再試行';

  @override
  String get closeLabel => '閉じる';

  @override
  String get workingLabel => '処理中...';

  @override
  String get okLabel => 'OK';

  @override
  String get quickSave => 'クイック保存';

  @override
  String get manualInput => '手動入力';

  @override
  String get quickSaveClipboardTip =>
      'ヒント: クイック保存ではクリップボードのテキストが自動的に使われます。\n空の場合は手動で内容を入力できます。';

  @override
  String get invalidActionType => '無効な操作タイプです';

  @override
  String get quickActions => 'クイック操作';

  @override
  String get enableFloatingGestureLauncher => 'フローティングジェスチャー起動を有効化';

  @override
  String get floatingGestureLauncherDescription => '他のアプリからジェスチャーで素早くアプリを開きます';

  @override
  String get gestureConfiguration => 'ジェスチャー設定';

  @override
  String get gestureConfigurationDescription => 'ジェスチャーの動作をカスタマイズします';

  @override
  String get appAllowlist => '許可アプリ一覧';

  @override
  String get appAllowlistDescription => 'ジェスチャーは選択したアプリ内でのみ有効です';

  @override
  String get diagnostics => '診断';

  @override
  String get diagnosticsDescription => 'ジェスチャー権限、サービス、同期状態を確認します';

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
  String get titleTagsUseBuiltInModel => 'タイトルとタグは内蔵モデルを使用します';

  @override
  String get titleTagsUseLocalRuleGenerator => 'タイトルとタグはローカルのルール生成を使用します';

  @override
  String get storageSummaryTapToView => 'タップして保存容量の詳細を表示';

  @override
  String get createShareRestoreLocalBackups => 'ローカルバックアップの作成、共有、復元';

  @override
  String storageSummaryFormat(
      Object bytes, Object summaryCount, Object templateCount) {
    return '$bytes ・ 要約 $summaryCount 件 ・ テンプレート $templateCount 件';
  }

  @override
  String get backupSummaryNone => 'まだローカルバックアップがありません。タップして作成できます';

  @override
  String backupSummaryAvailable(Object backupCount) {
    return 'ローカルバックアップ $backupCount 件';
  }

  @override
  String get architectureChecksDebugOnly => 'アーキテクチャ確認 - DEBUG 専用';

  @override
  String get runArchitectureVerification => 'アーキテクチャ確認を実行';

  @override
  String get runArchitectureVerificationDescription =>
      '新しいアーキテクチャが正しく動作しているか確認します';

  @override
  String get runningArchitectureVerification => 'アーキテクチャ確認を実行中...';

  @override
  String get architectureVerificationFinished =>
      'アーキテクチャ確認が完了しました。コンソール出力を確認してください。';

  @override
  String get inspectDatabase => 'データベースを確認';

  @override
  String get inspectDatabaseDescription => '要約とテンプレート保存領域の生データを表示します';

  @override
  String get notAllPermissionsGranted =>
      'すべての権限が付与されていません。ジェスチャー機能が正しく動作しない可能性があります。';

  @override
  String get floatingWindowServiceStarted => 'フローティングウィンドウサービスを開始しました';

  @override
  String get floatingWindowServiceStopped => 'フローティングウィンドウサービスを停止しました';

  @override
  String failedToStartMessage(Object error) {
    return '開始に失敗しました: $error';
  }

  @override
  String failedToStopMessage(Object error) {
    return '停止に失敗しました: $error';
  }

  @override
  String get serviceStarted => 'サービス開始';

  @override
  String get floatingWindowTips =>
      'フローティングジェスチャーサービスが開始されました。\n\n使い方:\n1. 画面端付近の半透明のジェスチャー領域を探してください。\n2. その領域内でスワイプするとアプリをすばやく起動できます。\n3. オーバーレイが表示されない場合は、必要な権限がすべて付与されているか確認してください。\n\n重要:\nアプリ切り替え後にジェスチャーが動作しない場合は、次を確認してください:\n- アプリが許可リストに含まれているか\n- 使用状況アクセス権限が付与されているか';

  @override
  String get openAllowlist => '許可リストを開く';

  @override
  String get memoryManagement => '記憶管理';

  @override
  String loadFailedMessage(Object error) {
    return '読み込みに失敗しました: $error';
  }

  @override
  String get loadFailedLabel => '読み込みに失敗しました';

  @override
  String errorWithDetails(Object error) {
    return 'エラー: $error';
  }

  @override
  String deleteSummaryConfirm(Object title) {
    return '「$title」を削除しますか？';
  }

  @override
  String deleteTemplateConfirm(Object title) {
    return 'テンプレート「$title」を削除しますか？';
  }

  @override
  String deleteFailedMessage(Object error) {
    return '削除に失敗しました: $error';
  }

  @override
  String get templateDeleted => 'テンプレートを削除しました';

  @override
  String get currentView => '現在の表示';

  @override
  String get allMemories => 'すべての記憶';

  @override
  String get searchFilter => '検索フィルター';

  @override
  String itemCountLabel(Object count) {
    return '$count 件';
  }

  @override
  String get notFiltered => '未適用';

  @override
  String get filtered => '適用中';

  @override
  String get memoryType => '記憶タイプ';

  @override
  String metaImportanceLabel(Object percent) {
    return '重要度 $percent';
  }

  @override
  String metaVisitsLabel(Object count) {
    return 'アクセス $count';
  }

  @override
  String metaUpdatedLabel(Object date) {
    return '$date に更新';
  }

  @override
  String metaLastOpenedLabel(Object date) {
    return '最終表示 $date';
  }

  @override
  String get editLabel => '編集';

  @override
  String get promoteToCore => 'コアに昇格';

  @override
  String get setAsCore => 'コアに設定';

  @override
  String get setAsCoreMemory => 'コア記憶に設定';

  @override
  String get mergeSimilar => '類似項目を統合';

  @override
  String get importanceScore => '重要度スコア';

  @override
  String get refreshAndCleanup => '更新して整理';

  @override
  String get refreshCleanupCompleted => '更新と整理が完了しました';

  @override
  String get promoteToCoreMemory => 'コア記憶に昇格';

  @override
  String promotionDialogBody(Object title) {
    return '\"$title\" は通常の忘却減衰の対象外となり、優先度の高い長期記憶として保持されます。';
  }

  @override
  String promotionStatsLine(Object accessCount, Object importancePercent) {
    return '現在のアクセス $accessCount 回 ・ 重要度 $importancePercent';
  }

  @override
  String get promotionThresholdMet => 'この記憶はすでに自動昇格のしきい値を満たしています。';

  @override
  String get promotionThresholdNotMet =>
      'この記憶はまだ自動しきい値に達していませんが、手動でコア記憶として固定できます。';

  @override
  String promotionThresholdLine(
      Object accessCountThreshold, Object importanceThreshold) {
    return '現在の自動しきい値: アクセス数 >= $accessCountThreshold または 重要度 >= $importanceThreshold';
  }

  @override
  String get generatingPromotionReason => '昇格理由を生成中...';

  @override
  String get promotionReason => '昇格理由';

  @override
  String get defaultPromotionReason =>
      'この記憶は継続的な価値があり、長期的なコア記憶として保持するのに適しています。';

  @override
  String get upgradeReasonHighAccess =>
      'この記憶は頻繁に参照され、長期的な価値が安定しているため、コア記憶への昇格に適しています。';

  @override
  String get upgradeReasonHighImportance =>
      'この記憶は重要度が高く、長期的なコア記憶として保持する価値があります。';

  @override
  String get confirmPromotion => '昇格を確認';

  @override
  String get confirmSetAsCore => 'コア設定を確認';

  @override
  String get promotedToCoreMemory => 'コア記憶に昇格しました';

  @override
  String get setAsCoreSuccess => 'コア記憶に設定しました';

  @override
  String get viewCore => 'コアを表示';

  @override
  String get noSimilarMemoriesFound => '類似する記憶が見つかりません';

  @override
  String get currentFactMemory => '現在の事実記憶';

  @override
  String get candidateFactMemory => '候補の事実記憶';

  @override
  String get mergeCompleted => '統合が完了しました';

  @override
  String get chooseMemoryToCompare => '比較する記憶を選択';

  @override
  String mergeCandidateCount(Object title, Object count) {
    return '\"$title\" には $count 件の統合候補があります';
  }

  @override
  String similarityWithContent(Object similarity, Object content) {
    return '類似度 $similarity ・ $content';
  }

  @override
  String get deleteMemory => '記憶を削除';

  @override
  String deleteMemoryConfirm(Object title) {
    return '\"$title\" を削除しますか？';
  }

  @override
  String get deletedLabel => '削除済み';

  @override
  String get factMemories => '事実記憶';

  @override
  String get coreMemories => 'コア記憶';

  @override
  String get sessionMemories => 'セッション記憶';

  @override
  String get factMemoryLabel => '事実';

  @override
  String get coreMemoryLabel => 'コア';

  @override
  String get sessionMemoryLabel => 'セッション';

  @override
  String get factMemoryDescription => '長期保存に適した通常の事実や安定した情報です。';

  @override
  String get coreMemoryDescription => '通常の忘却減衰に参加しない、最優先の長期記憶です。';

  @override
  String get sessionMemoryDescription => '短期的な整理に役立つ、最近のやり取りから得た一時的な文脈です。';

  @override
  String relativeMinutesAgo(Object count) {
    return '$count 分前';
  }

  @override
  String relativeHoursAgo(Object count) {
    return '$count 時間前';
  }

  @override
  String relativeDaysAgo(Object count) {
    return '$count 日前';
  }

  @override
  String get noMatchingMemories => '一致する記憶がありません';

  @override
  String get noFactMemoriesYet => '事実記憶はまだありません';

  @override
  String get noCoreMemoriesYet => 'コア記憶はまだありません';

  @override
  String get noSessionMemoriesYet => 'セッション記憶はまだありません';

  @override
  String get mergeFactMemories => '事実記憶を統合';

  @override
  String get mergeFactMemoriesDescription =>
      '2 つのバージョンを比較し、最終的に残すタイトル、内容、タグを選択してください。';

  @override
  String similarityPercent(Object percent) {
    return '類似度 $percent';
  }

  @override
  String get mergedPreview => '統合プレビュー';

  @override
  String get noTags => 'タグなし';

  @override
  String get notNow => '今回はしない';

  @override
  String get mergingLabel => '統合中...';

  @override
  String get confirmMerge => '統合を確定';

  @override
  String get keepOriginal => '元を残す';

  @override
  String get keepNew => '新規を残す';

  @override
  String get smartMerge => 'スマート統合';

  @override
  String get emptyValue => '空';

  @override
  String get candidateMemory => '候補記憶';

  @override
  String mergeFailedMessage(Object error) {
    return '統合に失敗しました: $error';
  }

  @override
  String get clearModelCache => 'モデルキャッシュを削除';

  @override
  String get clearModelCacheMessage =>
      'ローカルのモデル推論キャッシュを削除しますが、要約、テンプレート、モデルファイル自体は保持されます。';

  @override
  String get noModelCacheFilesToClear => '削除できるモデルキャッシュがありません';

  @override
  String clearedModelCacheResult(Object count, Object bytes) {
    return 'キャッシュファイル $count 件を削除し、$bytes を解放しました';
  }

  @override
  String get clearBackupFiles => 'バックアップファイルを削除';

  @override
  String get clearBackupFilesMessage =>
      'ローカルで生成されたバックアップファイルを削除しますが、データベース内の現在の要約とテンプレートには影響しません。';

  @override
  String get noBackupFilesToClear => '削除できるバックアップファイルがありません';

  @override
  String deletedBackupFilesResult(Object count, Object bytes) {
    return 'バックアップファイル $count 件を削除し、$bytes を解放しました';
  }

  @override
  String failedToReadStorageUsage(Object error) {
    return '保存容量の読み取りに失敗しました: $error';
  }

  @override
  String get totalStorageUsed => '使用中の総ストレージ';

  @override
  String storageOverviewCounts(
      Object summaryCount, Object templateCount, Object backupCount) {
    return '要約 $summaryCount 件 ・ テンプレート $templateCount 件 ・ バックアップ $backupCount 件';
  }

  @override
  String get summaryDatabase => '要約データベース';

  @override
  String summaryDatabaseSubtitle(Object count) {
    return '要約 $count 件';
  }

  @override
  String get templateDatabase => 'テンプレートデータベース';

  @override
  String templateDatabaseSubtitle(Object count) {
    return 'テンプレート $count 件';
  }

  @override
  String get backupFiles => 'バックアップファイル';

  @override
  String backupFilesSubtitle(Object count) {
    return 'バックアップ $count 件';
  }

  @override
  String get modelFile => 'モデルファイル';

  @override
  String get bundledModelFootprint => '同梱モデルの容量';

  @override
  String get modelCache => 'モデルキャッシュ';

  @override
  String get inferenceCacheAndIntermediateFiles => '推論キャッシュと中間ファイル';

  @override
  String get cleanupTools => 'クリーンアップツール';

  @override
  String get clearLocalBackupFiles => 'ローカルバックアップを削除';

  @override
  String backupCreatedMessage(Object fileName) {
    return 'バックアップを作成しました: $fileName';
  }

  @override
  String failedToCreateBackupMessage(Object error) {
    return 'バックアップの作成に失敗しました: $error';
  }

  @override
  String importFailedMessage(Object error) {
    return 'インポートに失敗しました: $error';
  }

  @override
  String get importFailedUnableReadSelectedFile =>
      'インポートに失敗しました: 選択したファイルを読み取れません';

  @override
  String get unknownValue => '不明';

  @override
  String get importBackup => 'バックアップをインポート';

  @override
  String backupImportPreviewMessage(
      Object summaryCount, Object templateCount, Object exportedAt) {
    return 'このバックアップには要約 $summaryCount 件とテンプレート $templateCount 件が含まれます。\nエクスポート日時: $exportedAt\n\nインポートすると現在の要約とテンプレートのデータが上書きされます。続行しますか？';
  }

  @override
  String importFinishedMessage(Object summaryCount, Object templateCount) {
    return 'インポート完了: 要約 $summaryCount 件、テンプレート $templateCount 件';
  }

  @override
  String get invalidBackupFileFormat => 'インポートに失敗しました: バックアップファイルの形式が無効です';

  @override
  String get restoreBackupMessage => '復元すると現在の要約とテンプレートのデータが上書きされます。続行しますか？';

  @override
  String restoreFinishedMessage(Object summaryCount, Object templateCount) {
    return '復元完了: 要約 $summaryCount 件、テンプレート $templateCount 件';
  }

  @override
  String restoreFailedMessage(Object error) {
    return '復元に失敗しました: $error';
  }

  @override
  String deleteBackupConfirmMessage(Object fileName) {
    return 'バックアップ $fileName を削除しますか？';
  }

  @override
  String get backupDeleted => 'バックアップを削除しました';

  @override
  String failedToLoadBackupList(Object error) {
    return 'バックアップ一覧の読み込みに失敗しました: $error';
  }

  @override
  String get noLocalBackupFilesYet => 'ローカルバックアップファイルはまだありません';

  @override
  String get localBackups => 'ローカルバックアップ';

  @override
  String backupFilesAvailable(Object count) {
    return '利用可能なバックアップファイル $count 件';
  }

  @override
  String get backupOverviewDescription =>
      'バックアップを作成すると JSON ファイルが生成され、共有シートが開きます。アプリ外からバックアップファイルを取り込むこともできます。';

  @override
  String get createAndShareBackup => 'バックアップを作成して共有';

  @override
  String get importBackupData => 'バックアップデータをインポート';

  @override
  String get shareBackupText => 'ローカル記憶庫のバックアップ';

  @override
  String get shareBackupSubject => 'ローカル記憶庫バックアップ';

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
