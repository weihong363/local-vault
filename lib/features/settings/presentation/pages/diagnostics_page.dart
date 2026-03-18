import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/services/gesture_diagnostics_service.dart';
import 'package:local_vault/features/app_whitelist/domain/providers/app_whitelist_provider.dart';
import 'package:local_vault/features/app_whitelist/models/app_info.dart';
import 'package:local_vault/features/gesture_config/domain/providers/gesture_config_provider.dart';
import 'package:local_vault/features/gesture_config/models/gesture_config.dart';

class DiagnosticsPage extends ConsumerStatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  ConsumerState<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends ConsumerState<DiagnosticsPage> {
  late final GestureDiagnosticsService _diagnosticsService;
  GestureDiagnosticsSnapshot? _snapshot;
  Object? _error;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _diagnosticsService = sl<GestureDiagnosticsService>();
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
      if (!mounted) return;

      setState(() {
        _snapshot = snapshot;
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
    final gestureConfigs = ref.watch(gestureConfigProvider);
    final whitelist = ref.watch(appWhitelistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('诊断'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _loadDiagnostics,
            tooltip: '刷新诊断',
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

    if (_error != null || providerError != null || _snapshot == null) {
      final message = _error ?? providerError ?? '无法加载诊断信息';
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
                child: const Text('重试'),
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

    return RefreshIndicator(
      onRefresh: _loadDiagnostics,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _DiagnosticSummaryBanner(items: items),
          const SizedBox(height: 16),
          Text(
            '手势诊断',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '下拉可刷新权限、服务和原生同步状态。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DiagnosticItemCard(item: item),
              )),
          if (whitelistApps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '白名单应用',
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
        title: '悬浮窗手势唤醒',
        value: snapshot.floatingWindowEnabled ? '已开启' : '已关闭',
        description: snapshot.floatingWindowEnabled
            ? '设置中的手势总开关已打开。'
            : '总开关关闭时，双击和三击都不会触发。',
        tone: snapshot.floatingWindowEnabled
            ? _DiagnosticTone.healthy
            : _DiagnosticTone.warning,
      ),
      _DiagnosticItem(
        title: '悬浮窗权限',
        value: snapshot.overlayPermissionGranted ? '已授权' : '未授权',
        description: snapshot.overlayPermissionGranted
            ? '系统允许应用在其他应用上层工作。'
            : '未授权时，悬浮窗服务无法正常启动。',
        tone: snapshot.overlayPermissionGranted
            ? _DiagnosticTone.healthy
            : _DiagnosticTone.error,
      ),
      _DiagnosticItem(
        title: '使用情况统计权限',
        value: snapshot.usageStatsPermissionGranted ? '已授权' : '未授权',
        description: snapshot.usageStatsPermissionGranted
            ? '应用可以识别当前前台应用，用于白名单判断。'
            : '未授权时，白名单判断和跨应用手势触发都会失效。',
        tone: snapshot.usageStatsPermissionGranted
            ? _DiagnosticTone.healthy
            : _DiagnosticTone.error,
      ),
      _DiagnosticItem(
        title: '悬浮窗服务状态',
        value: switch (snapshot.floatingServiceRunning) {
          true => '运行中',
          false => '未运行',
          null => '状态不可用',
        },
        description: switch (snapshot.floatingServiceRunning) {
          true => '原生悬浮窗服务当前正在监听手势。',
          false when snapshot.floatingWindowEnabled => '总开关已开启，但原生悬浮窗服务当前没有运行。',
          false => '总开关关闭时，服务通常会保持停止。',
          null => '当前无法读取原生服务状态。',
        },
        tone: switch (snapshot.floatingServiceRunning) {
          true => _DiagnosticTone.healthy,
          false when snapshot.floatingWindowEnabled => _DiagnosticTone.warning,
          false => _DiagnosticTone.info,
          null => _DiagnosticTone.info,
        },
      ),
      _DiagnosticItem(
        title: '双击动作同步',
        value:
            'Flutter：${_actionLabel(flutterTap2Action)} / 原生：${_actionLabel(nativeTap2Action)}',
        description: flutterTap2Action == nativeTap2Action
            ? '双击动作已经同步到原生层。'
            : '当前双击动作和原生层不一致，建议重新保存一次手势配置。',
        tone: flutterTap2Action == nativeTap2Action
            ? _DiagnosticTone.healthy
            : _DiagnosticTone.warning,
      ),
      _DiagnosticItem(
        title: '三击动作同步',
        value:
            'Flutter：${_actionLabel(flutterTap3Action)} / 原生：${_actionLabel(nativeTap3Action)}',
        description: flutterTap3Action == nativeTap3Action
            ? '三击动作已经同步到原生层。'
            : '当前三击动作和原生层不一致，建议重新保存一次手势配置。',
        tone: flutterTap3Action == nativeTap3Action
            ? _DiagnosticTone.healthy
            : _DiagnosticTone.warning,
      ),
      _DiagnosticItem(
        title: '白名单范围',
        value:
            whitelistApps.isEmpty ? '全部应用' : '已限制 ${whitelistApps.length} 个应用',
        description: whitelistApps.isEmpty
            ? '当前手势会在所有前台应用中尝试生效。'
            : '当前只有白名单中的前台应用会响应手势。',
        tone: whitelistApps.isEmpty
            ? _DiagnosticTone.info
            : _DiagnosticTone.healthy,
      ),
      _DiagnosticItem(
        title: '白名单原生同步',
        value:
            'Flutter：${whitelistApps.length} 个 / 原生：${nativeWhitelistPackages?.length ?? '-'} 个',
        description: nativeWhitelistPackages == null
            ? '当前无法读取原生白名单。'
            : whitelistSynced
                ? '白名单已经同步到原生层。'
                : 'Flutter 和原生白名单不一致，建议重新进入白名单页触发一次同步。',
        tone: nativeWhitelistPackages == null
            ? _DiagnosticTone.info
            : whitelistSynced
                ? _DiagnosticTone.healthy
                : _DiagnosticTone.warning,
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
    switch (action) {
      case GestureAction.openTemplates:
        return '打开提示词模板';
      case GestureAction.saveSummary:
        return '保存摘要';
      case GestureAction.openSummaries:
        return '打开已保存的上下文';
      case null:
        return '未读取到';
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
        ? '发现会直接影响手势工作的异常'
        : hasWarning
            ? '发现需要留意的手势配置问题'
            : '当前没有发现明显的手势异常';
    final description = hasError
        ? '建议优先处理权限未授权这类问题。'
        : hasWarning
            ? '同步状态或服务状态存在偏差时，手势可能不会按预期触发。'
            : '权限、服务和原生同步状态看起来都正常。';

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
