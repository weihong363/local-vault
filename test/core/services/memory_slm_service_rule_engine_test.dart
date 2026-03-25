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
        'Login Page Redesign Discussion',
        'Today confirmed login page redesign plan and analytics completion scope, and supplemented gray release arrangements.',
      );

      expect(response.data, 'Login Page Redesign');
    });

    test('mergeSessions deduplicates repeated details and keeps structure',
        () async {
      final service = MemorySLMService();
      addTearDown(service.dispose);
      final now = DateTime.parse('2026-03-19T10:00:00.000Z');

      final response = await service.mergeSessions(<SummaryEntity>[
        SummaryEntity(
          id: 'session_merge_1',
          title: 'Release Arrangements',
          content:
              'Confirm Wednesday go-live window. Supplement rollback plan.',
          tags: const <String>['Release'],
          type: MemoryType.session,
          createdAt: now,
          source: 'quick_action',
        ),
        SummaryEntity(
          id: 'session_merge_2',
          title: 'Release Arrangements',
          content: 'Confirm Wednesday go-live window. Organize gray strategy.',
          tags: const <String>['Gray'],
          type: MemoryType.session,
          createdAt: now.add(const Duration(minutes: 1)),
          source: 'quick_action',
        ),
        SummaryEntity(
          id: 'session_merge_3',
          title: 'Release Arrangements',
          content:
              'Supplement rollback plan. Synchronize with person in charge.',
          tags: const <String>['Rollback'],
          type: MemoryType.session,
          createdAt: now.add(const Duration(minutes: 2)),
          source: 'quick_action',
        ),
      ]);

      expect(response.data.title, 'Release Arrangements');
      expect(
        RegExp('Confirm Wednesday go-live window')
            .allMatches(response.data.content)
            .length,
        1,
      );
      expect(
        RegExp('Supplement rollback plan')
            .allMatches(response.data.content)
            .length,
        1,
      );
      expect(response.data.content, contains('Organize gray strategy'));
      expect(response.data.tags,
          containsAll(const <String>['Release', 'Gray', 'Rollback']));
    });
  });
}
