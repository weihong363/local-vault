// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '本地记忆库';

  @override
  String get home => '首页';

  @override
  String get templates => '模板';

  @override
  String get chooseTemplate => '选择模板';

  @override
  String get addTemplate => '新增模板';

  @override
  String get editTemplate => '编辑模板';

  @override
  String get memory => '记忆';

  @override
  String get myMemories => '我的记忆';

  @override
  String get settings => '设置';

  @override
  String get search => '搜索';

  @override
  String get save => '保存';

  @override
  String get saveSummaryQuickActionTitle => '保存摘要';

  @override
  String get inject => '注入';

  @override
  String get generalSettings => '通用设置';

  @override
  String get themeSettings => '主题设置';

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '浅色模式';

  @override
  String get systemMode => '跟随系统';

  @override
  String get language => '语言';

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
  String get storageSettings => '存储设置';

  @override
  String get storageSpace => '存储空间';

  @override
  String get backupData => '备份数据';

  @override
  String get about => '关于';

  @override
  String get versionInfo => '版本信息';

  @override
  String get feedback => '反馈';

  @override
  String get inDevelopment => '开发中';

  @override
  String get comingSoon => '即将推出';

  @override
  String get title => '标题';

  @override
  String get content => '内容';

  @override
  String get tags => '标签';

  @override
  String get saveToVault => '保存到本地记忆库';

  @override
  String get showFullContent => '显示完整内容';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get savedToVault => '已保存到本地记忆库';

  @override
  String get titleAndContentRequired => '标题和内容不能为空';

  @override
  String get commaSeparatedTagsHint => '标签（用逗号分隔）';

  @override
  String get searchHint => '搜索标题、内容或标签...';

  @override
  String get noSearchResults => '暂无搜索结果';

  @override
  String get noData => '暂无数据';

  @override
  String get noTemplatesYet => '暂无模板';

  @override
  String get noSummariesYet => '暂无记忆';

  @override
  String get navHome => '首页';

  @override
  String get navTemplates => '模板';

  @override
  String get navMemory => '记忆';

  @override
  String get navSettings => '设置';

  @override
  String get refresh => '刷新';

  @override
  String get cancelLabel => '取消';

  @override
  String get continueLabel => '继续';

  @override
  String get deleteLabel => '删除';

  @override
  String get deleteSummary => '删除摘要';

  @override
  String get deleteTemplate => '删除模板';

  @override
  String get shareLabel => '分享';

  @override
  String get restoreLabel => '恢复';

  @override
  String get retryLabel => '重试';

  @override
  String get closeLabel => '关闭';

  @override
  String get workingLabel => '处理中...';

  @override
  String get okLabel => '知道了';

  @override
  String get quickSave => '快捷保存';

  @override
  String get manualInput => '手动输入';

  @override
  String get quickSaveClipboardTip =>
      '提示：快捷保存会优先自动使用剪贴板文本。\n如果剪贴板为空，你也可以手动输入内容。';

  @override
  String get invalidActionType => '无效的操作类型';

  @override
  String get quickActions => '快捷操作';

  @override
  String get enableFloatingGestureLauncher => '启用悬浮手势启动器';

  @override
  String get floatingGestureLauncherDescription => '在其他应用中通过手势快速打开本应用';

  @override
  String get gestureConfiguration => '手势配置';

  @override
  String get gestureConfigurationDescription => '自定义手势行为';

  @override
  String get appAllowlist => '应用白名单';

  @override
  String get appAllowlistDescription => '仅在选定应用内启用手势';

  @override
  String get diagnostics => '诊断信息';

  @override
  String get diagnosticsDescription => '检查手势权限、服务状态和同步状态';

  @override
  String get slmInferenceSettingTitle => '启用 SLM 推理';

  @override
  String get slmInferenceSettingDescription =>
      '该开关保留用于未来兼容扩展。当前版本的标题、标签和主题生成统一使用本地规则。';

  @override
  String get slmInferenceEnabledMessage => 'SLM 偏好已启用。当前版本仍统一使用本地规则生成标题、标签和主题。';

  @override
  String get slmInferenceDisabledMessage =>
      'SLM 偏好已关闭。当前版本仍统一使用本地规则生成标题、标签和主题。';

  @override
  String get titleTagsUseBuiltInModel => '标题和标签已切换为原生 SLM 生成';

  @override
  String get titleTagsUseLocalRuleGenerator => '标题和标签已切换为本地规则生成';

  @override
  String get storageSummaryTapToView => '点击查看存储详情';

  @override
  String get createShareRestoreLocalBackups => '创建、分享并恢复本地备份';

  @override
  String storageSummaryFormat(
      Object bytes, Object summaryCount, Object templateCount) {
    return '$bytes · $summaryCount 条摘要 · $templateCount 个模板';
  }

  @override
  String get backupSummaryNone => '暂无本地备份，点击即可创建';

  @override
  String backupSummaryAvailable(Object backupCount) {
    return '已有 $backupCount 份本地备份';
  }

  @override
  String get architectureChecksDebugOnly => '架构检查 - 仅限调试';

  @override
  String get runArchitectureVerification => '运行架构校验';

  @override
  String get runArchitectureVerificationDescription => '验证新架构是否正常工作';

  @override
  String get runningArchitectureVerification => '正在运行架构校验...';

  @override
  String get architectureVerificationFinished => '架构校验已完成，请查看控制台输出。';

  @override
  String get inspectDatabase => '查看数据库';

  @override
  String get inspectDatabaseDescription => '查看摘要和模板存储中的原始记录';

  @override
  String get notAllPermissionsGranted => '并非所有权限都已授予，手势功能可能无法正常工作。';

  @override
  String get permissionsRequiredTitle => '需要权限';

  @override
  String get permissionsRequiredMessage =>
      '为了让手势唤醒功能正常工作，需要以下权限：\n\n1. 悬浮窗权限：用于在其他应用上层显示手势检测区域\n2. 使用情况访问权限：用于检测当前正在使用的前台应用，以便在白名单应用中显示手势区域\n\n请在接下来的界面中授予这些权限。';

  @override
  String get usageAccessPermissionRequiredTitle => '需要使用情况访问权限';

  @override
  String get usageAccessPermissionRequiredMessage =>
      '当前缺少“使用情况访问权限”。\n\n没有它：\n• 应用无法识别当前正在使用的前台应用\n• 手势唤醒无法在其他应用中正常工作\n\n点击“去授权”打开系统设置，并为本应用启用该权限。';

  @override
  String get floatingWindowServiceStarted => '悬浮窗服务已启动';

  @override
  String get floatingWindowServiceStopped => '悬浮窗服务已停止';

  @override
  String failedToStartMessage(Object error) {
    return '启动失败：$error';
  }

  @override
  String failedToStopMessage(Object error) {
    return '停止失败：$error';
  }

  @override
  String get serviceStarted => '服务已启动';

  @override
  String get floatingWindowTips =>
      '悬浮手势服务已经开始运行。\n\n使用说明：\n1. 请留意屏幕边缘附近的半透明手势区域。\n2. 在这些区域内滑动即可快速启动应用。\n3. 如果没有看到悬浮层，请确认所需权限都已授予。\n\n注意：\n如果切换应用后手势失效，请检查：\n- 该应用是否已加入白名单\n- 是否已授予使用情况访问权限';

  @override
  String get openAllowlist => '打开白名单';

  @override
  String get memoryManagement => '记忆管理';

  @override
  String loadFailedMessage(Object error) {
    return '加载失败：$error';
  }

  @override
  String get loadFailedLabel => '加载失败';

  @override
  String errorWithDetails(Object error) {
    return '错误：$error';
  }

  @override
  String deleteSummaryConfirm(Object title) {
    return '确定删除摘要 \"$title\" 吗？';
  }

  @override
  String deleteTemplateConfirm(Object title) {
    return '确定删除模板 \"$title\" 吗？';
  }

  @override
  String deleteFailedMessage(Object error) {
    return '删除失败：$error';
  }

  @override
  String get templateDeleted => '模板已删除';

  @override
  String get currentView => '当前视图';

  @override
  String get allMemories => '全部记忆';

  @override
  String get searchFilter => '搜索筛选';

  @override
  String itemCountLabel(Object count) {
    return '$count 项';
  }

  @override
  String get notFiltered => '未筛选';

  @override
  String get filtered => '已筛选';

  @override
  String get memoryType => '记忆类型';

  @override
  String metaImportanceLabel(Object percent) {
    return '重要度 $percent';
  }

  @override
  String metaVisitsLabel(Object count) {
    return '访问 $count';
  }

  @override
  String metaUpdatedLabel(Object date) {
    return '更新于 $date';
  }

  @override
  String metaLastOpenedLabel(Object date) {
    return '上次打开 $date';
  }

  @override
  String get editLabel => '编辑';

  @override
  String get promoteToCore => '提升为核心';

  @override
  String get setAsCore => '设为核心';

  @override
  String get setAsCoreMemory => '设为核心记忆';

  @override
  String get mergeSimilar => '合并相似项';

  @override
  String get importanceScore => '重要度分数';

  @override
  String get refreshAndCleanup => '刷新并清理';

  @override
  String get refreshCleanupCompleted => '刷新和清理已完成';

  @override
  String get promoteToCoreMemory => '提升为核心记忆';

  @override
  String promotionDialogBody(Object title) {
    return '\"$title\" 将不再参与常规遗忘衰减，并会作为高优先级长期记忆保留。';
  }

  @override
  String promotionStatsLine(Object accessCount, Object importancePercent) {
    return '当前访问 $accessCount 次 · 重要度 $importancePercent';
  }

  @override
  String get promotionThresholdMet => '这条记忆已经满足自动提升阈值。';

  @override
  String get promotionThresholdNotMet => '这条记忆暂未达到自动提升阈值，但你仍然可以手动将其固定为核心记忆。';

  @override
  String promotionThresholdLine(
      Object accessCountThreshold, Object importanceThreshold) {
    return '当前自动阈值：访问次数 >= $accessCountThreshold 或 重要度 >= $importanceThreshold';
  }

  @override
  String get generatingPromotionReason => '正在生成提升理由...';

  @override
  String get promotionReason => '提升理由';

  @override
  String get defaultPromotionReason => '这条记忆已经具备持续价值，适合作为长期核心记忆保留。';

  @override
  String get upgradeReasonHighAccess => '这条记忆访问频繁，已经展现出稳定的长期价值，适合提升为核心记忆。';

  @override
  String get upgradeReasonHighImportance => '这条记忆的重要度较高，值得作为长期核心记忆保留。';

  @override
  String get confirmPromotion => '确认提升';

  @override
  String get confirmSetAsCore => '确认设为核心';

  @override
  String get promotedToCoreMemory => '已提升为核心记忆';

  @override
  String get setAsCoreSuccess => '已设为核心记忆';

  @override
  String get viewCore => '查看核心记忆';

  @override
  String get noSimilarMemoriesFound => '未找到相似记忆';

  @override
  String get currentFactMemory => '当前事实记忆';

  @override
  String get candidateFactMemory => '候选事实记忆';

  @override
  String get mergeCompleted => '合并完成';

  @override
  String get chooseMemoryToCompare => '选择一条记忆进行比对';

  @override
  String mergeCandidateCount(Object title, Object count) {
    return '\"$title\" 有 $count 个可合并候选';
  }

  @override
  String similarityWithContent(Object similarity, Object content) {
    return '相似度 $similarity · $content';
  }

  @override
  String get deleteMemory => '删除记忆';

  @override
  String deleteMemoryConfirm(Object title) {
    return '确定删除 \"$title\" 吗？';
  }

  @override
  String get deletedLabel => '已删除';

  @override
  String get factMemories => '事实记忆';

  @override
  String get coreMemories => '核心记忆';

  @override
  String get sessionMemories => '会话记忆';

  @override
  String get factMemoryLabel => '事实';

  @override
  String get coreMemoryLabel => '核心';

  @override
  String get sessionMemoryLabel => '会话';

  @override
  String get factMemoryDescription => '适合长期保留的普通事实和稳定信息。';

  @override
  String get coreMemoryDescription => '最高优先级的长期记忆，不参与常规遗忘衰减。';

  @override
  String get sessionMemoryDescription => '来自近期交互的临时上下文，用于短期整理和衔接。';

  @override
  String relativeMinutesAgo(Object count) {
    return '$count 分钟前';
  }

  @override
  String relativeHoursAgo(Object count) {
    return '$count 小时前';
  }

  @override
  String relativeDaysAgo(Object count) {
    return '$count 天前';
  }

  @override
  String get noMatchingMemories => '没有匹配的记忆';

  @override
  String get noFactMemoriesYet => '暂无事实记忆';

  @override
  String get noCoreMemoriesYet => '暂无核心记忆';

  @override
  String get noSessionMemoriesYet => '暂无会话记忆';

  @override
  String get mergeFactMemories => '合并事实记忆';

  @override
  String get mergeFactMemoriesDescription => '请比较两个版本，并选择最终保留的标题、内容和标签。';

  @override
  String similarityPercent(Object percent) {
    return '相似度 $percent';
  }

  @override
  String get mergedPreview => '合并预览';

  @override
  String get noTags => '暂无标签';

  @override
  String get notNow => '暂不处理';

  @override
  String get mergingLabel => '合并中...';

  @override
  String get confirmMerge => '确认合并';

  @override
  String get keepOriginal => '保留原版';

  @override
  String get keepNew => '保留新版';

  @override
  String get smartMerge => '智能合并';

  @override
  String get emptyValue => '空';

  @override
  String get candidateMemory => '候选记忆';

  @override
  String mergeFailedMessage(Object error) {
    return '合并失败：$error';
  }

  @override
  String get clearModelCache => '清理模型缓存';

  @override
  String get clearModelCacheMessage => '这会删除本地模型推理缓存文件，但会保留摘要、模板以及模型文件本身。';

  @override
  String get noModelCacheFilesToClear => '没有可清理的模型缓存文件';

  @override
  String clearedModelCacheResult(Object count, Object bytes) {
    return '已清理 $count 个缓存文件，释放 $bytes';
  }

  @override
  String get clearBackupFiles => '清理备份文件';

  @override
  String get clearBackupFilesMessage => '这会删除本地生成的备份文件，但不会影响数据库中的当前摘要和模板数据。';

  @override
  String get noBackupFilesToClear => '没有可清理的备份文件';

  @override
  String deletedBackupFilesResult(Object count, Object bytes) {
    return '已删除 $count 个备份文件，释放 $bytes';
  }

  @override
  String failedToReadStorageUsage(Object error) {
    return '读取存储占用失败：$error';
  }

  @override
  String get totalStorageUsed => '总存储占用';

  @override
  String storageOverviewCounts(
      Object summaryCount, Object templateCount, Object backupCount) {
    return '$summaryCount 条摘要 · $templateCount 个模板 · $backupCount 份备份';
  }

  @override
  String get summaryDatabase => '摘要数据库';

  @override
  String summaryDatabaseSubtitle(Object count) {
    return '$count 条摘要';
  }

  @override
  String get templateDatabase => '模板数据库';

  @override
  String templateDatabaseSubtitle(Object count) {
    return '$count 个模板';
  }

  @override
  String get backupFiles => '备份文件';

  @override
  String backupFilesSubtitle(Object count) {
    return '$count 份备份';
  }

  @override
  String get modelFile => '模型文件';

  @override
  String get bundledModelFootprint => '内置模型占用';

  @override
  String get modelCache => '模型缓存';

  @override
  String get inferenceCacheAndIntermediateFiles => '推理缓存和中间文件';

  @override
  String get cleanupTools => '清理工具';

  @override
  String get clearLocalBackupFiles => '清理本地备份文件';

  @override
  String backupCreatedMessage(Object fileName) {
    return '备份已创建：$fileName';
  }

  @override
  String failedToCreateBackupMessage(Object error) {
    return '创建备份失败：$error';
  }

  @override
  String importFailedMessage(Object error) {
    return '导入失败：$error';
  }

  @override
  String get importFailedUnableReadSelectedFile => '导入失败：无法读取所选文件';

  @override
  String get unknownValue => '未知';

  @override
  String get importBackup => '导入备份';

  @override
  String backupImportPreviewMessage(
      Object summaryCount, Object templateCount, Object exportedAt) {
    return '该备份包含 $summaryCount 条摘要和 $templateCount 个模板。\n导出时间：$exportedAt\n\n导入后会覆盖当前的摘要和模板数据，是否继续？';
  }

  @override
  String importFinishedMessage(Object summaryCount, Object templateCount) {
    return '导入完成：$summaryCount 条摘要，$templateCount 个模板';
  }

  @override
  String get invalidBackupFileFormat => '导入失败：备份文件格式无效';

  @override
  String get restoreBackupMessage => '恢复后会覆盖当前的摘要和模板数据，是否继续？';

  @override
  String restoreFinishedMessage(Object summaryCount, Object templateCount) {
    return '恢复完成：$summaryCount 条摘要，$templateCount 个模板';
  }

  @override
  String restoreFailedMessage(Object error) {
    return '恢复失败：$error';
  }

  @override
  String deleteBackupConfirmMessage(Object fileName) {
    return '确定删除备份 $fileName 吗？';
  }

  @override
  String get backupDeleted => '备份已删除';

  @override
  String failedToLoadBackupList(Object error) {
    return '加载备份列表失败：$error';
  }

  @override
  String get noLocalBackupFilesYet => '暂无本地备份文件';

  @override
  String get localBackups => '本地备份';

  @override
  String backupFilesAvailable(Object count) {
    return '共有 $count 份备份文件';
  }

  @override
  String get backupOverviewDescription =>
      '创建备份会生成一个 JSON 文件并打开分享面板。你也可以从应用外部导入备份文件。';

  @override
  String get createAndShareBackup => '创建并分享备份';

  @override
  String get importBackupData => '导入备份数据';

  @override
  String get shareBackupText => '本地记忆库备份';

  @override
  String get shareBackupSubject => '本地记忆库备份';

  @override
  String get confirmLabel => '确认';

  @override
  String get clearLabel => '清空';

  @override
  String get runningLabel => '运行中...';

  @override
  String get unknownError => '未知错误';

  @override
  String get statusEnabled => '已启用';

  @override
  String get statusDisabled => '已禁用';

  @override
  String get statusGranted => '已授予';

  @override
  String get statusNotGranted => '未授予';

  @override
  String get statusRunning => '运行中';

  @override
  String get statusStopped => '已停止';

  @override
  String get statusUnavailable => '不可用';

  @override
  String get statusAvailable => '可用';

  @override
  String get statusMissing => '缺失';

  @override
  String get statusReady => '就绪';

  @override
  String get statusCompatible => '兼容';

  @override
  String get statusIncompatible => '不兼容';

  @override
  String get statusInitialized => '已初始化';

  @override
  String get statusNotInitialized => '未初始化';

  @override
  String get statusDetected => '已检测到';

  @override
  String get statusNotDetected => '未检测到';

  @override
  String get statusModelUsed => '已使用模型';

  @override
  String get statusModelNotUsed => '未使用模型';

  @override
  String get statusInitializationComplete => '初始化完成';

  @override
  String get statusInitializationIncomplete => '初始化未完成';

  @override
  String get gestureConfigurationSaved => '手势配置已保存';

  @override
  String gestureConfigurationLoadFailed(Object error) {
    return '加载手势配置失败：$error';
  }

  @override
  String get resetToDefaults => '恢复默认';

  @override
  String get resetGesturesToDefaultsMessage => '要将所有手势恢复为默认配置吗？';

  @override
  String get restoredDefaultSettings => '已恢复默认设置';

  @override
  String get gestureShareOnly => '仅分享';

  @override
  String get gestureActionOpenTemplates => '打开提示模板';

  @override
  String get gestureActionSaveSummary => '从分享内容中保存摘要';

  @override
  String get gestureActionOpenSavedContext => '打开已保存内容';

  @override
  String get gestureDoubleTap => '双击';

  @override
  String get gestureTripleTap => '三击';

  @override
  String get triggerAction => '触发动作';

  @override
  String get alreadyUsedByAnotherGesture => '已被其他手势占用';

  @override
  String get searchAppsHint => '搜索应用...';

  @override
  String appWhitelistLoadFailed(Object error) {
    return '加载失败：$error';
  }

  @override
  String selectedAppsCount(Object count) {
    return '已选择 $count 个应用';
  }

  @override
  String get clearAllowlistTooltip => '清空白名单';

  @override
  String get gesturesActiveInAllApps => '手势在所有应用中都处于激活状态';

  @override
  String get filterAll => '全部';

  @override
  String get filterSelected => '已选择';

  @override
  String get filterUnselected => '未选择';

  @override
  String get noAppsFound => '未找到应用';

  @override
  String get noMatchingAppsFound => '未找到匹配的应用';

  @override
  String get noSelectedAppsYet => '还没有已选择的应用';

  @override
  String get noUnselectedApps => '没有未选择的应用';

  @override
  String get clearAllowlistTitle => '清空白名单';

  @override
  String get clearAllowlistMessage => '要清空应用白名单吗？清空后手势会在所有应用中激活。';

  @override
  String get allowlistCleared => '白名单已清空';

  @override
  String get databaseInspector => '数据库查看器';

  @override
  String failedToOpenDatabase(Object error) {
    return '打开数据库失败：$error';
  }

  @override
  String get summariesTab => '摘要';

  @override
  String get templatesTab => '模板';

  @override
  String get noSummaryRecordsInBox => '此数据盒中没有摘要记录';

  @override
  String get noTemplateRecordsInBox => '此数据盒中没有模板记录';

  @override
  String recordsWithIssues(Object count) {
    return '有问题的记录：$count';
  }

  @override
  String legacyTemplateTypes(Object count) {
    return '旧模板类型记录：$count';
  }

  @override
  String defaultTemplatesCount(Object count) {
    return '默认模板：$count';
  }

  @override
  String boxMetricLabel(Object boxName) {
    return '数据盒：$boxName';
  }

  @override
  String recordsMetricLabel(Object count) {
    return '记录数：$count';
  }

  @override
  String keyMetricLabel(Object key) {
    return '键：$key';
  }

  @override
  String get noObviousIssuesDetected => '未发现明显问题';

  @override
  String issuesMetricLabel(Object count) {
    return '问题数：$count';
  }

  @override
  String get copyJson => '复制 JSON';

  @override
  String get recordNotMapCorrupted => '记录不是 Map，可能已损坏';

  @override
  String get unparseableSummaryRecord => '无法解析的摘要记录';

  @override
  String get unparseableTemplateRecord => '无法解析的模板记录';

  @override
  String rawTypeLabel(Object type) {
    return '原始类型：$type';
  }

  @override
  String get legacyTemplateRecordDetected => '检测到旧版模板类型记录，将按事实记忆读取';

  @override
  String get missingId => '缺少 id';

  @override
  String get titleIsEmpty => '标题为空';

  @override
  String get contentIsEmpty => '内容为空';

  @override
  String get accessCountInvalid => 'accessCount 不是有效数字';

  @override
  String get accessCountBelowZero => 'accessCount 小于 0';

  @override
  String get createdAtCouldNotBeParsed => 'createdAt 无法解析';

  @override
  String summaryDeserializationFailed(Object error) {
    return 'SummaryEntity 反序列化失败：$error';
  }

  @override
  String templateDeserializationFailed(Object error) {
    return 'TemplateEntity 反序列化失败：$error';
  }

  @override
  String get unknownTime => '未知时间';

  @override
  String get untitledSummary => '（未命名摘要）';

  @override
  String get untitledTemplate => '（未命名模板）';

  @override
  String summaryRecordSubtitle(
      Object accessCount, Object createdAt, Object type) {
    return '类型：$type  访问：$accessCount  创建于：$createdAt';
  }

  @override
  String templateRecordSubtitle(Object createdAt, Object templateKind) {
    return '$templateKind  创建于：$createdAt';
  }

  @override
  String get defaultTemplateLabel => '默认模板';

  @override
  String get customTemplateLabel => '自定义模板';

  @override
  String get refreshDiagnostics => '刷新诊断信息';

  @override
  String get failedToLoadDiagnostics => '加载诊断信息失败';

  @override
  String get gestureDiagnosticsTitle => '手势诊断';

  @override
  String get gestureDiagnosticsDescription => '下拉即可刷新权限、服务和原生同步状态。';

  @override
  String get slmDiagnosticsTitle => 'SLM 诊断';

  @override
  String get slmDiagnosticsDescription => '检查当前模型、缓存和初始化状态，并运行一次示例自检推理。';

  @override
  String get allowlistedAppsLabel => '白名单应用';

  @override
  String get floatingGestureLauncherTitle => '悬浮手势启动器';

  @override
  String get floatingGestureLauncherEnabledDescription => '设置中的主手势开关已启用。';

  @override
  String get floatingGestureLauncherDisabledDescription =>
      '当主开关关闭时，双击和三击手势不会触发。';

  @override
  String get overlayPermissionTitle => '悬浮窗权限';

  @override
  String get overlayPermissionGrantedDescription => '系统允许应用显示在其他应用之上。';

  @override
  String get overlayPermissionDeniedDescription => '没有此权限时，悬浮层服务无法正常启动。';

  @override
  String get usageAccessPermissionTitle => '使用情况访问权限';

  @override
  String get usageAccessGrantedDescription => '应用可以识别当前前台应用，以执行白名单检查。';

  @override
  String get usageAccessDeniedDescription => '没有此权限时，白名单匹配和跨应用手势触发都会失败。';

  @override
  String get floatingServiceStatusTitle => '悬浮服务状态';

  @override
  String get floatingServiceRunningDescription => '原生悬浮服务当前正在监听手势。';

  @override
  String get floatingServiceEnabledButStoppedDescription =>
      '主开关已启用，但原生悬浮服务当前没有运行。';

  @override
  String get floatingServiceStoppedDescription => '当主开关关闭时，服务通常会保持停止状态。';

  @override
  String get floatingServiceUnavailableDescription => '无法读取原生服务状态。';

  @override
  String get doubleTapActionSyncTitle => '双击动作同步';

  @override
  String get doubleTapActionSyncedDescription => '双击动作已经同步到原生层。';

  @override
  String get doubleTapActionOutOfSyncDescription =>
      '当前双击动作与原生层不一致，建议重新保存一次手势设置。';

  @override
  String get tripleTapActionSyncTitle => '三击动作同步';

  @override
  String get tripleTapActionSyncedDescription => '三击动作已经同步到原生层。';

  @override
  String get tripleTapActionOutOfSyncDescription =>
      '当前三击动作与原生层不一致，建议重新保存一次手势设置。';

  @override
  String get allowlistScopeTitle => '白名单范围';

  @override
  String get allAppsValue => '所有应用';

  @override
  String restrictedAppsValue(Object count) {
    return '限制为 $count 个应用';
  }

  @override
  String get allowlistScopeAllAppsDescription => '手势当前会尝试在所有前台应用中生效。';

  @override
  String get allowlistScopeRestrictedDescription => '当前只有白名单中的前台应用会响应手势。';

  @override
  String get allowlistNativeSyncTitle => '白名单原生同步';

  @override
  String flutterNativeCountLabel(Object flutterCount, Object nativeCount) {
    return 'Flutter：$flutterCount / 原生：$nativeCount';
  }

  @override
  String actionSyncValue(Object flutterAction, Object nativeAction) {
    return 'Flutter：$flutterAction / 原生：$nativeAction';
  }

  @override
  String get allowlistNativeUnreadableDescription => '无法读取原生白名单。';

  @override
  String get allowlistNativeSyncedDescription => '白名单已经同步到原生层。';

  @override
  String get allowlistNativeOutOfSyncDescription =>
      'Flutter 和原生白名单不同步。重新打开白名单页面可以触发一次新的同步。';

  @override
  String get runtimeEnvironmentTitle => '运行环境';

  @override
  String get environmentAndroid => 'Android';

  @override
  String get environmentWeb => 'Web';

  @override
  String get environmentDesktop => '桌面';

  @override
  String get runtimeEnvironmentAndroidDescription => '该环境满足尝试端侧 SLM 推理的基础条件。';

  @override
  String get runtimeEnvironmentNonAndroidDescription =>
      '这不是 Android 设备环境。仍可运行自检，但通常会走规则回退路径。';

  @override
  String get experimentalNativeInferenceFlagTitle => '实验性原生推理开关';

  @override
  String get experimentalNativeInferenceEnabledDescription =>
      '当前版本默认使用纯规则引擎；该状态位仅为未来扩展保留。';

  @override
  String get experimentalNativeInferenceDisabledDescription =>
      '当前版本已切换为纯规则引擎，原生推理链路已移除，因此 SLM 会保持在本地规则模式。';

  @override
  String get nativeInferenceSupportTitle => '原生推理支持';

  @override
  String get nativeInferenceSupportAvailableDescription =>
      '当前 SLM 推理路径所需的原生符号和运行时条件看起来都已满足。';

  @override
  String get nativeInferenceSupportUnavailableDescription =>
      '当前版本不再提供原生推理能力，标题、标签和主题生成统一使用本地规则。';

  @override
  String get nativeSymbolDetectionTitle => '原生符号检测';

  @override
  String get nativeSymbolDetectedDescription =>
      '已检测到所需的 LlmInferenceEngine 符号。';

  @override
  String get nativeSymbolMissingDescription => '缺少关键原生符号时，模型推理会立即回退到规则模式。';

  @override
  String get bundledModelFormatTitle => '内置模型格式';

  @override
  String get slmInitializationStateTitle => 'SLM 初始化状态';

  @override
  String get slmInitializedDescription => '服务已经初始化，后续自检会复用当前状态。';

  @override
  String get slmNotInitializedDescription => '尚未触发初始化。运行自检时会自动尝试初始化。';

  @override
  String get modelAvailabilityTitle => '模型可用性';

  @override
  String get modelAvailableNow => '当前可用';

  @override
  String get usingRuleFallback => '使用规则回退';

  @override
  String get modelAvailabilityAvailableDescription => '当前设备已经可以直接使用模型推理。';

  @override
  String get modelAvailabilityIncompatibleDescription =>
      '当前模型文件格式与当前 Android 原生 SLM 运行时不兼容，因此在替换内置模型前，运行时会保持规则回退路径。';

  @override
  String get modelAvailabilityFallbackDescription =>
      '当前版本的标题、标签和主题生成统一使用本地规则，不依赖设备侧模型推理。';

  @override
  String modelFileMissingDescription(Object path) {
    return '当前文件路径：$path。如果文件缺失，运行时会自动回退到规则模式。';
  }

  @override
  String get modelCacheRuntimeParametersTitle => '模型缓存与运行参数';

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
    return '$size · 最大缓存条目 $count';
  }

  @override
  String slmSelfCheckFailed(Object error) {
    return 'SLM 自检失败：$error';
  }

  @override
  String get slmSelfCheckTitle => 'SLM 自检';

  @override
  String get slmSelfCheckAndroidHint =>
      '最好在真实 Android 设备上至少运行一次，以确认当前是否真的使用到了模型。';

  @override
  String get slmSelfCheckNonAndroidHint =>
      '这不是 Android 设备环境，因此自检主要用于验证回退行为和配置状态。';

  @override
  String get runSelfCheck => '运行自检';

  @override
  String get noSelfCheckYet =>
      '尚未运行过自检。建议在目标设备上运行一次，以验证主题提取和标题/标签生成是否使用模型或规则回退。';

  @override
  String completedChipLabel(Object time) {
    return '完成于 $time';
  }

  @override
  String get topicExtraction => '主题提取';

  @override
  String get titleAndTagGeneration => '标题与标签生成';

  @override
  String fallbackDetailLabel(Object latency, Object mode) {
    return '回退：$mode · ${latency}ms';
  }

  @override
  String tagsDetailLabel(Object tags) {
    return '标签：$tags';
  }

  @override
  String get fallbackModel => '模型';

  @override
  String get fallbackCache => '缓存';

  @override
  String get fallbackRules => '规则';

  @override
  String get fallbackDisabledUnavailable => '禁用/不可用';

  @override
  String get summaryBannerErrorTitle => '发现了会直接影响手势行为的问题';

  @override
  String get summaryBannerErrorDescription => '通常应该优先修复权限相关问题。';

  @override
  String get summaryBannerWarningTitle => '有一些手势配置问题需要关注';

  @override
  String get summaryBannerWarningDescription => '当同步状态或服务状态漂移时，手势可能无法按预期触发。';

  @override
  String get summaryBannerHealthyTitle => '未发现明显的手势问题';

  @override
  String get summaryBannerHealthyDescription => '权限、服务状态和原生同步看起来都很健康。';

  @override
  String get ocrRecognitionTitlePrefix => 'OCR 识别';

  @override
  String ocrRecognizedCharacters(Object count) {
    return '已识别 $count 个字符';
  }

  @override
  String ocrFailedMessage(Object error) {
    return 'OCR 失败：$error';
  }

  @override
  String ocrProcessingFailedMessage(Object error) {
    return 'OCR 处理失败：$error';
  }

  @override
  String get unableToReadImageFile => '无法读取图片文件';

  @override
  String get previewEnterContent => '请输入内容以预览建议标题和标签';

  @override
  String previewGenerationFailed(Object error) {
    return '预览生成失败：$error';
  }

  @override
  String get previewApplied => '已将预览标题和标签应用到表单';

  @override
  String get contentRequiredMessage => '内容不能为空';

  @override
  String get summaryUpdated => '摘要已更新';

  @override
  String get duplicateFactMemoryUpdated => '检测到重复事实记忆，已更新现有记录';

  @override
  String get savedAndMergedFactMemories => '已保存并合并事实记忆';

  @override
  String saveFailedMessage(Object error) {
    return '保存失败：$error';
  }

  @override
  String get mergeCandidatesFound => '发现可合并候选';

  @override
  String mergeCandidatesFoundDescription(Object title) {
    return '\"$title\" 已保存。请查看这些可合并候选：';
  }

  @override
  String get laterLabel => '稍后处理';

  @override
  String get grantAccessLabel => '去授权';

  @override
  String get existingFactMemory => '已有事实记忆';

  @override
  String get newFactMemory => '新事实记忆';

  @override
  String get editSummary => '编辑摘要';

  @override
  String get saveContent => '保存内容';

  @override
  String get sharedBadge => '已分享';

  @override
  String get remarkLabel => '备注';

  @override
  String get enterTitleHint => '输入标题';

  @override
  String get contentShareHint => '来自其他应用的分享内容会自动出现在这里';

  @override
  String get remarkHint => '添加可选上下文或备注';

  @override
  String get tagsHint => '多个标签请用逗号分隔';

  @override
  String get previewSuggestedTitleTags => '预览建议标题和标签';

  @override
  String get previewSuggestedTitleTagsDescription =>
      '开启后，会根据当前内容生成建议，但不会自动覆盖你的表单';

  @override
  String get updateSummary => '更新摘要';

  @override
  String get requiredFieldHint => '* 表示必填项';

  @override
  String get saveResultPreview => '保存结果预览';

  @override
  String get previewPrimaryDescription => '该预览会主要根据正文内容推荐标题和标签。';

  @override
  String get suggestedTitle => '建议标题';

  @override
  String get suggestedTags => '建议标签';

  @override
  String get applyToForm => '应用到表单';

  @override
  String get generatedByBuiltInModel => '由原生 SLM 生成';

  @override
  String get generatedByLocalRules => '由本地规则生成';

  @override
  String get pendingSummary => '待整理摘要';

  @override
  String get temporaryTopic => '临时主题';

  @override
  String get generalTopic => '通用主题';

  @override
  String get uncategorized => '未分类';

  @override
  String get unknownModelFormat => '未知模型格式';

  @override
  String modelFormatBundledSupported(Object extension) {
    return '检测到内置的 .$extension 资源文件。当前规则模式无需原生运行时也可继续运行。';
  }

  @override
  String modelFormatUnsupportedForLocalRules(Object extension) {
    return '当前本地规则模式不支持 .$extension 资源文件。';
  }

  @override
  String get slmSelfCheckTopicSampleContent =>
      '这是一个诊断样本，用于验证当前设备上的本地规则主题提取是否正常工作。';

  @override
  String get slmSelfCheckMetadataSampleContent =>
      '这是一个诊断样本，用于验证当前 Local Vault 环境下的标题与标签生成是否正常工作。请生成一个便于检索的标题和 2 到 4 个标签。';
}
