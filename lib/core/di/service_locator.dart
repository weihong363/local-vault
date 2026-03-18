import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:local_vault/core/config/memory_policy_config.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';
import 'package:local_vault/core/domain/repositories/template_repository_interface.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';
import 'package:local_vault/core/domain/usecases/template_usecases.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:local_vault/core/services/gesture_diagnostics_service.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/services/storage_management_service.dart';
import 'package:local_vault/core/services/summary_metadata_service.dart';
import 'package:local_vault/core/theme/memory_theme_config.dart';
import 'package:local_vault/infrastructure/repositories/hive_summary_repository.dart';
import 'package:local_vault/infrastructure/repositories/hive_template_repository.dart';

/// 服务定位器实例
final GetIt sl = GetIt.instance;

/// 初始化依赖注入
Future<void> initializeDependencies() async {
  debugPrint('🚀 [DI] 开始初始化依赖注入');
  final memoryPolicyConfig = await MemoryPolicyConfig.load();
  final memoryThemeConfig = await MemoryThemeConfig.load();

  // 1. Infrastructure 层注册
  sl.registerLazySingleton<SummaryRepositoryInterface>(
    () => HiveSummaryRepository(),
  );
  sl.registerLazySingleton<TemplateRepositoryInterface>(
    () => HiveTemplateRepository(),
  );
  sl.registerLazySingleton<AppSettingsService>(
    () => AppSettingsService(),
  );
  sl.registerLazySingleton<MemoryPolicyConfig>(
    () => memoryPolicyConfig,
  );
  sl.registerLazySingleton<MemoryThemeConfig>(
    () => memoryThemeConfig,
  );
  sl.registerLazySingleton<GestureDiagnosticsService>(
    () => GestureDiagnosticsService(
      settingsService: sl<AppSettingsService>(),
    ),
  );
  sl.registerLazySingleton<MemorySLMService>(
    () => MemorySLMService(),
  );
  sl.registerLazySingleton<StorageManagementService>(
    () => StorageManagementService(
      summaryRepository: sl<SummaryRepositoryInterface>(),
      templateRepository: sl<TemplateRepositoryInterface>(),
      slmService: sl<MemorySLMService>(),
    ),
  );
  sl.registerLazySingleton<SummaryMetadataService>(
    () => SummaryMetadataService(
      slmService: sl<MemorySLMService>(),
      settingsService: sl<AppSettingsService>(),
    ),
  );

  // 2. Domain 层注册
  sl.registerLazySingleton<SummaryUseCases>(
    () => SummaryUseCases(
      sl<SummaryRepositoryInterface>(),
      sl<MemorySLMService>(),
      policyConfig: sl<MemoryPolicyConfig>(),
    ),
  );
  sl.registerLazySingleton<TemplateUseCases>(
    () => TemplateUseCases(sl<TemplateRepositoryInterface>()),
  );

  // 3. 初始化仓库
  await sl<SummaryRepositoryInterface>().init();
  await sl<TemplateRepositoryInterface>().init();

  debugPrint('✅ [DI] 依赖注入初始化完成');
}
