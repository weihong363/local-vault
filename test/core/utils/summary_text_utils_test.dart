import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/utils/summary_text_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const <String, Object>{});

  group('SummaryTextUtils', () {
    test('keeps high-signal short English acronyms as tags', () {
      final tags = SummaryTextUtils.generateTags(
        'RAG',
        '继续优化 RAG 召回、chunk 切分和 rerank 效果。',
      );

      expect(
        tags.map((tag) => tag.toLowerCase()),
        contains('rag'),
      );
    });

    test('removes English leading fillers when generating titles', () {
      final title = SummaryTextUtils.generateTitle(
        'Please help me summarize the login page redesign review and analytics update.',
      );

      expect(title.toLowerCase(), isNot(contains('please help me')));
      expect(title.toLowerCase(), isNot(contains('summarize')));
      expect(title.toLowerCase(), contains('login'));
    });

    test('supports Japanese scripts when generating titles', () {
      final title = SummaryTextUtils.generateTitle(
        '今週のリリース計画を整理し、ログイン画面の修正内容を確認する。',
      );

      expect(title, isNot(SummaryTextUtils.unnamedTitle));
      expect(title, contains('リリース'));
      expect(title.startsWith('今週'), isFalse);
    });

    test('supports Korean scripts when generating tags', () {
      final tags = SummaryTextUtils.generateTags(
        '릴리스 계획 검토',
        '이번 주 릴리스 일정과 롤백 계획을 확인하고 로그인 화면 수정 범위를 정리한다.',
      );

      expect(tags, isNotEmpty);
      expect(tags.join(','), contains('릴리스'));
    });

    test('supports accented Latin scripts when generating titles and tags', () {
      final title = SummaryTextUtils.generateTitle(
        'Por favor, resumir la revisión de recuperación y reordenación del buscador.',
      );
      final tags = SummaryTextUtils.generateTags(
        'Plan de recuperación',
        'Necesitamos ajustar la reordenación y la base de conocimiento.',
      );

      expect(title.toLowerCase(), isNot(contains('por favor')));
      expect(title.toLowerCase(), contains('revisión'));
      expect(tags.join(','), contains('recuperación'));
    });
  });

  group('MemorySLMService', () {
    test('canonicalizes RAG-related fallback topics', () async {
      final service = MemorySLMService();
      addTearDown(service.dispose);

      final profile = service.describeTextSemantics(
        title: 'Sentence Transformers 在端侧的用法',
        content: '继续验证向量检索、chunk 切分和 rerank 对召回率的影响。',
      );

      expect(profile.domainLabel, 'RAG');
      expect(profile.displayTopic, contains('RAG'));
    });

    test('canonicalizes Spanish RAG aliases and secondary signals', () async {
      final service = MemorySLMService();
      addTearDown(service.dispose);

      final profile = service.describeTextSemantics(
        title: 'Plan de base de conocimiento',
        content:
            'Seguimos ajustando la recuperación vectorial y la reordenación para mejorar RAG.',
      );

      expect(profile.domainLabel, 'RAG');
      expect(profile.displayTopic, contains('RAG'));
    });

    test('canonicalizes French OCR aliases', () async {
      final service = MemorySLMService();
      addTearDown(service.dispose);

      final profile = service.describeTextSemantics(
        title: 'Reconnaissance optique de caractères',
        content: 'Nous devons vérifier le flux OCR pour les images partagées.',
      );

      expect(profile.domainLabel, 'OCR');
      expect(profile.displayTopic, contains('OCR'));
    });
  });
}
