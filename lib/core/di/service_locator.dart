import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:local_vault/core/config/memory_policy_config.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';
import 'package:local_vault/core/domain/repositories/template_repository_interface.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';
import 'package:local_vault/core/domain/usecases/template_usecases.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';
import 'package:local_vault/core/memory_runtime/policies/default_memory_policy.dart';
import 'package:local_vault/core/memory_runtime/repositories/memory_sidecar_repository.dart';
import 'package:local_vault/core/memory_runtime/services/default_memory_worker.dart';
import 'package:local_vault/core/memory_runtime/services/rule_based_memory_runtime.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:local_vault/core/services/gesture_diagnostics_service.dart';
import 'package:local_vault/core/services/memory_slm_diagnostics_service.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/services/storage_management_service.dart';
import 'package:local_vault/core/services/summary_metadata_service.dart';
import 'package:local_vault/core/theme/memory_theme_config.dart';
import 'package:local_vault/infrastructure/repositories/hive_memory_sidecar_repository.dart';
import 'package:local_vault/infrastructure/repositories/hive_summary_repository.dart';
import 'package:local_vault/infrastructure/repositories/hive_template_repository.dart';

/// 服务定位器实例
final GetIt sl = GetIt.instance;

/// 初始化依赖注入
Future<void> initializeDependencies() async {
  debugPrint('🚀 [DI] Starting dependency injection initialization');
  final memoryPolicyConfig = await MemoryPolicyConfig.load();
  final memoryThemeConfig = await MemoryThemeConfig.load();

  // 1. Infrastructure 层注册
  sl.registerLazySingleton<SummaryRepositoryInterface>(
    () => HiveSummaryRepository(),
  );
  sl.registerLazySingleton<TemplateRepositoryInterface>(
    () => HiveTemplateRepository(),
  );
  sl.registerLazySingleton<MemorySidecarRepository>(
    () => HiveMemorySidecarRepository(),
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
    () => MemorySLMService(
      settingsService: sl<AppSettingsService>(),
    ),
  );
  sl.registerLazySingleton<MemorySlmDiagnosticsService>(
    () => MemorySlmDiagnosticsService(
      slmService: sl<MemorySLMService>(),
    ),
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
      settingsService: sl<AppSettingsService>(),
    ),
  );
  sl.registerLazySingleton<MemoryPolicy>(
    () => const DefaultMemoryPolicy(),
  );
  sl.registerLazySingleton<ModelRuntimeProvider>(
    () => const NoopModelRuntimeProvider(),
  );
  sl.registerLazySingleton<MemoryWorker>(
    () => DefaultMemoryWorker(),
  );
  sl.registerLazySingleton<MemoryCompressor>(
    () => RuleBasedMemoryCompressor(
      slmService: sl<MemorySLMService>(),
      policyConfig: sl<MemoryPolicyConfig>(),
      policy: sl<MemoryPolicy>(),
    ),
  );
  sl.registerLazySingleton<MemoryMerger>(
    () => RuleBasedMemoryMerger(
      slmService: sl<MemorySLMService>(),
      policy: sl<MemoryPolicy>(),
    ),
  );
  sl.registerLazySingleton<MemoryRetriever>(
    () => RuleBasedMemoryRetriever(
      sidecarRepository: sl<MemorySidecarRepository>(),
      slmService: sl<MemorySLMService>(),
      policy: sl<MemoryPolicy>(),
    ),
  );
  sl.registerLazySingleton<ContextAssembler>(
    () => DefaultContextAssembler(
      policy: sl<MemoryPolicy>(),
    ),
  );
  sl.registerLazySingleton<MemoryCapability>(
    () => RuleBasedMemoryCapability(
      summaryRepository: sl<SummaryRepositoryInterface>(),
      sidecarRepository: sl<MemorySidecarRepository>(),
      compressor: sl<MemoryCompressor>(),
      merger: sl<MemoryMerger>(),
      retriever: sl<MemoryRetriever>(),
      contextAssembler: sl<ContextAssembler>(),
      worker: sl<MemoryWorker>(),
      policy: sl<MemoryPolicy>(),
      legacyPolicyConfig: sl<MemoryPolicyConfig>(),
      slmService: sl<MemorySLMService>(),
      modelRuntimeProvider: sl<ModelRuntimeProvider>(),
    ),
  );

  // 2. Domain 层注册
  sl.registerLazySingleton<SummaryUseCases>(
    () => SummaryUseCases(
      sl<SummaryRepositoryInterface>(),
      sl<MemorySLMService>(),
      policyConfig: sl<MemoryPolicyConfig>(),
      memoryCapability: sl<MemoryCapability>(),
    ),
  );
  sl.registerLazySingleton<TemplateUseCases>(
    () => TemplateUseCases(sl<TemplateRepositoryInterface>()),
  );

  // 3. 初始化仓库
  await sl<SummaryRepositoryInterface>().init();
  await sl<TemplateRepositoryInterface>().init();
  await sl<MemorySidecarRepository>().init();

  debugPrint('✅ [DI] Dependency injection initialized');
}
