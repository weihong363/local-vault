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
  });

  group('MemorySLMService', () {
    test('canonicalizes RAG-related fallback topics', () async {
      final service = MemorySLMService();
      addTearDown(service.dispose);

      final response = await service.extractTopic(
        'Sentence Transformers 在端侧的用法',
        '继续验证向量检索、chunk 切分和 rerank 对召回率的影响。',
      );

      expect(response.data, 'RAG');
    });
  });
}
