import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/providers/locale_provider.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';
import 'package:local_vault/core/providers/theme_provider.dart';
import 'package:local_vault/core/services/memory_slm_diagnostics_service.dart';
import 'package:local_vault/core/services/save_coordinator.dart';
import 'package:local_vault/core/services/share_service.dart';
import 'package:local_vault/core/utils/app_permission_manager.dart';
import 'package:local_vault/core/utils/storage_initializer.dart';
import 'package:local_vault/core/utils/memory_title_generator.dart';
import 'package:local_vault/core/widgets/bottom_navigation.dart';
import 'package:local_vault/core/widgets/quick_action_activity_page.dart';
import 'package:local_vault/features/app_whitelist/presentation/pages/app_whitelist_page.dart';
import 'package:local_vault/features/gesture_config/presentation/pages/gesture_config_page.dart';
import 'package:local_vault/features/inject/presentation/pages/inject_page.dart';
import 'package:local_vault/features/quick_action/models/quick_action_type.dart';
import 'package:local_vault/features/quick_action/presentation/pages/quick_action_page.dart';
import 'package:local_vault/features/save/presentation/pages/save_page.dart';
import 'package:local_vault/features/search/presentation/pages/search_page.dart';
import 'package:local_vault/features/settings/presentation/pages/database_inspector_page.dart';
import 'package:local_vault/features/settings/presentation/pages/diagnostics_page.dart';
import 'package:local_vault/features/settings/presentation/pages/feedback_page.dart';
import 'package:local_vault/features/summary/presentation/pages/summary_detail_page.dart';
import 'package:local_vault/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageInitializer.initialize();
  await initializeDependencies();
  // 初始化 Topic Taxonomy
  await StructuredMemoryTitleGenerator.initialize();
  runApp(const ProviderScope(child: LocalVaultApp()));
}

class LocalVaultApp extends ConsumerStatefulWidget {
  const LocalVaultApp({super.key});

  @override
  ConsumerState<LocalVaultApp> createState() => _LocalVaultAppState();
}

class _LocalVaultAppState extends ConsumerState<LocalVaultApp>
    with WidgetsBindingObserver {
  static const bool _autoRunSlmSelfCheckOnStartup = bool.fromEnvironment(
    'AUTO_RUN_SLM_SELF_CHECK_ON_STARTUP',
    defaultValue: false,
  );
  bool _initialized = false;
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  late final GoRouter _router;
  StreamSubscription<SharedText>? _shareSubscription;
  StreamSubscription<SharedImage>? _imageSubscription;
  static const MethodChannel _quickSaveChannel =
      MethodChannel('com.ironion.localvault/quick_save');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = _createRouter();
    _loadPreferences();
    _setupQuickSaveChannel();
  }

  /// Configure the quick-save MethodChannel.
  void _setupQuickSaveChannel() {
    _quickSaveChannel.setMethodCallHandler((call) async {
      debugPrint('📥 [main] Received MethodChannel call: ${call.method}');
      try {
        switch (call.method) {
          case 'saveFromClipboard':
            final content = call.arguments as String;
            await _handleSaveFromClipboard(content);
            return true;
          case 'openTemplates':
            _router.go(AppRoutes.template);
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
        debugPrint('❌ [main] MethodChannel handling failed: $e');
        rethrow;
      }
    });
    debugPrint('✅ [main] QuickSave MethodChannel configured');
  }

  /// Save content from the clipboard.
  Future<void> _handleSaveFromClipboard(String content) async {
    debugPrint(
      '💾 [main] Starting silent clipboard save, length: ${content.length}',
    );
    try {
      final saveCoordinator = SaveCoordinator();
      final success = await saveCoordinator.handleSilentShortcutSave(
        content: content,
        actionId: SaveCoordinator.clipboardShortcutActionId,
      );

      if (success) {
        debugPrint('✅ [main] Silent save succeeded');
      } else {
        debugPrint('⚠️ [main] Silent save interrupted, opening save page');
        _router.push(AppRoutes.save, extra: content);
      }
    } catch (e) {
      debugPrint('❌ [main] Silent save failed: $e, opening save page');
      _router.push(AppRoutes.save, extra: content);
    }
  }

  /// Initialize the share service.
  void _initializeShareService() {
    debugPrint('🚀 [main] Initializing share service...');

    // Initialize ShareService.
    final shareService = ShareService();
    shareService.initialize();

    // Listen for shared text.
    _shareSubscription = shareService.shareStream.listen((sharedText) {
      if (mounted) {
        debugPrint(
          '✨ [main] Received shared text from stream, source: ${sharedText.source}',
        );
        debugPrint(
          '✨ [main] Text preview: '
          '${sharedText.text.substring(0, sharedText.text.length.clamp(0, 50))}...',
        );

        // Choose the flow based on the source.
        if (sharedText.source == 'quick_save' ||
            sharedText.source == 'silent_save_from_tile') {
          // Shortcut saves should stay silent.
          debugPrint('🤫 [main] Shortcut save detected, using silent save');
          _handleSilentSave(sharedText.text);
        } else {
          // Regular shares should open the save page.
          debugPrint('📱 [main] Regular share detected, opening save page');
          _handleShareText(sharedText.text);
        }
      }
    });

    // Listen for shared images.
    _imageSubscription = shareService.imageStream.listen((sharedImage) {
      if (mounted) {
        debugPrint(
          '🖼️ [main] Received ${sharedImage.uris.length} shared image(s) from stream',
        );
        _handleShareImage(sharedImage.uris);
      }
    });

    // Also check for pending shared text for backward compatibility.
    shareService.getPendingShareText().then((text) {
      if (text != null && mounted) {
        debugPrint('🔄 [main] Loaded pending shared text');
        _handleShareText(text);
      }
    });

    debugPrint('✅ [main] Share service initialized');
  }

  /// Perform a silent save without opening the UI.
  Future<void> _handleSilentSave(String text) async {
    debugPrint('💾 [main] Starting silent save...');
    try {
      final saveCoordinator = SaveCoordinator();
      final success = await saveCoordinator.handleSilentShortcutSave(
        content: text,
        actionId: SaveCoordinator.shareStreamShortcutActionId,
      );

      if (success) {
        debugPrint('✅ [main] Silent save succeeded');
      } else {
        debugPrint('⚠️ [main] Silent save interrupted, opening save page');
        _router.push(AppRoutes.save, extra: text);
      }
    } catch (e) {
      debugPrint('❌ [main] Silent save failed: $e, opening save page');
      _router.push(AppRoutes.save, extra: text);
    }
  }

  void _handleShareText(String text) {
    debugPrint(
        '📝 [main] Flutter received shared text, length: ${text.length}');
    debugPrint(
      '📝 [main] Text preview: '
      '${text.substring(0, text.length.clamp(0, 100))}${text.length > 100 ? '...' : ''}',
    );
    // Navigate directly to the save page with the shared text.
    debugPrint('🚀 [main] Navigating to the save page...');
    _router.push(AppRoutes.save, extra: text);
    debugPrint('✅ [main] Navigation finished');
  }

  void _handleShareImage(List<String> uris) {
    debugPrint('Flutter received ${uris.length} shared image(s)');
    // Navigate to the save page with the shared image URIs.
    _router.push(AppRoutes.save, extra: {'type': 'image', 'uris': uris});
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;

    // Delay the check until the initial UI is fully rendered.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final hasUsageStats =
        await AppPermissionManager.checkUsageStatsPermission();

    if (!hasUsageStats && mounted) {
      try {
        _showUsageStatsPermissionDialog();
      } catch (e) {
        debugPrint(
          '⚠️ [main] Failed to show the permission dialog: $e. Will retry on the next launch',
        );
      }
    }
  }

  void _showUsageStatsPermissionDialog() {
    final dialogContext = _rootNavigatorKey.currentContext;
    if (dialogContext == null) return;
    final loc = AppLocalizations.of(dialogContext)!;

    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(loc.usageAccessPermissionRequiredTitle),
        content: Text(loc.usageAccessPermissionRequiredMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // The user chose to be reminded later.
            },
            child: Text(loc.laterLabel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AppPermissionManager.requestUsageStatsPermission();
            },
            child: Text(loc.grantAccessLabel),
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
      debugPrint('🔄 [main] App resumed, running memory cleanup');
      _runMemoryCleanup();
    }
  }

  Future<void> _runMemoryCleanup() async {
    try {
      final container = ProviderScope.containerOf(context);
      final notifier = container.read(summaryEntityNotifierProvider.notifier);
      await notifier.applyForgettingCurve();
      await notifier.cleanupSessionMemories();
      debugPrint('✅ [main] Memory cleanup finished');
    } catch (e) {
      debugPrint('❌ [main] Memory cleanup failed: $e');
    }
  }

  GoRouter _createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
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
          builder: (context, state) => const BottomNavigation(currentIndex: 3),
        ),
        GoRoute(
          path: '/feedback',
          builder: (context, state) => const FeedbackPage(),
        ),
        GoRoute(
          path: AppRoutes.databaseInspector,
          builder: (context, state) => const DatabaseInspectorPage(),
        ),
        GoRoute(
          path: AppRoutes.diagnostics,
          builder: (context, state) => const DiagnosticsPage(),
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
            return SavePage(
                initialData: editingSummary != null ? null : initialData,
                editingSummary: editingSummary);
          },
        ),
        GoRoute(
          path: AppRoutes.inject,
          builder: (context, state) => const InjectPage(),
        ),
        GoRoute(
          path: AppRoutes.template,
          builder: (context, state) => const BottomNavigation(currentIndex: 1),
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
          builder: (context, state) => const BottomNavigation(currentIndex: 2),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_runPostInitialization());
    });
  }

  Future<void> _runPostInitialization() async {
    await _checkPermissions();
    _initializeShareService();
    await _runMemoryCleanup();
    await _runSlmSelfCheckIfEnabled();
  }

  Future<void> _runSlmSelfCheckIfEnabled() async {
    if (!_autoRunSlmSelfCheckOnStartup) {
      return;
    }

    try {
      debugPrint('🧪 [main] Running startup SLM self-check...');
      final result = await sl<MemorySlmDiagnosticsService>().runSelfCheck();
      debugPrint(
        '🧪 [main] Startup SLM self-check finished: '
        'initializeCompleted=${result.initializeCompleted}, '
        'topicFallback=${result.topicFallbackMode.name}, '
        'metadataFallback=${result.metadataFallbackMode.name}, '
        'usedNativeModel=${result.usedNativeModel}, '
        'topic="${result.topic}", '
        'title="${result.title}", '
        'tags=${result.tags.join(",")}',
      );
    } catch (error, stackTrace) {
      debugPrint('❌ [main] Startup SLM self-check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
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
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: _router,
    );
  }
}
