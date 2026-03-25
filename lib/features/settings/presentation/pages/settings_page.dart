import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/providers/locale_provider.dart';
import 'package:local_vault/core/providers/theme_provider.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:local_vault/core/services/floating_window_service.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/services/storage_management_service.dart';
import 'package:local_vault/core/utils/app_permission_manager.dart';
import 'package:local_vault/core/utils/architecture_verifier.dart';
import 'package:local_vault/features/settings/presentation/pages/backup_data_page.dart';
import 'package:local_vault/features/settings/presentation/pages/storage_space_page.dart';
import 'package:local_vault/l10n/app_localizations.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _floatingWindowEnabled = false;
  bool _slmInferenceEnabled = false;
  bool _isLoading = true;
  StorageUsageSnapshot? _usageSnapshot;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsService = sl<AppSettingsService>();
    final storageService = sl<StorageManagementService>();
    final slmService = sl<MemorySLMService>();
    final floatingWindowEnabled =
        await settingsService.isFloatingWindowEnabled();
    final slmInferenceEnabled = await slmService.isSlmInferenceEnabled();
    StorageUsageSnapshot? usageSnapshot;

    try {
      usageSnapshot = await storageService.inspectStorage();
    } catch (_) {}

    if (!mounted) {
      return;
    }
    setState(() {
      _floatingWindowEnabled = floatingWindowEnabled;
      _slmInferenceEnabled = slmInferenceEnabled;
      _usageSnapshot = usageSnapshot;
      _isLoading = false;
    });
  }

  Future<void> _openStorageSpacePage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const StorageSpacePage(),
      ),
    );
    await _loadSettings();
  }

  Future<void> _openBackupDataPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BackupDataPage(),
      ),
    );
    await _loadSettings();
  }

  Future<void> _toggleFloatingWindow(bool value) async {
    final loc = AppLocalizations.of(context)!;
    final settingsService = sl<AppSettingsService>();

    if (value) {
      // 先启动服务并保存设置
      try {
        await FloatingWindowService.startFloatingService();
        await settingsService.setFloatingWindowEnabled(true);
        setState(() {
          _floatingWindowEnabled = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.floatingWindowServiceStarted),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.failedToStartMessage('$e'))),
          );
        }
        return;
      }

      // 服务启动后，检查使用情况访问权限
      final hasUsageStatsPermission =
          await AppPermissionManager.checkUsageStatsPermission();
      if (!hasUsageStatsPermission && mounted) {
        await _showUsageAccessPermissionDialog();
      }

      // 显示使用提示
      if (mounted) {
        _showPermissionTips();
      }
    } else {
      try {
        await FloatingWindowService.stopFloatingService();
        await settingsService.setFloatingWindowEnabled(false);
        setState(() {
          _floatingWindowEnabled = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.floatingWindowServiceStopped)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.failedToStopMessage('$e'))),
          );
        }
      }
    }
  }

  Future<void> _toggleSlmInference(bool value) async {
    final loc = AppLocalizations.of(context)!;
    final slmService = sl<MemorySLMService>();
    await slmService.setSlmInferenceEnabled(value);
    if (!mounted) {
      return;
    }

    setState(() {
      _slmInferenceEnabled = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? loc.slmInferenceEnabledMessage
              : loc.slmInferenceDisabledMessage,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final appLocale = ref.watch(appLocaleProvider);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
      ),
      body: ListView(
        children: [
          // 快捷操作模块 - 打包时隐藏
          // _buildSectionHeader(loc.quickActions),
          // _buildFloatingWindowSwitch(loc),
          // _buildGestureConfig(loc),
          // _buildAppWhitelist(loc),
          // _buildDiagnostics(loc),

          // 通用设置
          _buildSectionHeader(loc.generalSettings),
          _buildSlmInferenceSwitch(loc),
          _buildThemeSelector(loc, themeMode, ref),
          _buildLanguageSelector(loc, appLocale, ref),

          // 存储设置
          _buildSectionHeader(loc.storageSettings),
          _buildStorageSpace(loc),
          _buildBackupData(loc),

          // 架构检查模块 - 打包时隐藏
          // _buildSectionHeader(loc.architectureChecksDebugOnly),
          // _buildArchitectureVerification(loc),
          // _buildDatabaseInspector(loc),

          // 关于
          _buildSectionHeader(loc.about),
          _buildVersionInfo(loc),
          _buildFeedback(loc, context),
        ],
      ),
    );
  }

  Widget _buildArchitectureVerification(AppLocalizations loc) {
    return ListTile(
      title: Text(loc.runArchitectureVerification),
      subtitle: Text(loc.runArchitectureVerificationDescription),
      trailing: const Icon(Icons.play_arrow),
      onTap: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.runningArchitectureVerification),
            duration: const Duration(seconds: 2),
          ),
        );
        await verifyNewArchitecture();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.architectureVerificationFinished),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  Widget _buildDatabaseInspector(AppLocalizations loc) {
    return ListTile(
      title: Text(loc.inspectDatabase),
      subtitle: Text(loc.inspectDatabaseDescription),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push(AppRoutes.databaseInspector);
      },
    );
  }

  Widget _buildFloatingWindowSwitch(AppLocalizations loc) {
    return ListTile(
      title: Text(loc.enableFloatingGestureLauncher),
      subtitle: Text(loc.floatingGestureLauncherDescription),
      trailing: Switch(
        value: _floatingWindowEnabled,
        onChanged: _toggleFloatingWindow,
      ),
    );
  }

  Widget _buildGestureConfig(AppLocalizations loc) {
    return ListTile(
      title: Text(loc.gestureConfiguration),
      subtitle: Text(loc.gestureConfigurationDescription),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push(AppRoutes.gestureConfig);
      },
    );
  }

  Widget _buildAppWhitelist(AppLocalizations loc) {
    return ListTile(
      title: Text(loc.appAllowlist),
      subtitle: Text(loc.appAllowlistDescription),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push(AppRoutes.appWhitelist);
      },
    );
  }

  Widget _buildDiagnostics(AppLocalizations loc) {
    return ListTile(
      title: Text(loc.diagnostics),
      subtitle: Text(loc.diagnosticsDescription),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push(AppRoutes.diagnostics);
      },
    );
  }

  Widget _buildSlmInferenceSwitch(AppLocalizations loc) {
    return ListTile(
      title: Text(loc.slmInferenceSettingTitle),
      subtitle: Text(loc.slmInferenceSettingDescription),
      trailing: Switch(
        value: _slmInferenceEnabled,
        onChanged: null, // 打包版本禁用交互
      ),
      enabled: false, // 整体置灰
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    AppLocalizations loc,
    ThemeMode currentTheme,
    WidgetRef ref,
  ) {
    final currentAppTheme = ThemeManager.getAppThemeMode(currentTheme);
    return ListTile(
      title: Text(loc.themeSettings),
      subtitle: Text(_getThemeLabel(loc, currentAppTheme)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<AppThemeMode>(
          value: currentAppTheme,
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (AppThemeMode? newValue) {
            if (newValue != null) {
              ThemeMode themeMode;
              switch (newValue) {
                case AppThemeMode.system:
                  themeMode = ThemeMode.system;
                  break;
                case AppThemeMode.light:
                  themeMode = ThemeMode.light;
                  break;
                case AppThemeMode.dark:
                  themeMode = ThemeMode.dark;
                  break;
              }
              ref.read(themeModeProvider.notifier).state = themeMode;
              ThemeManager.saveThemeMode(newValue);
            }
          },
          items: AppThemeMode.values.map((AppThemeMode mode) {
            return DropdownMenuItem<AppThemeMode>(
              value: mode,
              child: Text(_getThemeLabel(loc, mode)),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getThemeLabel(AppLocalizations loc, AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return loc.systemMode;
      case AppThemeMode.light:
        return loc.lightMode;
      case AppThemeMode.dark:
        return loc.darkMode;
    }
  }

  Widget _buildLanguageSelector(
    AppLocalizations loc,
    AppLocale currentLocale,
    WidgetRef ref,
  ) {
    return ListTile(
      title: Text(loc.language),
      subtitle: Text(_getLanguageLabel(loc, currentLocale)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<AppLocale>(
          value: currentLocale,
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (AppLocale? newValue) {
            if (newValue != null) {
              ref.read(appLocaleProvider.notifier).state = newValue;
              LocaleManager.saveLocale(newValue);
            }
          },
          items: AppLocale.values.map((AppLocale locale) {
            return DropdownMenuItem<AppLocale>(
              value: locale,
              child: Text(_getLanguageLabel(loc, locale)),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getLanguageLabel(AppLocalizations loc, AppLocale locale) {
    switch (locale) {
      case AppLocale.system:
        return loc.systemMode;
      case AppLocale.en:
        return loc.languageEnglish;
      case AppLocale.zh:
        return loc.languageChinese;
      case AppLocale.ja:
        return loc.languageJapanese;
      case AppLocale.ko:
        return loc.languageKorean;
      case AppLocale.es:
        return loc.languageSpanish;
      case AppLocale.fr:
        return loc.languageFrench;
      case AppLocale.de:
        return loc.languageGerman;
    }
  }

  Widget _buildStorageSpace(AppLocalizations loc) {
    return ListTile(
      title: Text(loc.storageSpace),
      subtitle: Text(_buildStorageSummary(loc)),
      trailing: const Icon(Icons.chevron_right),
      onTap: _openStorageSpacePage,
    );
  }

  Widget _buildBackupData(AppLocalizations loc) {
    return ListTile(
      title: Text(loc.backupData),
      subtitle: Text(_buildBackupSummary(loc)),
      trailing: const Icon(Icons.chevron_right),
      onTap: _openBackupDataPage,
    );
  }

  String _buildStorageSummary(AppLocalizations loc) {
    final usage = _usageSnapshot;
    if (usage == null) {
      return loc.storageSummaryTapToView;
    }

    return loc.storageSummaryFormat(
      StorageManagementService.formatBytes(usage.totalBytes),
      '${usage.summaryCount}',
      '${usage.templateCount}',
    );
  }

  String _buildBackupSummary(AppLocalizations loc) {
    final usage = _usageSnapshot;
    if (usage == null) {
      return loc.createShareRestoreLocalBackups;
    }

    if (usage.backupFileCount == 0) {
      return loc.backupSummaryNone;
    }

    return loc.backupSummaryAvailable('${usage.backupFileCount}');
  }

  Widget _buildVersionInfo(AppLocalizations loc) {
    return ListTile(
      title: Text(loc.versionInfo),
      subtitle: const Text('v1.0.0'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _buildFeedback(AppLocalizations loc, BuildContext context) {
    return ListTile(
      title: Text(loc.feedback),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push('/feedback');
      },
    );
  }

  void _showPermissionTips() {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.serviceStarted),
        content: Text(loc.floatingWindowTips),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.okLabel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.appWhitelist);
            },
            child: Text(loc.openAllowlist),
          ),
        ],
      ),
    );
  }

  Future<void> _showUsageAccessPermissionDialog() async {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;

    final granted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info_outline, color: Colors.orange),
        title: Text(loc.usageAccessPermissionRequiredTitle),
        content: Text(loc.usageAccessPermissionRequiredMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.grantAccessLabel),
          ),
        ],
      ),
    );

    if (granted == true && mounted) {
      // User agreed to grant permission, open settings
      await AppPermissionManager.requestUsageStatsPermission();
    }
  }
}
