import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/services/floating_window_service.dart';
import 'package:local_vault/core/services/share_service.dart';
import 'package:local_vault/core/utils/app_permission_manager.dart';
import 'package:local_vault/features/summary/models/summary.dart';
import 'package:local_vault/features/summary/presentation/pages/summary_detail_page.dart';
import 'package:local_vault/core/utils/storage_initializer.dart';
import 'package:local_vault/features/search/presentation/pages/search_page.dart';
import 'package:local_vault/features/settings/presentation/pages/settings_page.dart';
import 'package:local_vault/features/settings/presentation/pages/feedback_page.dart';
import 'package:local_vault/features/save/presentation/pages/save_page.dart';
import 'package:local_vault/features/inject/presentation/pages/inject_page.dart';
import 'package:local_vault/features/template/presentation/pages/template_page.dart';
import 'package:local_vault/features/quick_action/presentation/pages/quick_action_page.dart';
import 'package:local_vault/features/gesture_config/presentation/pages/gesture_config_page.dart';
import 'package:local_vault/features/app_whitelist/presentation/pages/app_whitelist_page.dart';
import 'package:local_vault/core/widgets/bottom_navigation.dart';
import 'package:local_vault/core/providers/theme_provider.dart';
import 'package:local_vault/core/providers/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageInitializer.initialize();
  runApp(const ProviderScope(child: LocalVaultApp()));
}

class LocalVaultApp extends ConsumerStatefulWidget {
  const LocalVaultApp({super.key});

  @override
  ConsumerState<LocalVaultApp> createState() => _LocalVaultAppState();
}

class _LocalVaultAppState extends ConsumerState<LocalVaultApp> with WidgetsBindingObserver {
  bool _initialized = false;
  late final GoRouter _router;
  StreamSubscription<SharedText>? _shareSubscription;
  StreamSubscription<SharedImage>? _imageSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = _createRouter();
    _loadPreferences();
    // 延迟检查权限，确保 UI 已加载和 MaterialLocalizations 可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 权限检查会在 _loadPreferences 完成后触发
    });
  }

  /// 初始化分享服务
  void _initializeShareService() {
    debugPrint('🚀 [main] 开始初始化分享服务...');
    
    // 初始化 ShareService
    final shareService = ShareService();
    shareService.initialize();
    
    // 监听分享文本流
    _shareSubscription = shareService.shareStream.listen((sharedText) {
      if (mounted) {
        debugPrint('✨ [main] 从 Stream 收到分享：${sharedText.text.substring(0, sharedText.text.length.clamp(0, 50))}...');
        _handleShareText(sharedText.text);
      }
    });
    
    // 监听分享图片流
    _imageSubscription = shareService.imageStream.listen((sharedImage) {
      if (mounted) {
        debugPrint('🖼️ [main] 从 Stream 收到图片分享：${sharedImage.uris.length} 张');
        _handleShareImage(sharedImage.uris);
      }
    });
    
    // 同时尝试获取待处理的分享文本（兼容旧模式）
    shareService.getPendingShareText().then((text) {
      if (text != null && mounted) {
        debugPrint('🔄 [main] 从 getPendingShareText 获取到分享文本');
        _handleShareText(text);
      }
    });
    
    debugPrint('✅ [main] 分享服务初始化完成');
  }

  void _handleShareText(String text) {
    debugPrint('Flutter 收到分享文本：$text');
    // 直接导航到保存页面，并传递文本
    _router.push(AppRoutes.save, extra: text);
  }
  
  void _handleShareImage(List<String> uris) {
    debugPrint('Flutter 收到分享图片：${uris.length} 张');
    // 导航到保存页面，传递图片 URIs
    _router.push(AppRoutes.save, extra: {'type': 'image', 'uris': uris});
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;
    
    // 延迟检查，确保 UI 完全加载
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    
    final hasUsageStats = await AppPermissionManager.checkUsageStatsPermission();
    
    if (!hasUsageStats && mounted) {
      try {
        _showUsageStatsPermissionDialog();
      } catch (e) {
        debugPrint('⚠️ [main] 显示权限对话框失败：$e，将在下次启动时重试');
      }
    }
  }

  void _showUsageStatsPermissionDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 需要重要权限'),
        content: const Text(
          '检测到未授予"使用情况统计"权限，这将导致：\n\n'
          '❌ 无法检测当前正在使用的应用\n'
          '❌ 手势唤醒功能在其他应用中无法正常工作\n\n'
          '请点击"去授权"按钮，在系统设置中找到该应用并开启此权限。',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 用户选择稍后提醒
            },
            child: const Text('稍后再说'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AppPermissionManager.requestUsageStatsPermission();
            },
            child: const Text('去授权'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shareSubscription?.cancel();
    _imageSubscription?.cancel();
    ShareService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingAction();
    }
  }

  Future<void> _checkPendingAction() async {
    final action = await FloatingWindowService.getPendingAction();
    if (action != null && mounted) {
      _navigateToAction(action);
    }
  }

  void _navigateToAction(String action) {
    QuickActionType? actionType;
    switch (action) {
      case 'OPEN_TEMPLATES':
        actionType = QuickActionType.templates;
        break;
      case 'OPEN_SAVE':
        actionType = QuickActionType.save;
        break;
      case 'OPEN_SUMMARIES':
        actionType = QuickActionType.summaries;
        break;
    }

    if (actionType != null) {
      _router.push(AppRoutes.quickAction, extra: actionType);
    }
  }

  GoRouter _createRouter() {
    return GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const BottomNavigation(),
        ),
        GoRoute(
          path: AppRoutes.search,
          builder: (context, state) => const SearchPage(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/feedback',
          builder: (context, state) => const FeedbackPage(),
        ),
        GoRoute(
          path: AppRoutes.summaryDetail,
          builder: (context, state) {
            final summary = state.extra as Summary;
            return SummaryDetailPage(summary: summary);
          },
        ),
        GoRoute(
          path: AppRoutes.save,
          builder: (context, state) {
            // 从路由参数或 extra 获取分享文本或图片
            final initialData = state.extra;
            return SavePage(initialData: initialData);
          },
        ),
        GoRoute(
          path: AppRoutes.inject,
          builder: (context, state) => const InjectPage(),
        ),
        GoRoute(
          path: AppRoutes.template,
          builder: (context, state) => const TemplatePage(),
        ),
        GoRoute(
          path: AppRoutes.quickAction,
          builder: (context, state) {
            final actionType = state.extra as QuickActionType;
            return QuickActionPage(actionType: actionType);
          },
        ),
        GoRoute(
          path: AppRoutes.gestureConfig,
          builder: (context, state) => const GestureConfigPage(),
        ),
        GoRoute(
          path: AppRoutes.appWhitelist,
          builder: (context, state) => const AppWhitelistPage(),
        ),
      ],
    );
  }

  Future<void> _loadPreferences() async {
    final themeMode = await ThemeManager.loadThemeMode();
    final locale = await LocaleManager.loadLocale();
    
    ref.read(themeModeProvider.notifier).state = themeMode;
    ref.read(appLocaleProvider.notifier).state = locale;
    
    setState(() {
      _initialized = true;
    });
    
    // 等待两帧，确保 MaterialLocalizations 完全加载
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _checkPermissions();
      _initializeShareService();
      _checkPendingAction();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final themeMode = ref.watch(themeModeProvider);
    final appLocale = ref.watch(appLocaleProvider);
    final locale = LocaleManager.getLocale(appLocale);

    return MaterialApp.router(
      title: 'Local Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
        Locale('ja'),
        Locale('ko'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
      ],
      locale: locale,
      routerConfig: _router,
    );
  }
}
