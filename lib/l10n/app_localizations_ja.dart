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
  String get showFullContent => '全文を表示';

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
  String get slmInferenceSettingTitle => 'SLM 推論を有効化';

  @override
  String get slmInferenceSettingDescription =>
      'この設定は将来の互換性のために残されています。現在のアプリ版では、タイトル・タグ・トピックの生成に常にローカルルールを使用します。';

  @override
  String get slmInferenceEnabledMessage =>
      'SLM 設定を有効にしました。現在のアプリ版では、引き続きタイトル・タグ・トピックの生成にローカルルールを使用します。';

  @override
  String get slmInferenceDisabledMessage =>
      'SLM 設定を無効にしました。現在のアプリ版では、引き続きタイトル・タグ・トピックの生成にローカルルールを使用します。';

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
  String get permissionsRequiredTitle => '権限が必要です';

  @override
  String get permissionsRequiredMessage =>
      'ジェスチャー起動を正しく動作させるには、次の権限が必要です：\n\n1. オーバーレイ権限：他のアプリの上にジェスチャー検出エリアを表示するために使用します\n2. 使用状況アクセス権限：現在前面にあるアプリを検出し、許可リストのアプリでジェスチャーエリアを表示するために使用します\n\nこの後の画面で、これらの権限を許可してください。';

  @override
  String get usageAccessPermissionRequiredTitle => '使用状況アクセス権限が必要です';

  @override
  String get usageAccessPermissionRequiredMessage =>
      '使用状況アクセス権限がありません。\n\nこの権限がないと：\n• 現在アクティブなアプリを判別できません\n• 他のアプリでジェスチャー起動が正しく動作しません\n\n「アクセスを許可」をタップしてシステム設定を開き、このアプリの権限を有効にしてください。';

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
  String get currentFactMemory => '原版記憶';

  @override
  String get candidateFactMemory => '新版記憶';

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
  String get confirmLabel => '確認';

  @override
  String get clearLabel => 'クリア';

  @override
  String get runningLabel => '実行中...';

  @override
  String get unknownError => '不明なエラー';

  @override
  String get statusEnabled => '有効';

  @override
  String get statusDisabled => '無効';

  @override
  String get statusGranted => '許可済み';

  @override
  String get statusNotGranted => '未許可';

  @override
  String get statusRunning => '実行中';

  @override
  String get statusStopped => '停止中';

  @override
  String get statusUnavailable => '利用不可';

  @override
  String get statusAvailable => '利用可能';

  @override
  String get statusMissing => '不足';

  @override
  String get statusReady => '準備完了';

  @override
  String get statusCompatible => '互換あり';

  @override
  String get statusIncompatible => '互換なし';

  @override
  String get statusInitialized => '初期化済み';

  @override
  String get statusNotInitialized => '未初期化';

  @override
  String get statusDetected => '検出済み';

  @override
  String get statusNotDetected => '未検出';

  @override
  String get statusModelUsed => 'モデル使用';

  @override
  String get statusModelNotUsed => 'モデル未使用';

  @override
  String get statusInitializationComplete => '初期化完了';

  @override
  String get statusInitializationIncomplete => '初期化未完了';

  @override
  String get gestureConfigurationSaved => '設定を保存しました';

  @override
  String gestureConfigurationLoadFailed(Object error) {
    return 'ジェスチャー設定の読み込みに失敗しました: $error';
  }

  @override
  String get resetToDefaults => 'デフォルトに戻す';

  @override
  String get resetGesturesToDefaultsMessage => 'すべてのジェスチャーをデフォルト設定に戻しますか？';

  @override
  String get restoredDefaultSettings => 'デフォルト設定を復元しました';

  @override
  String get gestureShareOnly => '共有のみ';

  @override
  String get gestureActionOpenTemplates => 'プロンプトテンプレートを開く';

  @override
  String get gestureActionSaveSummary => '共有コンテンツから要約を保存';

  @override
  String get gestureActionOpenSavedContext => '保存済みコンテキストを開く';

  @override
  String get gestureDoubleTap => 'ダブルタップ';

  @override
  String get gestureTripleTap => 'トリプルタップ';

  @override
  String get triggerAction => '実行アクション';

  @override
  String get alreadyUsedByAnotherGesture => 'すでに別のジェスチャーで使用されています';

  @override
  String get searchAppsHint => 'アプリを検索...';

  @override
  String appWhitelistLoadFailed(Object error) {
    return '読み込みに失敗しました: $error';
  }

  @override
  String selectedAppsCount(Object count) {
    return '選択中のアプリ $count 件';
  }

  @override
  String get clearAllowlistTooltip => '許可リストをクリア';

  @override
  String get gesturesActiveInAllApps => 'ジェスチャーはすべてのアプリで有効です';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterSelected => '選択済み';

  @override
  String get filterUnselected => '未選択';

  @override
  String get noAppsFound => 'アプリが見つかりません';

  @override
  String get noMatchingAppsFound => '一致するアプリが見つかりません';

  @override
  String get noSelectedAppsYet => 'まだアプリが選択されていません';

  @override
  String get noUnselectedApps => '未選択のアプリはありません';

  @override
  String get clearAllowlistTitle => '許可リストをクリア';

  @override
  String get clearAllowlistMessage =>
      'アプリの許可リストをクリアしますか？ ジェスチャーはすべてのアプリで有効になります。';

  @override
  String get allowlistCleared => '許可リストをクリアしました';

  @override
  String get databaseInspector => 'データベースインスペクター';

  @override
  String failedToOpenDatabase(Object error) {
    return 'データベースを開けませんでした: $error';
  }

  @override
  String get summariesTab => '要約';

  @override
  String get templatesTab => 'テンプレート';

  @override
  String get noSummaryRecordsInBox => 'このボックスに要約レコードはありません';

  @override
  String get noTemplateRecordsInBox => 'このボックスにテンプレートレコードはありません';

  @override
  String recordsWithIssues(Object count) {
    return '問題のあるレコード: $count';
  }

  @override
  String legacyTemplateTypes(Object count) {
    return '旧テンプレート型: $count';
  }

  @override
  String defaultTemplatesCount(Object count) {
    return 'デフォルトテンプレート: $count';
  }

  @override
  String boxMetricLabel(Object boxName) {
    return 'ボックス: $boxName';
  }

  @override
  String recordsMetricLabel(Object count) {
    return 'レコード: $count';
  }

  @override
  String keyMetricLabel(Object key) {
    return 'キー: $key';
  }

  @override
  String get noObviousIssuesDetected => '明らかな問題は検出されませんでした';

  @override
  String issuesMetricLabel(Object count) {
    return '問題数: $count';
  }

  @override
  String get copyJson => 'JSON をコピー';

  @override
  String get recordNotMapCorrupted => 'レコードは Map ではなく、破損している可能性があります';

  @override
  String get unparseableSummaryRecord => '解析できない要約レコード';

  @override
  String get unparseableTemplateRecord => '解析できないテンプレートレコード';

  @override
  String rawTypeLabel(Object type) {
    return '生の型: $type';
  }

  @override
  String get legacyTemplateRecordDetected =>
      '旧テンプレート型レコードを検出しました。fact として読み込みます';

  @override
  String get missingId => 'ID がありません';

  @override
  String get titleIsEmpty => 'タイトルが空です';

  @override
  String get contentIsEmpty => '内容が空です';

  @override
  String get accessCountInvalid => 'accessCount が有効な数値ではありません';

  @override
  String get accessCountBelowZero => 'accessCount が 0 未満です';

  @override
  String get createdAtCouldNotBeParsed => 'createdAt を解析できませんでした';

  @override
  String summaryDeserializationFailed(Object error) {
    return 'SummaryEntity のデシリアライズに失敗しました: $error';
  }

  @override
  String templateDeserializationFailed(Object error) {
    return 'TemplateEntity のデシリアライズに失敗しました: $error';
  }

  @override
  String get unknownTime => '不明な時刻';

  @override
  String get untitledSummary => '(無題の要約)';

  @override
  String get untitledTemplate => '(無題のテンプレート)';

  @override
  String summaryRecordSubtitle(
      Object accessCount, Object createdAt, Object type) {
    return '種類: $type  アクセス: $accessCount  作成: $createdAt';
  }

  @override
  String templateRecordSubtitle(Object createdAt, Object templateKind) {
    return '$templateKind  作成: $createdAt';
  }

  @override
  String get defaultTemplateLabel => 'デフォルトテンプレート';

  @override
  String get customTemplateLabel => 'カスタムテンプレート';

  @override
  String get refreshDiagnostics => '診断を更新';

  @override
  String get failedToLoadDiagnostics => '診断の読み込みに失敗しました';

  @override
  String get gestureDiagnosticsTitle => 'ジェスチャー診断';

  @override
  String get gestureDiagnosticsDescription => '下に引いて、権限・サービス・ネイティブ同期状態を更新します。';

  @override
  String get slmDiagnosticsTitle => 'SLM 診断';

  @override
  String get slmDiagnosticsDescription =>
      '現在のモデル、キャッシュ、初期化状態を確認し、サンプルのセルフチェック推論を実行します。';

  @override
  String get allowlistedAppsLabel => '許可リスト対象アプリ';

  @override
  String get floatingGestureLauncherTitle => 'フローティングジェスチャーランチャー';

  @override
  String get floatingGestureLauncherEnabledDescription =>
      '設定のジェスチャーマスター切り替えは有効です。';

  @override
  String get floatingGestureLauncherDisabledDescription =>
      'マスター切り替えが無効のとき、ダブルタップとトリプルタップのジェスチャーは発火しません。';

  @override
  String get overlayPermissionTitle => 'オーバーレイ権限';

  @override
  String get overlayPermissionGrantedDescription =>
      'システムにより、このアプリは他のアプリ上に表示できます。';

  @override
  String get overlayPermissionDeniedDescription =>
      'この権限がないと、フローティングオーバーレイサービスは正常に開始できません。';

  @override
  String get usageAccessPermissionTitle => '使用状況アクセス権限';

  @override
  String get usageAccessGrantedDescription => '許可リスト確認のために現在の前面アプリを判別できます。';

  @override
  String get usageAccessDeniedDescription =>
      'この権限がないと、許可リスト照合やアプリ横断ジェスチャー起動が失敗します。';

  @override
  String get floatingServiceStatusTitle => 'フローティングサービス状態';

  @override
  String get floatingServiceRunningDescription =>
      'ネイティブのフローティングサービスは現在ジェスチャーを待機しています。';

  @override
  String get floatingServiceEnabledButStoppedDescription =>
      'マスター切り替えは有効ですが、ネイティブのフローティングサービスは現在動作していません。';

  @override
  String get floatingServiceStoppedDescription =>
      'マスター切り替えが無効な場合、サービスは通常停止したままです。';

  @override
  String get floatingServiceUnavailableDescription =>
      'ネイティブサービスの状態を読み取れませんでした。';

  @override
  String get doubleTapActionSyncTitle => 'ダブルタップ動作の同期';

  @override
  String get doubleTapActionSyncedDescription => 'ダブルタップ動作はネイティブ層と同期されています。';

  @override
  String get doubleTapActionOutOfSyncDescription =>
      '現在のダブルタップ動作はネイティブ層と一致していません。ジェスチャー設定を再保存することをおすすめします。';

  @override
  String get tripleTapActionSyncTitle => 'トリプルタップ動作の同期';

  @override
  String get tripleTapActionSyncedDescription => 'トリプルタップ動作はネイティブ層と同期されています。';

  @override
  String get tripleTapActionOutOfSyncDescription =>
      '現在のトリプルタップ動作はネイティブ層と一致していません。ジェスチャー設定を再保存することをおすすめします。';

  @override
  String get allowlistScopeTitle => '許可リスト範囲';

  @override
  String get allAppsValue => 'すべてのアプリ';

  @override
  String restrictedAppsValue(Object count) {
    return '$count 件のアプリに制限';
  }

  @override
  String get allowlistScopeAllAppsDescription => '現在、ジェスチャーはすべての前面アプリで動作を試みます。';

  @override
  String get allowlistScopeRestrictedDescription =>
      '現在、許可リストにある前面アプリのみがジェスチャーに反応します。';

  @override
  String get allowlistNativeSyncTitle => '許可リストのネイティブ同期';

  @override
  String flutterNativeCountLabel(Object flutterCount, Object nativeCount) {
    return 'Flutter: $flutterCount / ネイティブ: $nativeCount';
  }

  @override
  String actionSyncValue(Object flutterAction, Object nativeAction) {
    return 'Flutter: $flutterAction / ネイティブ: $nativeAction';
  }

  @override
  String get allowlistNativeUnreadableDescription => 'ネイティブの許可リストを読み取れませんでした。';

  @override
  String get allowlistNativeSyncedDescription => '許可リストはネイティブ層と同期されています。';

  @override
  String get allowlistNativeOutOfSyncDescription =>
      'Flutter とネイティブの許可リストが同期していません。許可リストページを開き直すと再同期が走る場合があります。';

  @override
  String get runtimeEnvironmentTitle => '実行環境';

  @override
  String get environmentAndroid => 'Android';

  @override
  String get environmentWeb => 'Web';

  @override
  String get environmentDesktop => 'デスクトップ';

  @override
  String get runtimeEnvironmentAndroidDescription =>
      'この環境は、端末内 SLM 推論を試行するための基本条件を満たしています。';

  @override
  String get runtimeEnvironmentNonAndroidDescription =>
      'これは Android 環境ではありません。セルフチェックは実行できますが、通常はルールベースのフォールバック経路になります。';

  @override
  String get experimentalNativeInferenceFlagTitle => '実験的ネイティブ推論フラグ';

  @override
  String get experimentalNativeInferenceEnabledDescription =>
      '現在のアプリ版はデフォルトで純粋なルールモードを使用しており、この状態は将来の拡張のためだけに保持されています。';

  @override
  String get experimentalNativeInferenceDisabledDescription =>
      '現在のアプリ版は純粋なルールエンジンに切り替わっているため、ネイティブ推論経路はもう使用されません。';

  @override
  String get nativeInferenceSupportTitle => 'ネイティブ推論サポート';

  @override
  String get nativeInferenceSupportAvailableDescription =>
      '現在の SLM 推論経路に必要なネイティブシンボルと実行条件は満たされているようです。';

  @override
  String get nativeInferenceSupportUnavailableDescription =>
      'このアプリ版ではネイティブ推論を提供しません。タイトル、タグ、トピックはローカルルールで生成されます。';

  @override
  String get nativeSymbolDetectionTitle => 'ネイティブシンボル検出';

  @override
  String get nativeSymbolDetectedDescription =>
      '必要な LlmInferenceEngine シンボルが確認できました。';

  @override
  String get nativeSymbolMissingDescription =>
      '重要なネイティブシンボルが不足している場合、モデル推論は即座にルールモードへフォールバックします。';

  @override
  String get bundledModelFormatTitle => '同梱モデル形式';

  @override
  String get slmInitializationStateTitle => 'SLM 初期化状態';

  @override
  String get slmInitializedDescription =>
      'サービスはすでに初期化されているため、以後のセルフチェックでも現在の状態を再利用します。';

  @override
  String get slmNotInitializedDescription =>
      '初期化はまだ開始されていません。セルフチェックを実行すると自動的に試行します。';

  @override
  String get modelAvailabilityTitle => 'モデル利用可能性';

  @override
  String get modelAvailableNow => '現在利用可能';

  @override
  String get usingRuleFallback => 'ルールフォールバックを使用中';

  @override
  String get modelAvailabilityAvailableDescription =>
      'この端末では、モデル推論をすでに直接利用できます。';

  @override
  String get modelAvailabilityIncompatibleDescription =>
      '現在のモデルファイル形式は現在の Android ネイティブ SLM ランタイムと互換性がないため、同梱モデルを差し替えるまでランタイムはルールフォールバック経路のままになります。';

  @override
  String get modelAvailabilityFallbackDescription =>
      '現在のアプリ版では、タイトル・タグ・トピックの生成にローカルルールを使用し、端末内モデル推論には依存しません。';

  @override
  String modelFileMissingDescription(Object path) {
    return '現在のファイルパス: $path。ファイルが存在しない場合、ランタイムは自動的にルールモードへフォールバックします。';
  }

  @override
  String get modelCacheRuntimeParametersTitle => 'モデルキャッシュと実行パラメータ';

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
    return '$size · 最大キャッシュ件数 $count';
  }

  @override
  String slmSelfCheckFailed(Object error) {
    return 'SLM セルフチェックに失敗しました: $error';
  }

  @override
  String get slmSelfCheckTitle => 'SLM セルフチェック';

  @override
  String get slmSelfCheckAndroidHint =>
      'モデルが実際に使われているかを確認するため、実機の Android 端末で一度実行することをおすすめします。';

  @override
  String get slmSelfCheckNonAndroidHint =>
      'これは Android 環境ではないため、セルフチェックは主にフォールバック挙動と設定状態の確認に役立ちます。';

  @override
  String get runSelfCheck => 'セルフチェックを実行';

  @override
  String get noSelfCheckYet =>
      'まだセルフチェックは実行されていません。対象端末で一度実行し、トピック抽出やタイトル/タグ生成がモデルとルールフォールバックのどちらを使っているか確認することをおすすめします。';

  @override
  String completedChipLabel(Object time) {
    return '$time に完了';
  }

  @override
  String get topicExtraction => 'トピック抽出';

  @override
  String get titleAndTagGeneration => 'タイトルとタグの生成';

  @override
  String fallbackDetailLabel(Object latency, Object mode) {
    return 'フォールバック: $mode · ${latency}ms';
  }

  @override
  String tagsDetailLabel(Object tags) {
    return 'タグ: $tags';
  }

  @override
  String get fallbackModel => 'モデル';

  @override
  String get fallbackCache => 'キャッシュ';

  @override
  String get fallbackRules => 'ルール';

  @override
  String get fallbackDisabledUnavailable => '無効/利用不可';

  @override
  String get summaryBannerErrorTitle => 'ジェスチャー動作を直接壊す可能性のある問題が見つかりました';

  @override
  String get summaryBannerErrorDescription => '通常は、権限関連の問題を最初に修正するべきです。';

  @override
  String get summaryBannerWarningTitle => '注意が必要なジェスチャー設定の問題があります';

  @override
  String get summaryBannerWarningDescription =>
      '同期状態やサービス状態がずれていると、ジェスチャーが期待どおりに発火しない場合があります。';

  @override
  String get summaryBannerHealthyTitle => '明らかなジェスチャーの問題は見つかりませんでした';

  @override
  String get summaryBannerHealthyDescription => '権限、サービス状態、ネイティブ同期はいずれも良好です。';

  @override
  String get ocrRecognitionTitlePrefix => 'OCR 認識';

  @override
  String ocrRecognizedCharacters(Object count) {
    return '認識文字数 $count';
  }

  @override
  String ocrFailedMessage(Object error) {
    return 'OCR に失敗しました: $error';
  }

  @override
  String ocrProcessingFailedMessage(Object error) {
    return 'OCR 処理に失敗しました: $error';
  }

  @override
  String get unableToReadImageFile => '画像ファイルを読み取れません';

  @override
  String get previewEnterContent => '候補タイトルとタグをプレビューするには内容を入力してください';

  @override
  String previewGenerationFailed(Object error) {
    return 'プレビュー生成に失敗しました: $error';
  }

  @override
  String get previewApplied => 'プレビューのタイトルとタグをフォームに適用しました';

  @override
  String get contentRequiredMessage => '内容は必須です';

  @override
  String get summaryUpdated => '要約を更新しました';

  @override
  String get duplicateFactMemoryUpdated => '重複する事実記憶を検出し、既存レコードを更新しました';

  @override
  String get savedAndMergedFactMemories => '事実記憶を保存して統合しました';

  @override
  String saveFailedMessage(Object error) {
    return '保存に失敗しました: $error';
  }

  @override
  String get mergeCandidatesFound => '統合候補が見つかりました';

  @override
  String mergeCandidatesFoundDescription(Object title) {
    return '\"$title\" を保存しました。次の統合候補を確認してください:';
  }

  @override
  String get laterLabel => '後で';

  @override
  String get grantAccessLabel => 'アクセスを許可';

  @override
  String get existingFactMemory => '既存の事実記憶';

  @override
  String get newFactMemory => '新しい事実記憶';

  @override
  String get editSummary => '要約を編集';

  @override
  String get saveContent => '内容を保存';

  @override
  String get sharedBadge => '共有';

  @override
  String get remarkLabel => '備考';

  @override
  String get enterTitleHint => 'タイトルを入力';

  @override
  String get contentShareHint => '他アプリから共有された内容はここに自動表示されます';

  @override
  String get remarkHint => '任意の文脈やメモを追加';

  @override
  String get tagsHint => '複数のタグはカンマで区切ってください';

  @override
  String get previewSuggestedTitleTags => '候補タイトルとタグをプレビュー';

  @override
  String get previewSuggestedTitleTagsDescription =>
      '有効にすると、現在の内容から候補を生成しますが、フォームを自動で上書きしません';

  @override
  String get updateSummary => '要約を更新';

  @override
  String get requiredFieldHint => '* は必須項目です';

  @override
  String get saveResultPreview => '保存結果プレビュー';

  @override
  String get previewPrimaryDescription => 'このプレビューは、主に本文内容をもとにタイトルとタグを提案します。';

  @override
  String get suggestedTitle => '提案タイトル';

  @override
  String get suggestedTags => '提案タグ';

  @override
  String get applyToForm => 'フォームに適用';

  @override
  String get generatedByBuiltInModel => 'ネイティブ SLM ランタイムにより生成';

  @override
  String get generatedByLocalRules => 'ローカルルールにより生成';

  @override
  String get pendingSummary => '保留中の要約';

  @override
  String get temporaryTopic => '仮テーマ';

  @override
  String get generalTopic => '一般トピック';

  @override
  String get uncategorized => '未分類';

  @override
  String get unknownModelFormat => '不明なモデル形式';

  @override
  String modelFormatBundledSupported(Object extension) {
    return '同梱の .$extension アセットを検出しました。現在のローカルルールモードはネイティブランタイムなしで継続できます。';
  }

  @override
  String modelFormatUnsupportedForLocalRules(Object extension) {
    return '現在のローカルルールモードでは .$extension アセットはサポートされていません。';
  }

  @override
  String get slmSelfCheckTopicSampleContent =>
      'この診断サンプルは、現在の端末でローカルルールのトピック抽出が正しく動作するかを確認するためのものです。';

  @override
  String get slmSelfCheckMetadataSampleContent =>
      'この診断サンプルは、現在の Local Vault 環境でタイトルとタグの生成が正しく動作するかを確認するためのものです。検索しやすいタイトルと 2 から 4 個のタグを生成してください。';
}
