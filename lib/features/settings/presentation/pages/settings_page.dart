import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/providers/theme_provider.dart';
import 'package:local_vault/core/providers/locale_provider.dart';
import 'package:local_vault/core/services/floating_window_service.dart';
import 'package:local_vault/core/utils/app_permission_manager.dart';
import 'package:local_vault/core/utils/architecture_verifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _floatingWindowEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _floatingWindowEnabled = prefs.getBool('floating_window_enabled') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _toggleFloatingWindow(bool value) async {
    final prefs = await SharedPreferences.getInstance();
      
    if (value) {
      // 检查并请求所有必需的权限
      final allGranted = await AppPermissionManager.requestAllPermissions();
        
      if (!allGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('权限未完全授予，手势功能可能无法正常工作'),
            duration: Duration(seconds: 3),
          ),
        );
      }
        
      try {
        await FloatingWindowService.startFloatingService();
        await prefs.setBool('floating_window_enabled', true);
        setState(() {
          _floatingWindowEnabled = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('悬浮窗服务已启动'),
              duration: Duration(seconds: 2),
            ),
          );
            
          // 显示权限提示
          _showPermissionTips();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('启动失败：$e')),
          );
        }
      }
    } else {
      try {
        await FloatingWindowService.stopFloatingService();
        await prefs.setBool('floating_window_enabled', false);
        setState(() {
          _floatingWindowEnabled = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('悬浮窗服务已关闭')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('关闭失败：$e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
          _buildSectionHeader('快捷操作'),
          _buildFloatingWindowSwitch(),
          _buildGestureConfig(),
          _buildAppWhitelist(),
          _buildSectionHeader(loc.generalSettings),
          _buildThemeSelector(loc, themeMode, ref),
          _buildLanguageSelector(loc, appLocale, ref),
          _buildSectionHeader(loc.storageSettings),
          _buildMemoryManagement(),
          _buildStorageSpace(loc),
          _buildBackupData(loc),
          _buildSectionHeader('架构测试'),
          _buildArchitectureVerification(),
          _buildSectionHeader(loc.about),
          _buildVersionInfo(loc),
          _buildFeedback(loc, context),
        ],
      ),
    );
  }

  Widget _buildArchitectureVerification() {
    return ListTile(
      title: const Text('运行架构验证'),
      subtitle: const Text('验证新架构是否正常工作'),
      trailing: const Icon(Icons.play_arrow),
      onTap: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('正在运行架构验证...'),
            duration: Duration(seconds: 2),
          ),
        );
        await verifyNewArchitecture();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('架构验证完成！请查看控制台输出'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  Widget _buildFloatingWindowSwitch() {
    return ListTile(
      title: const Text('悬浮窗手势唤醒'),
      subtitle: const Text('在其他应用中通过手势快速打开'),
      trailing: Switch(
        value: _floatingWindowEnabled,
        onChanged: _toggleFloatingWindow,
      ),
    );
  }

  Widget _buildGestureConfig() {
    return ListTile(
      title: const Text('手势配置'),
      subtitle: const Text('自定义手势'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push(AppRoutes.gestureConfig);
      },
    );
  }

  Widget _buildAppWhitelist() {
    return ListTile(
      title: const Text('应用白名单'),
      subtitle: const Text('手势仅在选中的应用中生效'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push(AppRoutes.appWhitelist);
      },
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
        return 'English';
      case AppLocale.zh:
        return '中文';
      case AppLocale.ja:
        return '日本語';
      case AppLocale.ko:
        return '한국어';
      case AppLocale.es:
        return 'Español';
      case AppLocale.fr:
        return 'Français';
      case AppLocale.de:
        return 'Deutsch';
    }
  }

  Widget _buildStorageSpace(AppLocalizations loc) {
    return ListTile(
      title: Text(loc.storageSpace),
      subtitle: const Text('128 MB / 500 MB'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _buildBackupData(AppLocalizations loc) {
    return ListTile(
      title: Text(loc.backupData),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _buildVersionInfo(AppLocalizations loc) {
    return ListTile(
      title: Text(loc.versionInfo),
      subtitle: const Text('v1.0.0'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _buildMemoryManagement() {
    return ListTile(
      title: const Text('记忆管理'),
      subtitle: const Text('管理、合并和清理记忆'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push(AppRoutes.memoryManagement);
      },
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
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ 服务已启动'),
        content: const Text(
          '悬浮窗手势服务已成功启动！\n\n'
          '📝 使用提示：\n'
          '1. 在屏幕左右边缘可以看到半透明的紫色区域\n'
          '2. 在这些区域滑动手势即可快速打开应用\n'
          '3. 如果看不到悬浮窗，请检查是否授予了所有权限\n\n'
          '⚠️ 重要：\n'
          '如果切换到其他应用后手势失效，请检查:\n'
          '• 该应用是否在白名单中\n'
          '• 是否授予了"使用情况统计"权限',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('好的'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.appWhitelist);
            },
            child: const Text('配置白名单'),
          ),
        ],
      ),
    );
  }
}
