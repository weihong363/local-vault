/// 新架构使用示例

// 在任何地方都可以通过服务定位器获取 UseCase
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';

/// 示例 1: 添加摘要
Future<void> addSummaryExample() async {
  final useCases = sl<SummaryUseCases>();
  
  final summary = SummaryEntity.create(
    title: '我的新摘要',
    content: '这是摘要内容...',
    tags: ['重要', '工作'],
  );
  
  await useCases.addSummary(summary);
  debugPrint('✅ 摘要添加成功');
}

/// 示例 2: 获取所有摘要
void getAllSummariesExample() {
  final useCases = sl<SummaryUseCases>();
  
  final summaries = useCases.getAllSummaries();
  debugPrint('📋 共有 ${summaries.length} 个摘要');
  
  for (final summary in summaries) {
    debugPrint('- ${summary.title}');
  }
}

/// 示例 3: 搜索摘要
void searchSummariesExample(String query) {
  final useCases = sl<SummaryUseCases>();
  
  final results = useCases.searchSummaries(query);
  debugPrint('🔍 搜索 "$query" 找到 ${results.length} 个结果');
}
