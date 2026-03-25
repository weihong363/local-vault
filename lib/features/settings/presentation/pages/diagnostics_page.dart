import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/services/gesture_diagnostics_service.dart';
import 'package:local_vault/core/services/memory_slm_diagnostics_service.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/services/storage_management_service.dart';
import 'package:local_vault/features/app_whitelist/domain/providers/app_whitelist_provider.dart';
import 'package:local_vault/features/app_whitelist/models/app_info.dart';
import 'package:local_vault/features/gesture_config/domain/providers/gesture_config_provider.dart';
import 'package:local_vault/features/gesture_config/models/gesture_config.dart';
import 'package:local_vault/l10n/app_localizations.dart';

class DiagnosticsPage extends ConsumerStatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  ConsumerState<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends ConsumerState<DiagnosticsPage> {
  late final GestureDiagnosticsService _diagnosticsService;
  late final MemorySlmDiagnosticsService _slmDiagnosticsService;
  GestureDiagnosticsSnapshot? _snapshot;
  MemorySlmDiagnosticsSnapshot? _slmSnapshot;
  MemorySlmSelfCheckResult? _slmSelfCheckResult;
  Object? _error;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isRunningSlmSelfCheck = false;

  @override
  void initState() {
    super.initState();
    _diagnosticsService = sl<GestureDiagnosticsService>();
    _slmDiagnosticsService = sl<MemorySlmDiagnosticsService>();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    if (!mounted) return;

    setState(() {
      _error = null;
      if (_snapshot == null) {
        _isLoading = true;
      } else {
        _isRefreshing = true;
      }
    });

    try {
      final snapshot = await _diagnosticsService.collectSnapshot();
      final slmSnapshot = await _slmDiagnosticsService.collectSnapshot();
      if (!mounted) return;

      setState(() {
        _snapshot = snapshot;
        _slmSnapshot = slmSnapshot;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error;
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final gestureConfigs = ref.watch(gestureConfigProvider);
    final whitelist = ref.watch(appWhitelistProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.diagnostics),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _loadDiagnostics,
            tooltip: loc.refreshDiagnostics,
          ),
        ],
      ),
      body: _buildBody(
        context,
        gestureConfigs: gestureConfigs,
        whitelist: whitelist,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required AsyncValue<List<GestureConfig>> gestureConfigs,
    required AsyncValue<List<AppInfo>> whitelist,
  }) {
    final loc = AppLocalizations.of(context)!;
    if (_isLoading ||
        (gestureConfigs.isLoading && !gestureConfigs.hasValue) ||
        (whitelist.isLoading && !whitelist.hasValue)) {
      return const Center(child: CircularProgressIndicator());
    }

    final providerError = gestureConfigs.whenOrNull(
          error: (error, _) => error,
        ) ??
        whitelist.whenOrNull(
          error: (error, _) => error,
        );

    if (_error != null ||
        providerError != null ||
        _snapshot == null ||
        _slmSnapshot == null) {
      final message = _error ?? providerError ?? loc.failedToLoadDiagnostics;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                '$message',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadDiagnostics,
                child: Text(loc.retryLabel),
              ),
            ],
          ),
        ),
      );
    }

    final configs = gestureConfigs.value ?? const <GestureConfig>[];
    final whitelistApps = whitelist.value ?? const <AppInfo>[];
    final snapshot = _snapshot!;
    final items = _buildGestureDiagnosticItems(
      context,
      snapshot: snapshot,
      configs: configs,
      whitelistApps: whitelistApps,
    );
    final slmSnapshot = _slmSnapshot!;
    final slmItems = _buildSlmDiagnosticItems(
      context,
      snapshot: slmSnapshot,
    );

    return RefreshIndicator(
      onRefresh: _loadDiagnostics,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _DiagnosticSummaryBanner(items: items),
          const SizedBox(height: 16),
          Text(
            loc.gestureDiagnosticsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.gestureDiagnosticsDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DiagnosticItemCard(item: item),
              )),
          const SizedBox(height: 12),
          Text(
            loc.slmDiagnosticsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.slmDiagnosticsDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          ...slmItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DiagnosticItemCard(item: item),
              )),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSlmSelfCheckCard(context, slmSnapshot),
          ),
          if (whitelistApps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              loc.allowlistedAppsLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: whitelistApps
                  .map(
                    (app) => Chip(
                      label: Text(app.appName),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  List<_DiagnosticItem> _buildGestureDiagnosticItems(
    BuildContext context, {
    required GestureDiagnosticsSnapshot snapshot,
    required List<GestureConfig> configs,
    required List<AppInfo> whitelistApps,
  }) {
    final loc = AppLocalizations.of(context)!;
    final flutterTap2Action = _findAction(configs, GestureType.tap2);
    final flutterTap3Action = _findAction(configs, GestureType.tap3);
    final nativeTap2Action = _actionFromIndex(snapshot.nativeTap2ActionIndex);
    final nativeTap3Action = _actionFromIndex(snapshot.nativeTap3ActionIndex);
    final nativeWhitelistPackages = snapshot.nativeWhitelistPackages;
    final whitelistInFlutter =
        whitelistApps.map((app) => app.packageName).toSet();
    final whitelistInNative = nativeWhitelistPackages?.toSet();
    final whitelistSynced = whitelistInNative != null &&
        whitelistInNative.length == whitelistInFlutter.length &&
        whitelistInNative.containsAll(whitelistInFlutter);

    return [
      _DiagnosticItem(
        title: loc.floatingGestureLauncherTitle,
        value: snapshot.floatingWindowEnabled
            ? loc.statusEnabled
            : loc.statusDisabled,
        description: snapshot.floatingWindowEnabled
            ? loc.floatingGestureLauncherEnabledDescription
            : loc.floatingGestureLauncherDisabledDescription,
        tone: snapshot.floatingWindowEnabled
            ? _DiagnosticTone.healthy
            : _DiagnosticTone.warning,
      ),
      _DiagnosticItem(
        title: loc.overlayPermissionTitle,
        value: snapshot.overlayPermissionGranted
            ? loc.statusGranted
            : loc.statusNotGranted,
        description: snapshot.overlayPermissionGranted
            ? loc.overlayPermissionGrantedDescription
            : loc.overlayPermissionDeniedDescription,
        tone: snapshot.overlayPermissionGranted
            ? _DiagnosticTone.healthy
            : _DiagnosticTone.error,
      ),
      _DiagnosticItem(
        title: loc.usageAccessPermissionTitle,
        value: snapshot.usageStatsPermissionGranted
            ? loc.statusGranted
            : loc.statusNotGranted,
        description: snapshot.usageStatsPermissionGranted
            ? loc.usageAccessGrantedDescription
            : loc.usageAccessDeniedDescription,
        tone: snapshot.usageStatsPermissionGranted
            ? _DiagnosticTone.healthy
            : _DiagnosticTone.error,
      ),
      _DiagnosticItem(
        title: loc.floatingServiceStatusTitle,
        value: switch (snapshot.floatingServiceRunning) {
          true => loc.statusRunning,
          false => loc.statusStopped,
          null => loc.statusUnavailable,
        },
        description: switch (snapshot.floatingServiceRunning) {
          true => loc.floatingServiceRunningDescription,
          false when snapshot.floatingWindowEnabled =>
            loc.floatingServiceEnabledButStoppedDescription,
          false => loc.floatingServiceStoppedDescription,
          null => loc.floatingServiceUnavailableDescription,
        },
        tone: switch (snapshot.floatingServiceRunning) {
          true => _DiagnosticTone.healthy,
          false when snapshot.floatingWindowEnabled => _DiagnosticTone.warning,
          false => _DiagnosticTone.info,
          null => _DiagnosticTone.info,
        },
      ),
      _DiagnosticItem(
        title: loc.doubleTapActionSyncTitle,
        value: loc.actionSyncValue(
          _actionLabel(flutterTap2Action),
          _actionLabel(nativeTap2Action),
        ),
        description: flutterTap2Action == nativeTap2Action
            ? loc.doubleTapActionSyncedDescription
            : loc.doubleTapActionOutOfSyncDescription,
        tone: flutterTap2Action == nativeTap2Action
            ? _DiagnosticTone.healthy
            : _DiagnosticTone.warning,
      ),
      _DiagnosticItem(
        title: loc.tripleTapActionSyncTitle,
        value: loc.actionSyncValue(
          _actionLabel(flutterTap3Action),
          _actionLabel(nativeTap3Action),
        ),
        description: flutterTap3Action == nativeTap3Action
            ? loc.tripleTapActionSyncedDescription
            : loc.tripleTapActionOutOfSyncDescription,
        tone: flutterTap3Action == nativeTap3Action
            ? _DiagnosticTone.healthy
            : _DiagnosticTone.warning,
      ),
      _DiagnosticItem(
        title: loc.allowlistScopeTitle,
        value: whitelistApps.isEmpty
            ? loc.allAppsValue
            : loc.restrictedAppsValue('${whitelistApps.length}'),
        description: whitelistApps.isEmpty
            ? loc.allowlistScopeAllAppsDescription
            : loc.allowlistScopeRestrictedDescription,
        tone: whitelistApps.isEmpty
            ? _DiagnosticTone.info
            : _DiagnosticTone.healthy,
      ),
      _DiagnosticItem(
        title: loc.allowlistNativeSyncTitle,
        value: loc.flutterNativeCountLabel(
          '${whitelistApps.length}',
          '${nativeWhitelistPackages?.length ?? '-'}',
        ),
        description: nativeWhitelistPackages == null
            ? loc.allowlistNativeUnreadableDescription
            : whitelistSynced
                ? loc.allowlistNativeSyncedDescription
                : loc.allowlistNativeOutOfSyncDescription,
        tone: nativeWhitelistPackages == null
            ? _DiagnosticTone.info
            : whitelistSynced
                ? _DiagnosticTone.healthy
                : _DiagnosticTone.warning,
      ),
    ];
  }

  List<_DiagnosticItem> _buildSlmDiagnosticItems(
    BuildContext context, {
    required MemorySlmDiagnosticsSnapshot snapshot,
  }) {
    final loc = AppLocalizations.of(context)!;
    final environmentLabel = snapshot.runningOnAndroid
        ? loc.environmentAndroid
        : snapshot.runningOnWeb
            ? loc.environmentWeb
            : loc.environmentDesktop;
    final modelFileValue = loc.statusAndSizeLabel(
      snapshot.modelFileExists ? loc.statusReady : loc.statusMissing,
      StorageManagementService.formatBytes(snapshot.modelBytes),
    );
    final cacheValue = loc.cacheSummaryLabel(
      StorageManagementService.formatBytes(snapshot.cacheBytes),
      '${snapshot.maxCacheEntries}',
    );

    return [
      _DiagnosticItem(
        title: loc.runtimeEnvironmentTitle,
        value: environmentLabel,
        description: snapshot.runningOnAndroid
            ? loc.runtimeEnvironmentAndroidDescription
            : loc.runtimeEnvironmentNonAndroidDescription,
        tone: snapshot.runningOnAndroid
            ? _DiagnosticTone.healthy
            : _DiagnosticTone.info,
      ),
      _DiagnosticItem(
        title: loc.experimentalNativeInferenceFlagTitle,
        value: snapshot.experimentalNativeInferenceEnabled
            ? loc.statusEnabled
            : loc.statusDisabled,
        description: snapshot.experimentalNativeInferenceEnabled
            ? loc.experimentalNativeInferenceEnabledDescription
            : loc.experimentalNativeInferenceDisabledDescription,
        tone: snapshot.experimentalNativeInferenceEnabled
            ? _DiagnosticTone.healthy
            : snapshot.runningOnAndroid
                ? _DiagnosticTone.warning
                : _DiagnosticTone.info,
      ),
      _DiagnosticItem(
        title: loc.nativeInferenceSupportTitle,
        value: snapshot.nativeInferenceSupported
            ? loc.statusAvailable
            : loc.statusUnavailable,
        description: snapshot.nativeInferenceSupported
            ? loc.nativeInferenceSupportAvailableDescription
            : loc.nativeInferenceSupportUnavailableDescription,
        tone: snapshot.nativeInferenceSupported
            ? _DiagnosticTone.healthy
            : snapshot.runningOnAndroid &&
                    snapshot.experimentalNativeInferenceEnabled
                ? _DiagnosticTone.warning
                : _DiagnosticTone.info,
      ),
      _DiagnosticItem(
        title: loc.nativeSymbolDetectionTitle,
        value: snapshot.nativeSymbolsAvailable
            ? loc.statusDetected
            : loc.statusNotDetected,
        description: snapshot.nativeSymbolsAvailable
            ? loc.nativeSymbolDetectedDescription
            : loc.nativeSymbolMissingDescription,
        tone: snapshot.nativeSymbolsAvailable
            ? _DiagnosticTone.healthy
            : snapshot.runningOnAndroid &&
                    snapshot.experimentalNativeInferenceEnabled
                ? _DiagnosticTone.warning
                : _DiagnosticTone.info,
      ),
      _DiagnosticItem(
        title: loc.bundledModelFormatTitle,
        value: snapshot.modelFormatSupported
            ? loc.statusCompatible
            : loc.statusIncompatible,
        description: '${snapshot.modelFormatDescription}\n'
            '${snapshot.bundledFileName}',
        tone: snapshot.modelFormatSupported
            ? _DiagnosticTone.healthy
            : snapshot.runningOnAndroid
                ? _DiagnosticTone.warning
                : _DiagnosticTone.info,
      ),
      _DiagnosticItem(
        title: loc.slmInitializationStateTitle,
        value: snapshot.initialized
            ? loc.statusInitialized
            : loc.statusNotInitialized,
        description: snapshot.initialized
            ? loc.slmInitializedDescription
            : loc.slmNotInitializedDescription,
        tone: snapshot.initialized
            ? _DiagnosticTone.healthy
            : _DiagnosticTone.info,
      ),
      _DiagnosticItem(
        title: loc.modelAvailabilityTitle,
        value: snapshot.modelAvailable
            ? loc.modelAvailableNow
            : loc.usingRuleFallback,
        description: snapshot.modelAvailable
            ? loc.modelAvailabilityAvailableDescription
            : snapshot.modelFileExists && !snapshot.modelFormatSupported
                ? loc.modelAvailabilityIncompatibleDescription
                : loc.modelAvailabilityFallbackDescription,
        tone: snapshot.modelAvailable
            ? _DiagnosticTone.healthy
            : snapshot.runningOnAndroid &&
                    snapshot.experimentalNativeInferenceEnabled &&
                    snapshot.modelFileExists
                ? _DiagnosticTone.warning
                : _DiagnosticTone.info,
      ),
      _DiagnosticItem(
        title: loc.modelFile,
        value: modelFileValue,
        description: snapshot.modelFileExists
            ? '${snapshot.bundledFileName}\n${snapshot.modelFilePath}'
            : loc.modelFileMissingDescription(snapshot.modelFilePath),
        tone: snapshot.modelFileExists
            ? _DiagnosticTone.healthy
            : snapshot.runningOnAndroid
                ? _DiagnosticTone.warning
                : _DiagnosticTone.info,
      ),
      _DiagnosticItem(
        title: loc.modelCacheRuntimeParametersTitle,
        value: cacheValue,
        description: loc.modelCacheRuntimeParametersDescription(
          '${snapshot.requestTimeoutSeconds}',
          '${snapshot.maxQueueWaitSeconds}',
          '${snapshot.maxTokens}',
          snapshot.bundledAssetPath,
        ),
        tone: _DiagnosticTone.info,
      ),
    ];
  }

  GestureAction _findAction(List<GestureConfig> configs, GestureType type) {
    for (final config in configs) {
      if (config.gestureType == type) {
        return config.action;
      }
    }

    return type == GestureType.tap2
        ? GestureAction.openTemplates
        : GestureAction.openSummaries;
  }

  GestureAction? _actionFromIndex(int? index) {
    switch (index) {
      case 0:
        return GestureAction.openTemplates;
      case 1:
        return GestureAction.saveSummary;
      case 2:
        return GestureAction.openSummaries;
      default:
        return null;
    }
  }

  String _actionLabel(GestureAction? action) {
    final loc = AppLocalizations.of(context)!;
    switch (action) {
      case GestureAction.openTemplates:
        return loc.gestureActionOpenTemplates;
      case GestureAction.saveSummary:
        return loc.gestureActionSaveSummary;
      case GestureAction.openSummaries:
        return loc.gestureActionOpenSavedContext;
      case null:
        return loc.statusUnavailable;
    }
  }

  Future<void> _runSlmSelfCheck() async {
    final loc = AppLocalizations.of(context)!;
    if (_isRunningSlmSelfCheck) {
      return;
    }

    setState(() {
      _isRunningSlmSelfCheck = true;
    });

    try {
      final result = await _slmDiagnosticsService.runSelfCheck();
      final snapshot = await _slmDiagnosticsService.collectSnapshot();
      if (!mounted) {
        return;
      }

      setState(() {
        _slmSelfCheckResult = result;
        _slmSnapshot = snapshot;
        _isRunningSlmSelfCheck = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRunningSlmSelfCheck = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.slmSelfCheckFailed('$error'))),
      );
    }
  }

  Widget _buildSlmSelfCheckCard(
    BuildContext context,
    MemorySlmDiagnosticsSnapshot snapshot,
  ) {
    final loc = AppLocalizations.of(context)!;
    final result = _slmSelfCheckResult;
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = DateFormat('MM-dd HH:mm:ss');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.slmSelfCheckTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snapshot.runningOnAndroid
                          ? loc.slmSelfCheckAndroidHint
                          : loc.slmSelfCheckNonAndroidHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isRunningSlmSelfCheck ? null : _runSlmSelfCheck,
                icon: _isRunningSlmSelfCheck
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.science_outlined),
                label: Text(
                  _isRunningSlmSelfCheck ? loc.runningLabel : loc.runSelfCheck,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result == null)
            Text(
              loc.noSelfCheckYet,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ResultChip(
                  label: loc.completedChipLabel(
                    formatter.format(result.completedAt),
                  ),
                ),
                _ResultChip(
                  label: result.usedNativeModel
                      ? loc.statusModelUsed
                      : loc.statusModelNotUsed,
                  accentColor: result.usedNativeModel
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
                _ResultChip(
                  label: result.initializeCompleted
                      ? loc.statusInitializationComplete
                      : loc.statusInitializationIncomplete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SelfCheckBlock(
              title: loc.topicExtraction,
              value: result.topic.isEmpty ? loc.emptyValue : result.topic,
              detail: loc.fallbackDetailLabel(
                _fallbackLabel(result.topicFallbackMode),
                '${result.topicLatencyMs}',
              ),
            ),
            const SizedBox(height: 12),
            _SelfCheckBlock(
              title: loc.titleAndTagGeneration,
              value: result.title.isEmpty ? loc.emptyValue : result.title,
              detail:
                  '${loc.fallbackDetailLabel(_fallbackLabel(result.metadataFallbackMode), '${result.metadataLatencyMs}')}\n'
                  '${loc.tagsDetailLabel(result.tags.isEmpty ? loc.emptyValue : result.tags.join(', '))}',
            ),
          ],
        ],
      ),
    );
  }

  String _fallbackLabel(MemorySlmFallbackMode mode) {
    final loc = AppLocalizations.of(context)!;
    switch (mode) {
      case MemorySlmFallbackMode.none:
        return loc.fallbackModel;
      case MemorySlmFallbackMode.cache:
        return loc.fallbackCache;
      case MemorySlmFallbackMode.rules:
        return loc.fallbackRules;
      case MemorySlmFallbackMode.disabled:
        return loc.fallbackDisabledUnavailable;
    }
  }
}

enum _DiagnosticTone {
  healthy,
  info,
  warning,
  error,
}

class _DiagnosticItem {
  const _DiagnosticItem({
    required this.title,
    required this.value,
    required this.description,
    required this.tone,
  });

  final String title;
  final String value;
  final String description;
  final _DiagnosticTone tone;
}

class _DiagnosticSummaryBanner extends StatelessWidget {
  const _DiagnosticSummaryBanner({
    required this.items,
  });

  final List<_DiagnosticItem> items;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hasError = items.any((item) => item.tone == _DiagnosticTone.error);
    final hasWarning =
        items.any((item) => item.tone == _DiagnosticTone.warning);
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = hasError
        ? colorScheme.errorContainer
        : hasWarning
            ? Colors.amber.shade50
            : Colors.green.shade50;
    final foregroundColor = hasError
        ? colorScheme.onErrorContainer
        : hasWarning
            ? Colors.amber.shade900
            : Colors.green.shade800;
    final title = hasError
        ? loc.summaryBannerErrorTitle
        : hasWarning
            ? loc.summaryBannerWarningTitle
            : loc.summaryBannerHealthyTitle;
    final description = hasError
        ? loc.summaryBannerErrorDescription
        : hasWarning
            ? loc.summaryBannerWarningDescription
            : loc.summaryBannerHealthyDescription;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasError
                ? Icons.error_outline
                : hasWarning
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
            color: foregroundColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foregroundColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticItemCard extends StatelessWidget {
  const _DiagnosticItemCard({
    required this.item,
  });

  final _DiagnosticItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = switch (item.tone) {
      _DiagnosticTone.healthy => Colors.green.shade700,
      _DiagnosticTone.info => colorScheme.primary,
      _DiagnosticTone.warning => Colors.amber.shade800,
      _DiagnosticTone.error => colorScheme.error,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            switch (item.tone) {
              _DiagnosticTone.healthy => Icons.check_circle,
              _DiagnosticTone.info => Icons.info_outline,
              _DiagnosticTone.warning => Icons.warning_amber_rounded,
              _DiagnosticTone.error => Icons.error_outline,
            },
            color: accentColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.label,
    this.accentColor,
  });

  final String label;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color =
        accentColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    final isAccent = accentColor != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAccent ? color.withValues(alpha: 0.12) : color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isAccent ? color : null,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SelfCheckBlock extends StatelessWidget {
  const _SelfCheckBlock({
    required this.title,
    required this.value,
    required this.detail,
  });

  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
