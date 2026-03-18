// Quick verification script for the new architecture.
//
// Usage:
// 1. Import this file in main.dart
// 2. Call verifyNewArchitecture() after app startup
//
// Or run it directly from a debug console.

import 'package:flutter/foundation.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';
import 'package:local_vault/core/domain/usecases/template_usecases.dart';

/// Verify that the new architecture is functioning correctly.
Future<void> verifyNewArchitecture() async {
  debugPrint('🚀 [ArchitectureCheck] Starting verification...');

  try {
    // 1. Verify SummaryEntity.
    debugPrint('📝 [1/6] Testing SummaryEntity...');
    final summary = SummaryEntity.create(
      title: 'Architecture test summary',
      content: 'This summary is used to verify the new architecture.',
      tags: ['test', 'architecture'],
    );
    debugPrint('✅ SummaryEntity created: ${summary.title}');

    // 2. Verify TemplateEntity.
    debugPrint('📄 [2/6] Testing TemplateEntity...');
    final template = TemplateEntity.create(
      title: 'Architecture test template',
      content: 'This template is used to verify the new architecture.',
      tags: ['test', 'architecture'],
    );
    debugPrint('✅ TemplateEntity created: ${template.title}');

    // 3. Verify SummaryUseCases.
    debugPrint('🔧 [3/6] Testing SummaryUseCases...');
    final summaryUseCases = sl<SummaryUseCases>();
    await summaryUseCases.addSummary(summary);
    debugPrint('✅ SummaryUseCases save succeeded');

    final allSummaries = summaryUseCases.getAllSummaries();
    debugPrint(
      '✅ SummaryUseCases query succeeded with ${allSummaries.length} item(s)',
    );

    // 4. Verify TemplateUseCases.
    debugPrint('🔧 [4/6] Testing TemplateUseCases...');
    final templateUseCases = sl<TemplateUseCases>();
    await templateUseCases.addTemplate(template);
    debugPrint('✅ TemplateUseCases save succeeded');

    final allTemplates = templateUseCases.getAllTemplates();
    debugPrint(
      '✅ TemplateUseCases query succeeded with ${allTemplates.length} item(s)',
    );

    // 5. Verify search.
    debugPrint('🔍 [5/6] Testing search...');
    final searchResults = summaryUseCases.searchSummaries('test');
    debugPrint('✅ Search succeeded with ${searchResults.length} result(s)');

    // 6. Verify delete.
    debugPrint('🗑️ [6/6] Testing delete...');
    await summaryUseCases.deleteSummary(summary.id);
    await templateUseCases.deleteTemplate(template.id);
    debugPrint('✅ Delete succeeded');

    debugPrint('\n🎉 [ArchitectureCheck] All checks passed');
    debugPrint('📚 The new architecture is ready to use');
  } catch (e, stack) {
    debugPrint('❌ [ArchitectureCheck] Verification failed: $e');
    debugPrint('📦 Stack trace: $stack');
  }
}
