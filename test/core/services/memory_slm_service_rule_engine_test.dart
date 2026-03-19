import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const <String, Object>{});

  group('MemorySLMService rule engine', () {
    test('extractTopic prefers template-based topic candidates', () async {
      final service = MemorySLMService();
      addTearDown(service.dispose);

      final response = await service.extractTopic(
        '登录页改版讨论',
        '今天确认登录页改版计划和埋点补齐范围，并补充灰度发布安排。',
      );

      expect(response.data, '登录页改版');
    });

    test('mergeSessions deduplicates repeated details and keeps structure',
        () async {
      final service = MemorySLMService();
      addTearDown(service.dispose);
      final now = DateTime.parse('2026-03-19T10:00:00.000Z');

      final response = await service.mergeSessions(<SummaryEntity>[
        SummaryEntity(
          id: 'session_merge_1',
          title: '发布安排',
          content: '确认周三上线窗口。补充回滚预案。',
          tags: const <String>['发布'],
          type: MemoryType.session,
          createdAt: now,
          source: 'quick_action',
        ),
        SummaryEntity(
          id: 'session_merge_2',
          title: '发布安排',
          content: '确认周三上线窗口。整理灰度策略。',
          tags: const <String>['灰度'],
          type: MemoryType.session,
          createdAt: now.add(const Duration(minutes: 1)),
          source: 'quick_action',
        ),
        SummaryEntity(
          id: 'session_merge_3',
          title: '发布安排',
          content: '补充回滚预案。同步负责人。',
          tags: const <String>['回滚'],
          type: MemoryType.session,
          createdAt: now.add(const Duration(minutes: 2)),
          source: 'quick_action',
        ),
      ]);

      expect(response.data.title, '发布安排');
      expect(
        RegExp('确认周三上线窗口').allMatches(response.data.content).length,
        1,
      );
      expect(
        RegExp('补充回滚预案').allMatches(response.data.content).length,
        1,
      );
      expect(response.data.content, contains('整理灰度策略'));
      expect(response.data.tags, containsAll(const <String>['发布', '灰度', '回滚']));
    });
  });
}
