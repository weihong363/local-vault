import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/services/share_service.dart';
import 'package:local_vault/core/services/save_coordinator.dart';
import 'package:local_vault/core/utils/app_permission_manager.dart';
import 'package:local_vault/features/summary/presentation/pages/summary_detail_page.dart';
import 'package:local_vault/core/utils/storage_initializer.dart';
import 'package:local_vault/features/search/presentation/pages/search_page.dart';
import 'package:local_vault/features/settings/presentation/pages/settings_page.dart';
import 'package:local_vault/features/settings/presentation/pages/feedback_page.dart';
import 'package:local_vault/features/save/presentation/pages/save_page.dart';
import 'package:local_vault/features/inject/presentation/pages/inject_page.dart';
import 'package:local_vault/features/template/presentation/pages/template_page.dart';
import 'package:local_vault/features/quick_action/presentation/pages/quick_action_page.dart';
import 'package:local_vault/features/quick_action/models/quick_action_type.dart';
import 'package:local_vault/features/gesture_config/presentation/pages/gesture_config_page.dart';
import 'package:local_vault/features/app_whitelist/presentation/pages/app_whitelist_page.dart';
import 'package:local_vault/features/memory/presentation/pages/memory_management_page.dart';
import 'package:local_vault/core/widgets/bottom_navigation.dart';
import 'package:local_vault/core/widgets/quick_action_activity_page.dart';
import 'package:local_vault/core/providers/theme_provider.dart';
import 'package:local_vault/core/providers/locale_provider.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageInitializer.initialize();
  await initializeDependencies();
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
  static const MethodChannel _quickSaveChannel = MethodChannel('com.ironion.localvault/quick_save');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = _createRouter();
    _loadPreferences();
    _setupQuickSaveChannel();
  }

  /// 设置快速保存 MethodChannel
  void _setupQuickSaveChannel() {
    _quickSaveChannel.setMethodCallHandler((call) async {
      debugPrint('📥 [main] 收到 MethodChannel 调用：${call.method}');
      try {
        switch (call.method) {
          case 'saveFromClipboard':
            final content = call.arguments as String;
            await _handleSaveFromClipboard(content);
            return true;
          case 'openTemplates':
            _router.push(AppRoutes.template);
            return true;
          case 'openSave':
            _router.push(AppRoutes.save);
            return true;
          case 'openSummaries':
            _router.go(AppRoutes.home);
            return true;
          case 'openInject':
            _router.push(AppRoutes.inject);
            return true;
          default:
            throw PlatformException(
              code: 'Unimplemented',
              message: 'Method ${call.method} not implemented',
            );
        }
      } catch (e) {
        debugPrint('❌ [main] MethodChannel 处理失败：$e');
        rethrow;
      }
    });
    debugPrint('✅ [main] QuickSave MethodChannel 已设置');
  }

  /// 处理从剪贴板保存
  Future<void> _handleSaveFromClipboard(String content) async {
    debugPrint('💾 [main] 开始静默保存剪贴板内容，长度：${content.length}');
    try {
      final saveCoordinator = SaveCoordinator();
      final success = await saveCoordinator.handleQuickAction(
        content: content,
        actionId: 'quick_save_from_clipboard',
      );
      
      if (success) {
        debugPrint('✅ [main] 静默保存成功');
      } else {
        debugPrint('⚠️ [main] 静默保存被中断，跳转到保存页面');
        _router.push(AppRoutes.save, extra: content);
      }
    } catch (e) {
      debugPrint('❌ [main] 静默保存失败：$e，跳转到保存页面');
      _router.push(AppRoutes.save, extra: content);
    }
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
        debugPrint('✨ [main] 从 Stream 收到分享，来源：${sharedText.source}');
        debugPrint('✨ [main] 文本内容：${sharedText.text.substring(0, sharedText.text.length.clamp(0, 50))}...');
        
        // 根据来源决定处理方式
        if (sharedText.source == 'quick_save' || sharedText.source == 'silent_save_from_tile') {
          // 快捷方式保存，静默保存
          debugPrint('🤫 [main] 快捷方式保存，执行静默保存');
          _handleSilentSave(sharedText.text);
        } else {
          // 普通分享，打开保存页面
          debugPrint('📱 [main] 普通分享，打开保存页面');
          _handleShareText(sharedText.text);
        }
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

  /// 处理静默保存（不打开 UI）
  Future<void> _handleSilentSave(String text) async {
    debugPrint('💾 [main] 开始静默保存...');
    try {
      final saveCoordinator = SaveCoordinator();
      final success = await saveCoordinator.handleQuickAction(
        content: text,
        actionId: 'quick_save_from_share_stream',
      );
      
      if (success) {
        debugPrint('✅ [main] 静默保存成功');
      } else {
        debugPrint('⚠️ [main] 静默保存被中断，跳转到保存页面');
        _router.push(AppRoutes.save, extra: text);
      }
    } catch (e) {
      debugPrint('❌ [main] 静默保存失败：$e，跳转到保存页面');
      _router.push(AppRoutes.save, extra: text);
    }
  }

  void _handleShareText(String text) {
    debugPrint('📝 [main] Flutter 收到分享文本，长度：${text.length}');
    debugPrint('📝 [main] 文本内容：${text.substring(0, text.length.clamp(0, 100))}${text.length > 100 ? '...' : ''}');
    // 直接导航到保存页面，并传递文本
    debugPrint('🚀 [main] 准备导航到保存页面...');
    _router.push(AppRoutes.save, extra: text);
    debugPrint('✅ [main] 导航完成');
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
      debugPrint('🔄 [main] 应用恢复，执行记忆清理');
      _runMemoryCleanup();
    }
  }

  Future<void> _runMemoryCleanup() async {
    try {
      final container = ProviderScope.containerOf(context);
      final notifier = container.read(summaryEntityNotifierProvider.notifier);
      await notifier.applyForgettingCurve();
      await notifier.cleanupSessionMemories();
      debugPrint('✅ [main] 记忆清理完成');
    } catch (e) {
      debugPrint('❌ [main] 记忆清理失败: $e');
    }
  }

  GoRouter _createRouter() {
    return GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.quickActionActivity,
          builder: (context, state) => const QuickActionActivityPage(),
        ),
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
            final extra = state.extra;
            if (extra is SummaryEntity) {
              return SummaryDetailPage(summary: extra);
            }
            return const BottomNavigation();
          },
        ),
        GoRoute(
          path: AppRoutes.save,
          builder: (context, state) {
            final initialData = state.extra;
            SummaryEntity? editingSummary;
            if (initialData is SummaryEntity) {
              editingSummary = initialData;
            }
            return SavePage(initialData: editingSummary != null ? null : initialData, editingSummary: editingSummary);
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
        GoRoute(
          path: AppRoutes.memoryManagement,
          builder: (context, state) => const MemoryManagementPage(),
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
