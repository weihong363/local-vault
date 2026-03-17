// 新架构快速验证脚本
//
// 使用方式：
// 1. 在 main.dart 中导入此文件
// 2. 在应用启动后调用 verifyNewArchitecture()
//
// 或者：
// 在调试控制台中复制以下代码执行：

import 'package:flutter/foundation.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';
import 'package:local_vault/core/domain/usecases/template_usecases.dart';

/// 验证新架构是否正常工作
Future<void> verifyNewArchitecture() async {
  debugPrint('🚀 [新架构验证] 开始验证...');

  try {
    // 1. 验证 Summary Entity
    debugPrint('📝 [1/6] 测试 SummaryEntity...');
    final summary = SummaryEntity.create(
      title: '新架构测试摘要',
      content: '这是一条用于测试新架构的摘要内容',
      tags: ['测试', '新架构'],
    );
    debugPrint('✅ SummaryEntity 创建成功: ${summary.title}');

    // 2. 验证 Template Entity
    debugPrint('📄 [2/6] 测试 TemplateEntity...');
    final template = TemplateEntity.create(
      title: '新架构测试模板',
      content: '这是一条用于测试新架构的模板内容',
      tags: ['测试', '新架构'],
    );
    debugPrint('✅ TemplateEntity 创建成功: ${template.title}');

    // 3. 验证 Summary UseCase
    debugPrint('🔧 [3/6] 测试 SummaryUseCases...');
    final summaryUseCases = sl<SummaryUseCases>();
    await summaryUseCases.addSummary(summary);
    debugPrint('✅ SummaryUseCases 保存成功');

    final allSummaries = summaryUseCases.getAllSummaries();
    debugPrint('✅ SummaryUseCases 查询成功，共 ${allSummaries.length} 条');

    // 4. 验证 Template UseCase
    debugPrint('🔧 [4/6] 测试 TemplateUseCases...');
    final templateUseCases = sl<TemplateUseCases>();
    await templateUseCases.addTemplate(template);
    debugPrint('✅ TemplateUseCases 保存成功');

    final allTemplates = templateUseCases.getAllTemplates();
    debugPrint('✅ TemplateUseCases 查询成功，共 ${allTemplates.length} 条');

    // 5. 验证搜索功能
    debugPrint('🔍 [5/6] 测试搜索功能...');
    final searchResults = summaryUseCases.searchSummaries('测试');
    debugPrint('✅ 搜索成功，找到 ${searchResults.length} 条');

    // 6. 验证删除功能
    debugPrint('🗑️ [6/6] 测试删除功能...');
    await summaryUseCases.deleteSummary(summary.id);
    await templateUseCases.deleteTemplate(template.id);
    debugPrint('✅ 删除成功');

    debugPrint('\n🎉 [新架构验证] 全部测试通过！✅');
    debugPrint('📚 新架构已就绪，可以开始使用！');
  } catch (e, stack) {
    debugPrint('❌ [新架构验证] 测试失败: $e');
    debugPrint('📦 堆栈: $stack');
  }
}
