import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';
import 'package:local_vault/core/domain/repositories/template_repository_interface.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';
import 'package:local_vault/core/domain/usecases/template_usecases.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/infrastructure/repositories/hive_summary_repository.dart';
import 'package:local_vault/infrastructure/repositories/hive_template_repository.dart';

/// 服务定位器实例
final GetIt sl = GetIt.instance;

/// 初始化依赖注入
Future<void> initializeDependencies() async {
  debugPrint('🚀 [DI] 开始初始化依赖注入');

  // 1. Infrastructure 层注册
  sl.registerLazySingleton<SummaryRepositoryInterface>(
    () => HiveSummaryRepository(),
  );
  sl.registerLazySingleton<TemplateRepositoryInterface>(
    () => HiveTemplateRepository(),
  );
  sl.registerLazySingleton<MemorySLMService>(
    () => MemorySLMService(),
  );

  // 2. Domain 层注册
  sl.registerLazySingleton<SummaryUseCases>(
    () => SummaryUseCases(
      sl<SummaryRepositoryInterface>(),
      sl<MemorySLMService>(),
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
