import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/features/summary/presentation/widgets/summary_card.dart';

void main() {
  testWidgets('Summary card renders and responds to taps', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    final summary = SummaryEntity.create(
      title: '阶段二验证',
      content: '这是一条用于验证 SummaryCard 的测试内容。',
      tags: const ['测试'],
      type: MemoryType.fact,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummaryCard(
            summary: summary,
            index: 0,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('阶段二验证'), findsOneWidget);
    expect(find.textContaining('这是一条用于验证 SummaryCard'), findsOneWidget);

    await tester.tap(find.byType(SummaryCard));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
