import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/memory_promotion/memory_promotion.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/features/home/presentation/pages/memory_processing_detail_page.dart';

void main() {
  testWidgets('renders deferred operation status for deferred state record',
      (tester) async {
    final state = StateRecord(
      namespace: 'memory',
      key: 'task',
      summary: 'Review API spec tomorrow at 09:30',
      topic: 'API',
      keywords: const <String>['review'],
      importance: 0.7,
      version: 1,
      updatedAt: DateTime(2026, 4, 8, 9, 30),
      confidence: 0.3,
      coreMemoryMetadata: CoreMemoryMetadata.fromTopicClassification(
        'API',
        confidence: 0.3,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MemoryProcessingDetailPage(
            summaries: const <SummaryEntity>[],
            stateRecords: <StateRecord>[state],
            args: const MemoryProcessingDetailArgs(
              stateStorageKey: 'memory::task',
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('State operation result'), findsOneWidget);
    expect(find.textContaining('defer'), findsOneWidget);
  });

  testWidgets('renders explainability topic candidates', (tester) async {
    final summary = SummaryEntity(
      id: 'sum-1',
      title: 'Sprint planning',
      content: 'Team will update roadmap today and ship fixes tomorrow.',
      createdAt: DateTime(2026, 4, 8),
      tags: const <String>['planning', 'roadmap'],
      state: MemoryState.session,
      type: MemoryType.session,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MemoryProcessingDetailPage(
            summaries: <SummaryEntity>[summary],
            stateRecords: const <StateRecord>[],
            args: const MemoryProcessingDetailArgs(summaryId: 'sum-1'),
          ),
        ),
      ),
    );

    expect(find.text('Topic candidates with confidence'), findsOneWidget);
    expect(find.textContaining('Derived eventId'), findsOneWidget);
  });
}
